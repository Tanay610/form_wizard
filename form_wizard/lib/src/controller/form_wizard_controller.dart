import 'package:flutter/foundation.dart';

import '../models/form_state.dart' as form_wizard;
import '../models/form_wizard_field_array_model.dart';
import '../models/form_wizard_field_model.dart';
import '../providers/form_providers.dart';
import '../validators/validators.dart';

/// Controller facade for interacting with a [FormWizard].
///
/// The controller delegates mutations to Riverpod's [FormStateNotifier] and
/// mirrors global state into [ValueListenable]s for efficient external UI.
class FormWizardController {
  final ValueNotifier<bool> _isFormValid = ValueNotifier<bool>(true);
  final ValueNotifier<Map<String, dynamic>> _formValues =
      ValueNotifier<Map<String, dynamic>>(const <String, dynamic>{});
  final ValueNotifier<Map<String, String?>> _fieldErrors =
      ValueNotifier<Map<String, String?>>(const <String, String?>{});
  final ValueNotifier<Map<String, List<String>>> _fieldArrays =
      ValueNotifier<Map<String, List<String>>>(const <String, List<String>>{});

  FormStateNotifier? _notifier;

  /// Listen to this from submit buttons or parent widgets.
  ValueListenable<bool> get isFormValid => _isFormValid;

  /// Listen to this when a parent needs the entire value map.
  ValueListenable<Map<String, dynamic>> get formValues => _formValues;

  /// Listen to this when a parent needs the current validation errors.
  ValueListenable<Map<String, String?>> get fieldErrors => _fieldErrors;

  /// Listen to this when a parent needs dynamic field array item IDs.
  ValueListenable<Map<String, List<String>>> get fieldArrays => _fieldArrays;

  /// Current form values.
  Map<String, dynamic> get formData =>
      Map<String, dynamic>.unmodifiable(_formValues.value);

  /// Returns values for a dynamic field array grouped by item order.
  List<Map<String, dynamic>> getFieldArrayValues(String arrayName) {
    final itemIds = _fieldArrays.value[arrayName] ?? const <String>[];

    return [
      for (final itemId in itemIds)
        <String, dynamic>{
          for (final entry in _formValues.value.entries)
            if (entry.key.startsWith('$arrayName.$itemId.'))
              entry.key.substring('$arrayName.$itemId.'.length): entry.value,
        },
    ];
  }

  /// Attaches this controller to the Riverpod notifier owned by [FormWizard].
  void attach(FormStateNotifier notifier) {
    _notifier = notifier;
  }

  /// Configures the provider with fields, initial values, and validators.
  void configureFields(
    List<FormWizardFieldModel> fields, {
    List<FormWizardFieldArrayModel> fieldArrays =
        const <FormWizardFieldArrayModel>[],
  }) {
    final initialValues = <String, dynamic>{
      for (final field in fields) field.name: field.initialValue ?? '',
    };
    final validators = <String, List<Validator>>{
      for (final field in fields)
        field.name: List<Validator>.unmodifiable(
          field.validators ?? const <Validator>[],
        ),
    };
    final visibilityPredicates = <String, FormWizardVisibilityPredicate>{
      for (final field in fields)
        if (field.visibleWhen != null) field.name: field.visibleWhen!,
    };
    final visibilityDependencies = <String, List<String>>{
      for (final field in fields)
        if (field.visibleWhenDependsOn.isNotEmpty)
          field.name: List<String>.unmodifiable(field.visibleWhenDependsOn),
    };

    _notifier?.configure(
      initialValues: initialValues,
      validators: validators,
      visibilityPredicates: visibilityPredicates,
      visibilityDependencies: visibilityDependencies,
      initialFieldArrayCounts: {
        for (final fieldArray in fieldArrays)
          fieldArray.name: fieldArray.initialItemCount,
      },
    );
  }

  /// Called by [FormWizard] whenever Riverpod state changes.
  void sync(form_wizard.FormState state) {
    final nextValues = Map<String, dynamic>.unmodifiable(state.values);

    if (!mapEquals(_formValues.value, nextValues)) {
      _formValues.value = nextValues;
    }

    final nextErrors = Map<String, String?>.unmodifiable(state.errors);
    if (!mapEquals(_fieldErrors.value, nextErrors)) {
      _fieldErrors.value = nextErrors;
    }

    final nextFieldArrays = Map<String, List<String>>.unmodifiable({
      for (final entry in state.fieldArrays.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    });
    if (!mapEquals(_fieldArrays.value, nextFieldArrays)) {
      _fieldArrays.value = nextFieldArrays;
    }

    if (_isFormValid.value != state.isValid) {
      _isFormValid.value = state.isValid;
    }
  }

  /// Updates a single field value.
  void updateFieldValue(String fieldName, dynamic value) {
    _notifier?.updateFieldValue(fieldName, value);
  }

  /// Backwards-compatible alias for older package versions.
  void setValue(String fieldName, String? value) {
    updateFieldValue(fieldName, value);
  }

  /// Returns a field value.
  dynamic getValue(String fieldName) => _formValues.value[fieldName];

  /// Returns the latest known error for a field from the attached notifier.
  String? getError(String fieldName) => _fieldErrors.value[fieldName];

  /// Sets a field error manually.
  void setError(String fieldName, String? error) {
    _notifier?.setFieldError(fieldName, error);
  }

  /// Adds one item to a dynamic field array.
  void addFieldArrayItem(String arrayName) {
    _notifier?.addFieldArrayItem(arrayName);
  }

  /// Removes one item from a dynamic field array by item ID.
  void removeFieldArrayItem(String arrayName, String itemId) {
    _notifier?.removeFieldArrayItem(arrayName, itemId);
  }

  /// Reorders one item in a dynamic field array.
  void reorderFieldArrayItem(String arrayName, int oldIndex, int newIndex) {
    _notifier?.reorderFieldArrayItem(arrayName, oldIndex, newIndex);
  }

  /// Validates one field.
  bool validateField(String fieldName) {
    return _notifier?.validateField(fieldName) ?? false;
  }

  /// Validates the entire form.
  bool validateForm() {
    return _notifier?.validateForm() ?? false;
  }

  /// Backwards-compatible alias for older package versions.
  bool validateAll(Map<String, List<Validator>?> validatorsMap) {
    return validateForm();
  }

  /// Validates and submits the form.
  bool submitForm(void Function(Map<String, dynamic> values)? onValid) {
    final isValid = validateForm();
    if (isValid) {
      onValid?.call(formData);
    }
    return isValid;
  }

  /// Releases resources owned by this controller.
  void dispose() {
    _isFormValid.dispose();
    _formValues.dispose();
    _fieldErrors.dispose();
    _fieldArrays.dispose();
  }
}
