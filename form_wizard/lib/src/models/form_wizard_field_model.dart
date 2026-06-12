import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../validators/validators.dart';

enum FieldType { text, number, password, email, custom, dropdown, date }

/// Predicate used to decide whether a field should be visible.
typedef FormWizardVisibilityPredicate =
    bool Function(Map<String, dynamic> values);

class FormWizardFieldModel {
  /// Creates a field definition used by `FormWizard`.
  final String name;

  /// Human-readable label used by the default field decoration.
  final String label;

  /// Determines which built-in field UI is rendered.
  final FieldType type;

  /// Optional placeholder/helper hint.
  final String? hint;

  /// Initial raw value for this field.
  final dynamic initialValue;

  /// Fast synchronous validators for this field only.
  final List<Validator>? validators;

  /// Synchronous validators that can inspect other form values.
  final List<FormWizardContextValidator>? contextValidators;

  /// Async validators for server-backed or expensive checks.
  final List<FormWizardAsyncValidator>? asyncValidators;

  /// Fields that should trigger this field to revalidate when they change.
  final List<String> validationDependsOn;

  /// Debounce used before async validation starts after typing.
  final Duration asyncValidationDebounce;

  /// Converts this field's raw value when callers request transformed output.
  final FormWizardValueTransformer? valueTransformer;

  /// Keyboard type for text entry fields.
  final TextInputType? keyboardType;

  /// Whether text should be obscured.
  final bool? obscureText;

  /// Whether the field accepts user input.
  final bool enabled;

  /// Whether the text field is read-only.
  final bool readOnly;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Input formatters applied to text entry fields.
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill hints passed to text entry fields.
  final Iterable<String>? autofillHints;

  /// Maximum input length.
  final int? maxLength;

  /// Maximum visible text lines.
  final int? maxLines;

  /// Minimum visible text lines.
  final int? minLines;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Called when the platform submit action is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Builds custom decoration for built-in field UIs.
  final InputDecoration Function(
    String? errorText,
    TextEditingController controller,
  )?
  decorationBuilder;

  /// Dropdown options when [type] is [FieldType.dropdown].
  final List<String>? options;

  /// Date formatter when [type] is [FieldType.date].
  final String Function(DateTime)? dateFormatter;

  /// Predicate deciding whether this field is visible.
  final FormWizardVisibilityPredicate? visibleWhen;

  /// Fields that should trigger [visibleWhen] to reevaluate.
  final List<String> visibleWhenDependsOn;

  /// Builder for completely custom field UI.
  final Widget Function(
    TextEditingController controller,
    String? errorText,
    void Function(String) onChanged,
  )?
  customBuilder;

  FormWizardFieldModel({
    required this.name,
    required this.label,
    required this.type,
    this.hint,
    this.initialValue,
    this.validators,
    this.contextValidators,
    this.asyncValidators,
    this.validationDependsOn = const <String>[],
    this.asyncValidationDebounce = const Duration(milliseconds: 350),
    this.valueTransformer,
    this.keyboardType,
    this.obscureText,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.decorationBuilder,
    this.customBuilder,
    this.options,
    this.dateFormatter,
    this.visibleWhen,
    this.visibleWhenDependsOn = const <String>[],
  });

  /// Whether this field is a password field.
  bool get isPassword => type == FieldType.password;

  /// Whether this field is an email field.
  bool get isEmail => type == FieldType.email;

  /// Whether this field is a number field.
  bool get isNumber => type == FieldType.number;

  /// Whether this field is a plain text field.
  bool get isText => type == FieldType.text;

  /// Whether this field has a hint.
  bool get hasHint => hint != null;

  /// Whether this field has an initial value.
  bool get hasInitialValue => initialValue != null;

  /// Whether this field has synchronous validators.
  bool get hasValidators => validators != null && validators!.isNotEmpty;
}

extension SmartFormFieldModelExtension on FormWizardFieldModel {
  bool get isPassword => type == FieldType.password;
}

extension FormWizardFieldModelExtension2 on FormWizardFieldModel {
  bool get isEmail => type == FieldType.email;
}

extension FormWizardFieldModelExtension3 on FormWizardFieldModel {
  bool get isNumber => type == FieldType.number;
}

extension FormWizardFieldModelExtension4 on FormWizardFieldModel {
  bool get isText => type == FieldType.text;
}

extension FormWizardFieldModelExtension5 on FormWizardFieldModel {
  bool get isHint => hint != null;
}

extension FormWizardFieldModelExtension6 on FormWizardFieldModel {
  bool get isInitialValue => initialValue != null;
}

extension FormWizardFieldModelExtension7 on FormWizardFieldModel {
  bool get isValidators => validators != null;
}

extension FormWizardFieldModelExtension8 on FormWizardFieldModel {
  bool get isHintOrInitialValue => isHint || isInitialValue;
}
