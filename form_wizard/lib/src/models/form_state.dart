/// Immutable state for a [FormWizard] instance.
///
/// [values] stores each field value by field name. [errors] stores the current
/// validation error for each field, where `null` means the field is valid.
class FormState {
  /// Creates immutable form state.
  const FormState({
    this.values = const <String, dynamic>{},
    this.errors = const <String, String?>{},
    this.visibleFields = const <String, bool>{},
    this.fieldArrays = const <String, List<String>>{},
    this.nextArrayItemId = 0,
  });

  /// Field values keyed by [FormWizardFieldModel.name].
  final Map<String, dynamic> values;

  /// Field validation errors keyed by [FormWizardFieldModel.name].
  final Map<String, String?> errors;

  /// Field visibility keyed by [FormWizardFieldModel.name].
  final Map<String, bool> visibleFields;

  /// Dynamic field array item IDs keyed by array name.
  final Map<String, List<String>> fieldArrays;

  /// Monotonic counter used to create stable dynamic field array item IDs.
  final int nextArrayItemId;

  /// Returns a copy of this state with selected maps replaced.
  FormState copyWith({
    Map<String, dynamic>? values,
    Map<String, String?>? errors,
    Map<String, bool>? visibleFields,
    Map<String, List<String>>? fieldArrays,
    int? nextArrayItemId,
  }) {
    return FormState(
      values: values ?? this.values,
      errors: errors ?? this.errors,
      visibleFields: visibleFields ?? this.visibleFields,
      fieldArrays: fieldArrays ?? this.fieldArrays,
      nextArrayItemId: nextArrayItemId ?? this.nextArrayItemId,
    );
  }

  /// Returns a copy with a single field value updated.
  FormState setFieldValue(String fieldName, dynamic value) {
    return copyWith(values: <String, dynamic>{...values, fieldName: value});
  }

  /// Returns a copy with a single field error updated.
  FormState setFieldError(String fieldName, String? error) {
    return copyWith(errors: <String, String?>{...errors, fieldName: error});
  }

  /// Returns a copy with a single field visibility updated.
  FormState setFieldVisibility(String fieldName, bool isVisible) {
    return copyWith(
      visibleFields: <String, bool>{...visibleFields, fieldName: isVisible},
    );
  }

  /// Whether the current state has no validation errors.
  bool get isValid {
    return errors.entries.every((entry) {
      if (visibleFields[entry.key] == false) return true;
      return entry.value == null;
    });
  }
}
