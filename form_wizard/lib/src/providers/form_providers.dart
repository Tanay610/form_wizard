import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/form_state.dart';
import '../models/form_wizard_field_model.dart';
import '../validators/validators.dart';

/// Owns the immutable state for a form and exposes mutation APIs.
class FormStateNotifier extends Notifier<FormState> {
  @override
  FormState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      for (final timer in _asyncValidationTimers.values) {
        timer.cancel();
      }
      _asyncValidationTimers.clear();
    });

    return const FormState();
  }

  final Map<String, List<Validator>> _validators = <String, List<Validator>>{};
  final Map<String, List<FormWizardContextValidator>> _contextValidators =
      <String, List<FormWizardContextValidator>>{};
  final Map<String, List<FormWizardAsyncValidator>> _asyncValidators =
      <String, List<FormWizardAsyncValidator>>{};
  final Map<String, Duration> _asyncValidationDebounces = <String, Duration>{};
  final Map<String, FormWizardVisibilityPredicate> _visibilityPredicates =
      <String, FormWizardVisibilityPredicate>{};
  final Map<String, List<String>> _visibilityDependencies =
      <String, List<String>>{};
  final Map<String, List<String>> _visibilityDependents =
      <String, List<String>>{};
  final Map<String, List<String>> _validationDependencies =
      <String, List<String>>{};
  final Map<String, List<String>> _validationDependents =
      <String, List<String>>{};
  final Map<String, Timer> _asyncValidationTimers = <String, Timer>{};
  final Map<String, int> _asyncValidationTokens = <String, int>{};
  bool _isDisposed = false;

  /// Registers initial values and validators for the active field list.
  void configure({
    required Map<String, dynamic> initialValues,
    required Map<String, List<Validator>> validators,
    Map<String, List<FormWizardContextValidator>> contextValidators =
        const <String, List<FormWizardContextValidator>>{},
    Map<String, List<FormWizardAsyncValidator>> asyncValidators =
        const <String, List<FormWizardAsyncValidator>>{},
    Map<String, Duration> asyncValidationDebounces = const <String, Duration>{},
    Map<String, FormWizardVisibilityPredicate> visibilityPredicates =
        const <String, FormWizardVisibilityPredicate>{},
    Map<String, List<String>> visibilityDependencies =
        const <String, List<String>>{},
    Map<String, List<String>> validationDependencies =
        const <String, List<String>>{},
    Map<String, int> initialFieldArrayCounts = const <String, int>{},
  }) {
    _validators
      ..clear()
      ..addAll(validators);
    _contextValidators
      ..clear()
      ..addAll(contextValidators);
    _asyncValidators
      ..clear()
      ..addAll(asyncValidators);
    _asyncValidationDebounces
      ..clear()
      ..addAll(asyncValidationDebounces);
    _visibilityPredicates
      ..clear()
      ..addAll(visibilityPredicates);
    _visibilityDependencies
      ..clear()
      ..addAll(visibilityDependencies);
    _visibilityDependents
      ..clear()
      ..addAll(_reverseDependencies(visibilityDependencies));
    _validationDependencies
      ..clear()
      ..addAll(validationDependencies);
    _validationDependents
      ..clear()
      ..addAll(_reverseDependencies(validationDependencies));

    final nextValues = <String, dynamic>{
      for (final entry in initialValues.entries)
        entry.key: state.values[entry.key] ?? entry.value,
    };

    final nextErrors = <String, String?>{
      for (final fieldName in initialValues.keys)
        fieldName: state.errors[fieldName],
    };

    final nextVisibleFields = <String, bool>{
      for (final fieldName in initialValues.keys)
        fieldName: _isFieldVisible(fieldName, nextValues),
    };
    final nextFieldArrays = <String, List<String>>{...state.fieldArrays};
    var nextArrayItemId = state.nextArrayItemId;

    for (final entry in initialFieldArrayCounts.entries) {
      nextFieldArrays.putIfAbsent(entry.key, () {
        return [
          for (var i = 0; i < entry.value; i++) 'fw_${nextArrayItemId++}',
        ];
      });
    }

    final nextState = FormState(
      values: nextValues,
      errors: nextErrors,
      visibleFields: nextVisibleFields,
      fieldArrays: Map<String, List<String>>.unmodifiable(nextFieldArrays),
      dirtyFields: state.dirtyFields,
      touchedFields: state.touchedFields,
      validatingFields: state.validatingFields,
      isSubmitted: state.isSubmitted,
      nextArrayItemId: nextArrayItemId,
    );

    if (_stateEquals(state, nextState)) return;
    state = nextState;
  }

  /// Updates one field and revalidates only that field.
  void updateFieldValue(String fieldName, dynamic value) {
    final nextValues = <String, dynamic>{...state.values, fieldName: value};
    final nextVisibleFields = <String, bool>{...state.visibleFields};
    final nextErrors = <String, String?>{...state.errors};
    final nextDirtyFields = <String>{...state.dirtyFields, fieldName};
    final nextValidatingFields = <String>{...state.validatingFields};
    final asyncFields = <String>{};
    final affectedFields = _affectedFieldsFor(fieldName)..add(fieldName);

    for (final affectedField in affectedFields) {
      final isVisible = _isFieldVisible(affectedField, nextValues);
      nextVisibleFields[affectedField] = isVisible;

      if (!isVisible) {
        nextErrors[affectedField] = null;
        nextValidatingFields.remove(affectedField);
        _cancelAsyncValidation(affectedField);
        continue;
      }

      final error = _errorForFieldWithValues(
        affectedField,
        nextValues[affectedField],
        nextValues,
      );
      nextErrors[affectedField] = error;

      if (error == null && _hasAsyncValidators(affectedField)) {
        nextValidatingFields.add(affectedField);
        asyncFields.add(affectedField);
      } else {
        nextValidatingFields.remove(affectedField);
        _cancelAsyncValidation(affectedField);
      }
    }

    state = state.copyWith(
      values: nextValues,
      errors: nextErrors,
      visibleFields: nextVisibleFields,
      dirtyFields: nextDirtyFields,
      validatingFields: nextValidatingFields,
    );

    for (final asyncField in asyncFields) {
      _scheduleAsyncValidation(
        asyncField,
        Map<String, dynamic>.unmodifiable(nextValues),
      );
    }
  }

  /// Marks a field as touched.
  void markFieldTouched(String fieldName) {
    if (state.touchedFields.contains(fieldName)) return;
    state = state.copyWith(
      touchedFields: <String>{...state.touchedFields, fieldName},
    );
  }

  /// Marks multiple fields as touched.
  void markFieldsTouched(Iterable<String> fieldNames) {
    final nextTouchedFields = <String>{...state.touchedFields, ...fieldNames};
    if (setEquals(nextTouchedFields, state.touchedFields)) return;
    state = state.copyWith(touchedFields: nextTouchedFields);
  }

  /// Sets an error for a field.
  void setFieldError(String fieldName, String? error) {
    if (state.errors[fieldName] == error) return;
    state = state.setFieldError(fieldName, error);
  }

  /// Updates whether a field is visible.
  void setFieldVisibility(String fieldName, bool isVisible) {
    if (state.visibleFields[fieldName] == isVisible) return;

    var nextState = state.setFieldVisibility(fieldName, isVisible);
    if (!isVisible) {
      nextState = nextState.setFieldError(fieldName, null);
    }
    state = nextState;
  }

  /// Validates one field using the validators registered for [fieldName].
  bool validateField(String fieldName) {
    final error = _errorForField(fieldName, state.values[fieldName]);
    final nextValidatingFields = <String>{...state.validatingFields};

    if (error == null && _hasAsyncValidators(fieldName)) {
      nextValidatingFields.add(fieldName);
      _scheduleAsyncValidation(
        fieldName,
        Map<String, dynamic>.unmodifiable(state.values),
      );
    } else {
      nextValidatingFields.remove(fieldName);
      _cancelAsyncValidation(fieldName);
    }

    state = state.copyWith(
      errors: <String, String?>{...state.errors, fieldName: error},
      touchedFields: <String>{...state.touchedFields, fieldName},
      validatingFields: nextValidatingFields,
    );
    return error == null && !_hasAsyncValidators(fieldName);
  }

  /// Validates one field and waits for async validators.
  Future<bool> validateFieldAsync(String fieldName) {
    return validateFieldsAsync(<String>[fieldName]);
  }

  /// Validates selected fields and waits for async validators.
  Future<bool> validateFieldsAsync(Iterable<String> fieldNames) async {
    final fields = fieldNames.toSet();
    final nextErrors = <String, String?>{...state.errors};
    final nextValidatingFields = <String>{...state.validatingFields};
    final nextTouchedFields = <String>{...state.touchedFields, ...fields};
    final asyncWork = <_AsyncValidationWork>[];

    for (final fieldName in fields) {
      if (!_isFieldVisible(fieldName, state.values)) {
        nextErrors[fieldName] = null;
        nextValidatingFields.remove(fieldName);
        _cancelAsyncValidation(fieldName);
        continue;
      }

      final error = _errorForField(fieldName, state.values[fieldName]);
      nextErrors[fieldName] = error;

      if (error == null && _hasAsyncValidators(fieldName)) {
        nextValidatingFields.add(fieldName);
        asyncWork.add(
          _AsyncValidationWork(
            fieldName: fieldName,
            token: _nextAsyncValidationToken(fieldName),
          ),
        );
        _asyncValidationTimers.remove(fieldName)?.cancel();
      } else {
        nextValidatingFields.remove(fieldName);
        _cancelAsyncValidation(fieldName);
      }
    }

    state = state.copyWith(
      errors: nextErrors,
      touchedFields: nextTouchedFields,
      validatingFields: nextValidatingFields,
      isSubmitted: true,
    );

    if (asyncWork.isEmpty) {
      return fields.every((fieldName) => state.errors[fieldName] == null);
    }

    final valuesSnapshot = Map<String, dynamic>.unmodifiable(state.values);
    final results = await Future.wait([
      for (final work in asyncWork)
        _runAsyncValidation(work.fieldName, valuesSnapshot).then(
          (error) => _AsyncValidationResult(
            fieldName: work.fieldName,
            token: work.token,
            error: error,
          ),
        ),
    ]);

    if (_isDisposed) return false;

    final resolvedErrors = <String, String?>{...state.errors};
    final resolvedValidatingFields = <String>{...state.validatingFields};

    for (final result in results) {
      if (_asyncValidationTokens[result.fieldName] != result.token) continue;
      resolvedErrors[result.fieldName] = result.error;
      resolvedValidatingFields.remove(result.fieldName);
    }

    state = state.copyWith(
      errors: resolvedErrors,
      validatingFields: resolvedValidatingFields,
    );

    return fields.every((fieldName) {
      return state.errors[fieldName] == null &&
          !state.validatingFields.contains(fieldName);
    });
  }

  String? _errorForField(String fieldName, dynamic rawValue) {
    return _errorForFieldWithValues(fieldName, rawValue, state.values);
  }

  String? _errorForFieldWithValues(
    String fieldName,
    dynamic rawValue,
    Map<String, dynamic> values,
  ) {
    if (!_isFieldVisible(fieldName, values)) return null;

    final value = rawValue?.toString();
    final validators = _validators[fieldName] ?? const <Validator>[];

    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }

    final context = FormWizardValidationContext(
      Map<String, dynamic>.unmodifiable(values),
    );
    final contextValidators =
        _contextValidators[fieldName] ?? const <FormWizardContextValidator>[];

    for (final validator in contextValidators) {
      final result = validator(value, context);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  bool _isFieldVisible(String fieldName, Map<String, dynamic> values) {
    return _visibilityPredicates[fieldName]?.call(values) ?? true;
  }

  Set<String> _affectedFieldsFor(String fieldName) {
    final affected = <String>{};
    final stack = <String>[fieldName];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final dependents = <String>{
        ...(_visibilityDependents[current] ?? const <String>[]),
        ...(_validationDependents[current] ?? const <String>[]),
      };

      for (final dependent in dependents) {
        if (affected.add(dependent)) {
          stack.add(dependent);
        }
      }
    }

    return affected;
  }

  void _scheduleAsyncValidation(String fieldName, Map<String, dynamic> values) {
    final token = _nextAsyncValidationToken(fieldName);
    _asyncValidationTimers.remove(fieldName)?.cancel();
    _asyncValidationTimers[fieldName] = Timer(
      _asyncValidationDebounces[fieldName] ?? const Duration(milliseconds: 350),
      () async {
        final error = await _runAsyncValidation(fieldName, values);
        if (_isDisposed || _asyncValidationTokens[fieldName] != token) return;

        state = state.copyWith(
          errors: <String, String?>{...state.errors, fieldName: error},
          validatingFields: <String>{...state.validatingFields}
            ..remove(fieldName),
        );
      },
    );
  }

  Future<String?> _runAsyncValidation(
    String fieldName,
    Map<String, dynamic> values,
  ) async {
    if (!_isFieldVisible(fieldName, values)) return null;

    final value = values[fieldName]?.toString();
    final context = FormWizardValidationContext(
      Map<String, dynamic>.unmodifiable(values),
    );

    for (final validator
        in _asyncValidators[fieldName] ?? const <FormWizardAsyncValidator>[]) {
      final result = await validator(value, context);
      if (result != null) return result;
    }

    return null;
  }

  bool _hasAsyncValidators(String fieldName) {
    return (_asyncValidators[fieldName] ?? const <FormWizardAsyncValidator>[])
        .isNotEmpty;
  }

  int _nextAsyncValidationToken(String fieldName) {
    final token = (_asyncValidationTokens[fieldName] ?? 0) + 1;
    _asyncValidationTokens[fieldName] = token;
    return token;
  }

  void _cancelAsyncValidation(String fieldName) {
    _asyncValidationTimers.remove(fieldName)?.cancel();
    _nextAsyncValidationToken(fieldName);
  }

  /// Validates every registered field.
  bool validateForm() {
    final fieldNames = state.values.keys.toSet();
    final nextErrors = <String, String?>{...state.errors};
    final nextValidatingFields = <String>{...state.validatingFields};
    final asyncFields = <String>{};

    for (final fieldName in fieldNames) {
      final error = _errorForField(fieldName, state.values[fieldName]);
      nextErrors[fieldName] = error;

      if (error == null && _hasAsyncValidators(fieldName)) {
        nextValidatingFields.add(fieldName);
        asyncFields.add(fieldName);
      } else {
        nextValidatingFields.remove(fieldName);
        _cancelAsyncValidation(fieldName);
      }
    }

    state = state.copyWith(
      errors: nextErrors,
      touchedFields: <String>{...state.touchedFields, ...fieldNames},
      validatingFields: nextValidatingFields,
      isSubmitted: true,
    );

    for (final fieldName in asyncFields) {
      _scheduleAsyncValidation(
        fieldName,
        Map<String, dynamic>.unmodifiable(state.values),
      );
    }

    return state.isValid && asyncFields.isEmpty;
  }

  /// Validates every field and waits for async validators.
  Future<bool> validateFormAsync() {
    return validateFieldsAsync(state.values.keys);
  }

  /// Clears field values and errors.
  void reset({Map<String, dynamic> values = const <String, dynamic>{}}) {
    for (final timer in _asyncValidationTimers.values) {
      timer.cancel();
    }
    _asyncValidationTimers.clear();
    state = FormState(values: values);
  }

  /// Adds one item to a dynamic field array.
  void addFieldArrayItem(String arrayName) {
    final itemId = 'fw_${state.nextArrayItemId}';
    final currentItems = state.fieldArrays[arrayName] ?? const <String>[];

    state = state.copyWith(
      fieldArrays: <String, List<String>>{
        ...state.fieldArrays,
        arrayName: <String>[...currentItems, itemId],
      },
      nextArrayItemId: state.nextArrayItemId + 1,
    );
  }

  /// Removes one item from a dynamic field array.
  void removeFieldArrayItem(String arrayName, String itemId) {
    final currentItems = state.fieldArrays[arrayName] ?? const <String>[];
    if (!currentItems.contains(itemId)) return;

    final fieldPrefix = '$arrayName.$itemId.';
    final nextValues = <String, dynamic>{...state.values}
      ..removeWhere((fieldName, _) => fieldName.startsWith(fieldPrefix));
    final nextErrors = <String, String?>{...state.errors}
      ..removeWhere((fieldName, _) => fieldName.startsWith(fieldPrefix));
    final nextVisibleFields = <String, bool>{...state.visibleFields}
      ..removeWhere((fieldName, _) => fieldName.startsWith(fieldPrefix));
    final nextDirtyFields = <String>{...state.dirtyFields}
      ..removeWhere((fieldName) => fieldName.startsWith(fieldPrefix));
    final nextTouchedFields = <String>{...state.touchedFields}
      ..removeWhere((fieldName) => fieldName.startsWith(fieldPrefix));
    final nextValidatingFields = <String>{...state.validatingFields}
      ..removeWhere((fieldName) {
        final shouldRemove = fieldName.startsWith(fieldPrefix);
        if (shouldRemove) _cancelAsyncValidation(fieldName);
        return shouldRemove;
      });

    state = state.copyWith(
      values: nextValues,
      errors: nextErrors,
      visibleFields: nextVisibleFields,
      dirtyFields: nextDirtyFields,
      touchedFields: nextTouchedFields,
      validatingFields: nextValidatingFields,
      fieldArrays: <String, List<String>>{
        ...state.fieldArrays,
        arrayName: [
          for (final currentItemId in currentItems)
            if (currentItemId != itemId) currentItemId,
        ],
      },
    );
  }

  /// Reorders one item in a dynamic field array.
  void reorderFieldArrayItem(String arrayName, int oldIndex, int newIndex) {
    final currentItems = state.fieldArrays[arrayName] ?? const <String>[];
    if (oldIndex < 0 ||
        oldIndex >= currentItems.length ||
        newIndex < 0 ||
        newIndex >= currentItems.length ||
        oldIndex == newIndex) {
      return;
    }

    final nextItems = <String>[...currentItems];
    final item = nextItems.removeAt(oldIndex);
    nextItems.insert(newIndex, item);

    state = state.copyWith(
      fieldArrays: <String, List<String>>{
        ...state.fieldArrays,
        arrayName: nextItems,
      },
    );
  }
}

