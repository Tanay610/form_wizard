import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/form_state.dart';
import '../validators/validators.dart';

/// Owns the immutable state for a form and exposes mutation APIs.
class FormStateNotifier extends Notifier<FormState> {
  @override
  FormState build() => const FormState();

  final Map<String, List<Validator>> _validators = <String, List<Validator>>{};

  /// Registers initial values and validators for the active field list.
  void configure({
    required Map<String, dynamic> initialValues,
    required Map<String, List<Validator>> validators,
    Map<String, int> initialFieldArrayCounts = const <String, int>{},
  }) {
    _validators
      ..clear()
      ..addAll(validators);

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
        fieldName: state.visibleFields[fieldName] ?? true,
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

    state = FormState(
      values: nextValues,
      errors: nextErrors,
      visibleFields: nextVisibleFields,
      fieldArrays: Map<String, List<String>>.unmodifiable(nextFieldArrays),
      nextArrayItemId: nextArrayItemId,
    );
  }

  /// Updates one field and revalidates only that field.
  void updateFieldValue(String fieldName, dynamic value) {
    state = state.setFieldValue(fieldName, value);
    validateField(fieldName);
  }

  /// Sets an error for a field.
  void setFieldError(String fieldName, String? error) {
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
    if (state.visibleFields[fieldName] == false) {
      setFieldError(fieldName, null);
      return true;
    }

    final value = state.values[fieldName]?.toString();
    final validators = _validators[fieldName] ?? const <Validator>[];

    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        setFieldError(fieldName, result);
        return false;
      }
    }

    setFieldError(fieldName, null);
    return true;
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

/// Global form state provider.
///
/// Widgets should prefer `.select` on this provider to subscribe to one field:
/// `ref.watch(formStateProvider.select((state) => state.values[fieldName]))`.
final formStateProvider = NotifierProvider<FormStateNotifier, FormState>(
  FormStateNotifier.new,
);

/// Derived form validity provider.
///
/// This watches only the error map, so consumers such as submit buttons avoid
/// rebuilding for ordinary value changes that do not affect validity.
final formValidityProvider = Provider<bool>((ref) {
  return ref.watch(
    formStateProvider.select(
      (state) => state.errors.values.every((error) => error == null),
    ),
  );
});
