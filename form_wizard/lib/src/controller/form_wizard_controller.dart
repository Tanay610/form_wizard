import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  final ValueNotifier<bool> _isValidating = ValueNotifier<bool>(false);

  FormStateNotifier? _notifier;
  final Map<String, FormWizardValueTransformer> _valueTransformers =
      <String, FormWizardValueTransformer>{};
  final Map<String, FocusNode> _focusNodes = <String, FocusNode>{};
  final Map<String, GlobalKey> _fieldKeys = <String, GlobalKey>{};

  /// Listen to this from submit buttons or parent widgets.
  ValueListenable<bool> get isFormValid => _isFormValid;

  /// Listen to this when a parent needs the entire value map.
  ValueListenable<Map<String, dynamic>> get formValues => _formValues;

  /// Listen to this when a parent needs the current validation errors.
  ValueListenable<Map<String, String?>> get fieldErrors => _fieldErrors;

  /// Listen to this when a parent needs dynamic field array item IDs.
  ValueListenable<Map<String, List<String>>> get fieldArrays => _fieldArrays;

  /// Listen to this when async validation is running.
  ValueListenable<bool> get isValidating => _isValidating;

  /// Current form values.
  Map<String, dynamic> get formData =>
      Map<String, dynamic>.unmodifiable(_formValues.value);

  /// Current form values after applying configured value transformers.
  Map<String, dynamic> get transformedFormData {
    final rawValues = _formValues.value;
    final context = FormWizardValidationContext(
      Map<String, dynamic>.unmodifiable(rawValues),
    );

    return Map<String, dynamic>.unmodifiable({
      for (final entry in rawValues.entries)
        entry.key:
            _valueTransformers[entry.key]?.call(entry.value, context) ??
            entry.value,
    });
  }

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
    _valueTransformers
      ..clear()
      ..addEntries(
        fields
            .where((field) => field.valueTransformer != null)
            .map(
              (field) => MapEntry<String, FormWizardValueTransformer>(
                field.name,
                field.valueTransformer!,
              ),
            ),
      );

    final initialValues = <String, dynamic>{
      for (final field in fields) field.name: field.initialValue ?? '',
    };
    final validators = <String, List<Validator>>{
      for (final field in fields)
        field.name: List<Validator>.unmodifiable(
          field.validators ?? const <Validator>[],
        ),
    };
    final contextValidators = <String, List<FormWizardContextValidator>>{
      for (final field in fields)
        field.name: List<FormWizardContextValidator>.unmodifiable(
          field.contextValidators ?? const <FormWizardContextValidator>[],
        ),
    };
    final asyncValidators = <String, List<FormWizardAsyncValidator>>{
      for (final field in fields)
        field.name: List<FormWizardAsyncValidator>.unmodifiable(
          field.asyncValidators ?? const <FormWizardAsyncValidator>[],
        ),
    };
    final asyncValidationDebounces = <String, Duration>{
      for (final field in fields)
        if ((field.asyncValidators ?? const <FormWizardAsyncValidator>[])
            .isNotEmpty)
          field.name: field.asyncValidationDebounce,
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
    final validationDependencies = <String, List<String>>{
      for (final field in fields)
        if (field.validationDependsOn.isNotEmpty)
          field.name: List<String>.unmodifiable(field.validationDependsOn),
    };

    _notifier?.configure(
      initialValues: initialValues,
      validators: validators,
      contextValidators: contextValidators,
      asyncValidators: asyncValidators,
      asyncValidationDebounces: asyncValidationDebounces,
      visibilityPredicates: visibilityPredicates,
      visibilityDependencies: visibilityDependencies,
      validationDependencies: validationDependencies,
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

    final nextIsValidating = state.validatingFields.any(
      (fieldName) => state.visibleFields[fieldName] != false,
    );
    if (_isValidating.value != nextIsValidating) {
      _isValidating.value = nextIsValidating;
    }
  }

  /// Registers a rendered field so invalid submits can focus and scroll to it.
  void registerField(String fieldName, FocusNode focusNode, GlobalKey key) {
    _focusNodes[fieldName] = focusNode;
    _fieldKeys[fieldName] = key;
  }

  /// Removes a rendered field registration.
  void unregisterField(String fieldName, FocusNode focusNode) {
    if (_focusNodes[fieldName] == focusNode) {
      _focusNodes.remove(fieldName);
      _fieldKeys.remove(fieldName);
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

  /// Validates one field and waits for async validators.
  Future<bool> validateFieldAsync(String fieldName) {
    return _notifier?.validateFieldAsync(fieldName) ?? Future.value(false);
  }

  /// Validates selected fields and waits for async validators.
  Future<bool> validateFieldsAsync(Iterable<String> fieldNames) {
    return _notifier?.validateFieldsAsync(fieldNames) ?? Future.value(false);
  }

  /// Validates the entire form.
  bool validateForm() {
    return _notifier?.validateForm() ?? false;
  }

  /// Validates the entire form and waits for async validators.
  Future<bool> validateFormAsync() {
    return _notifier?.validateFormAsync() ?? Future.value(false);
  }

  /// Backwards-compatible alias for older package versions.
  bool validateAll(Map<String, List<Validator>?> validatorsMap) {
    return validateForm();
  }

  /// Validates and submits the form.
  bool submitForm(
    void Function(Map<String, dynamic> values)? onValid, {
    bool transformValues = false,
    bool focusFirstInvalid = true,
  }) {
    final isValid = validateForm();
    if (isValid) {
      onValid?.call(transformValues ? transformedFormData : formData);
    } else if (focusFirstInvalid) {
      focusFirstInvalidField();
    }
    return isValid;
  }

  /// Validates, waits for async validators, and submits the form.
  Future<bool> submitFormAsync(
    void Function(Map<String, dynamic> values)? onValid, {
    bool transformValues = false,
    bool focusFirstInvalid = true,
  }) async {
    final isValid = await validateFormAsync();
    if (isValid) {
      onValid?.call(transformValues ? transformedFormData : formData);
    } else if (focusFirstInvalid) {
      focusFirstInvalidField();
    }
    return isValid;
  }

  /// Focuses and scrolls to the first currently rendered invalid field.
  bool focusFirstInvalidField() {
    for (final entry in _fieldErrors.value.entries) {
      if (entry.value == null) continue;

      final focusNode = _focusNodes[entry.key];
      final context = _fieldKeys[entry.key]?.currentContext;

      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }

      if (focusNode != null && focusNode.canRequestFocus) {
        focusNode.requestFocus();
        return true;
      }

      if (context != null) return true;
    }

    return false;
  }

  /// Releases resources owned by this controller.
  void dispose() {
    _isFormValid.dispose();
    _formValues.dispose();
    _fieldErrors.dispose();
    _fieldArrays.dispose();
    _isValidating.dispose();
    _focusNodes.clear();
    _fieldKeys.clear();
  }
}