Map<String, List<String>> _reverseDependencies(
  Map<String, List<String>> dependencies,
) {
  final reversed = <String, List<String>>{};

  for (final entry in dependencies.entries) {
    for (final dependency in entry.value) {
      reversed.putIfAbsent(dependency, () => <String>[]).add(entry.key);
    }
  }

  return reversed;
}

/// Global form state provider.
///
/// Widgets should prefer `.select` on this provider to subscribe to one field:
/// `ref.watch(formStateProvider.select((state) => state.values[fieldName]))`.
final formStateProvider = NotifierProvider<FormStateNotifier, FormState>(
  FormStateNotifier.new,
);

bool _stateEquals(FormState a, FormState b) {
  return mapEquals(a.values, b.values) &&
      mapEquals(a.errors, b.errors) &&
      mapEquals(a.visibleFields, b.visibleFields) &&
      _fieldArraysEqual(a.fieldArrays, b.fieldArrays) &&
      setEquals(a.dirtyFields, b.dirtyFields) &&
      setEquals(a.touchedFields, b.touchedFields) &&
      setEquals(a.validatingFields, b.validatingFields) &&
      a.isSubmitted == b.isSubmitted &&
      a.nextArrayItemId == b.nextArrayItemId;
}

bool _fieldArraysEqual(
  Map<String, List<String>> a,
  Map<String, List<String>> b,
) {
  if (a.length != b.length) return false;

  for (final entry in a.entries) {
    if (!listEquals(entry.value, b[entry.key])) return false;
  }

  return true;
}

