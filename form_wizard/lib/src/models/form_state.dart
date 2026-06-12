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
    this.dirtyFields = const <String>{},
    this.touchedFields = const <String>{},
    this.validatingFields = const <String>{},
    this.isSubmitted = false,
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

  /// Field names whose value has changed from its initial value.
  final Set<String> dirtyFields;

  /// Field names that have received user interaction or submit validation.
  final Set<String> touchedFields;

  /// Field names currently running asynchronous validation.
  final Set<String> validatingFields;

  /// Whether submit validation has been attempted.
  final bool isSubmitted;

  /// Monotonic counter used to create stable dynamic field array item IDs.
  final int nextArrayItemId;

  /// Returns a copy of this state with selected maps replaced.
  FormState copyWith({
    Map<String, dynamic>? values,
    Map<String, String?>? errors,
    Map<String, bool>? visibleFields,
    Map<String, List<String>>? fieldArrays,
    Set<String>? dirtyFields,
    Set<String>? touchedFields,
    Set<String>? validatingFields,
    bool? isSubmitted,
    int? nextArrayItemId,
  }) {
    return FormState(
      values: values ?? this.values,
      errors: errors ?? this.errors,
      visibleFields: visibleFields ?? this.visibleFields,
      fieldArrays: fieldArrays ?? this.fieldArrays,
      dirtyFields: dirtyFields ?? this.dirtyFields,
      touchedFields: touchedFields ?? this.touchedFields,
      validatingFields: validatingFields ?? this.validatingFields,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      nextArrayItemId: nextArrayItemId ?? this.nextArrayItemId,
    );
  }

  /// Returns a copy with a single field value updated.
  FormState setFieldValue(String fieldName, dynamic value) {
    return copyWith(values: <String, dynamic>{...values, fieldName: value});
  }

  /// Returns a copy with one field value and error updated together.
  FormState setFieldValueAndError(
    String fieldName,
    dynamic value,
    String? error,
  ) {
    return copyWith(
      values: <String, dynamic>{...values, fieldName: value},
      errors: <String, String?>{...errors, fieldName: error},
    );
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
    final hasVisiblePendingValidation = validatingFields.any(
      (fieldName) => visibleFields[fieldName] != false,
    );
    if (hasVisiblePendingValidation) return false;

    return errors.entries.every((entry) {
      if (visibleFields[entry.key] == false) return true;
      return entry.value == null;
    });
  }

  /// Whether [fieldName] has changed from its initial value.
  bool isDirty(String fieldName) => dirtyFields.contains(fieldName);

  /// Whether [fieldName] has been interacted with or validated on submit.
  bool isTouched(String fieldName) => touchedFields.contains(fieldName);

  /// Whether [fieldName] is currently running async validation.
  bool isValidating(String fieldName) => validatingFields.contains(fieldName);
}
