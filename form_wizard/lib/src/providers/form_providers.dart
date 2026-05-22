import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/form_state.dart';
import '../models/form_wizard_field_model.dart';
import '../validators/validators.dart';

/// Owns the immutable state for a form and exposes mutation APIs.
class FormStateNotifier extends Notifier<FormState> {
  @override
  FormState build() => const FormState();

  final Map<String, List<Validator>> _validators = <String, List<Validator>>{};
  final Map<String, FormWizardVisibilityPredicate> _visibilityPredicates =
      <String, FormWizardVisibilityPredicate>{};
  final Map<String, List<String>> _visibilityDependencies =
      <String, List<String>>{};
  final Map<String, List<String>> _visibilityDependents =
      <String, List<String>>{};

  /// Registers initial values and validators for the active field list.
  void configure({
    required Map<String, dynamic> initialValues,
    required Map<String, List<Validator>> validators,
    Map<String, FormWizardVisibilityPredicate> visibilityPredicates =
        const <String, FormWizardVisibilityPredicate>{},
    Map<String, List<String>> visibilityDependencies =
        const <String, List<String>>{},
    Map<String, int> initialFieldArrayCounts = const <String, int>{},
  }) {
    _validators
      ..clear()
      ..addAll(validators);
    _visibilityPredicates
      ..clear()
      ..addAll(visibilityPredicates);
    _visibilityDependencies
      ..clear()
      ..addAll(visibilityDependencies);
    _visibilityDependents
      ..clear()
      ..addAll(_reverseDependencies(visibilityDependencies));

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
    final affectedFields = _affectedFieldsFor(fieldName)..add(fieldName);

    for (final affectedField in affectedFields) {
      final isVisible = _isFieldVisible(affectedField, nextValues);
      nextVisibleFields[affectedField] = isVisible;

      if (!isVisible) {
        nextErrors[affectedField] = null;
      } else if (affectedField == fieldName ||
          state.errors[affectedField] != null) {
        nextErrors[affectedField] = _errorForFieldWithValues(
          affectedField,
          nextValues[affectedField],
          nextValues,
        );
      }
    }

    state = state.copyWith(
      values: nextValues,
      errors: nextErrors,
      visibleFields: nextVisibleFields,
    );
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
    setFieldError(fieldName, error);
    return error == null;
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
      for (final dependent
          in _visibilityDependents[current] ?? const <String>[]) {
        if (affected.add(dependent)) {
          stack.add(dependent);
        }
      }
    }

    return affected;
  }

  /// Validates every registered field.
  bool validateForm() {
    var isValid = true;

    for (final fieldName in _validators.keys) {
      isValid = validateField(fieldName) && isValid;
    }

    return isValid;
  }

  /// Clears field values and errors.
  void reset({Map<String, dynamic> values = const <String, dynamic>{}}) {
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

    state = state.copyWith(
      values: nextValues,
      errors: nextErrors,
      visibleFields: nextVisibleFields,
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