/// Derived form validity provider.
///
/// This watches the derived validity boolean, so consumers such as submit
/// buttons avoid rebuilding for ordinary value changes that do not affect
/// validity.
final formValidityProvider = Provider<bool>((ref) {
  return ref.watch(formStateProvider.select((state) => state.isValid));
});

/// Derived provider for whether any visible field is running async validation.
final formValidationPendingProvider = Provider<bool>((ref) {
  return ref.watch(
    formStateProvider.select(
      (state) => state.validatingFields.any(
        (fieldName) => state.visibleFields[fieldName] != false,
      ),
    ),
  );
});

/// Watches the value for a single field.
final fieldValueProvider = Provider.family<dynamic, String>((ref, fieldName) {
  return ref.watch(
    formStateProvider.select((state) => state.values[fieldName]),
  );
});

/// Watches the error for a single field.
final fieldErrorProvider = Provider.family<String?, String>((ref, fieldName) {
  return ref.watch(
    formStateProvider.select((state) => state.errors[fieldName]),
  );
});

/// Watches whether a single field is running async validation.
final fieldValidatingProvider = Provider.family<bool, String>((ref, fieldName) {
  return ref.watch(
    formStateProvider.select(
      (state) => state.validatingFields.contains(fieldName),
    ),
  );
});

/// Watches whether a single field is dirty.
final fieldDirtyProvider = Provider.family<bool, String>((ref, fieldName) {
  return ref.watch(
    formStateProvider.select((state) => state.dirtyFields.contains(fieldName)),
  );
});

/// Watches whether a single field is touched.
final fieldTouchedProvider = Provider.family<bool, String>((ref, fieldName) {
  return ref.watch(
    formStateProvider.select(
      (state) => state.touchedFields.contains(fieldName),
    ),
  );
});

class _AsyncValidationWork {
  const _AsyncValidationWork({required this.fieldName, required this.token});

  final String fieldName;
  final int token;
}

class _AsyncValidationResult {
  const _AsyncValidationResult({
    required this.fieldName,
    required this.token,
    required this.error,
  });

  final String fieldName;
  final int token;
  final String? error;
}
