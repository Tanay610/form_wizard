import 'package:flutter/material.dart';

import '../validators/validators.dart';

enum FieldType { text, number, password, email, custom, dropdown, date }

/// Predicate used to decide whether a field should be visible.
typedef FormWizardVisibilityPredicate =
    bool Function(Map<String, dynamic> values);

class FormWizardFieldModel {
  /// Creates a field definition used by [FormWizard].
  final String name;
  final String label;
  final FieldType type;

  final String? hint;
  final String? initialValue;
  final List<Validator>? validators;

  final TextInputType? keyboardType;
  final bool? obscureText;
  final InputDecoration Function(
    String? errorText,
    TextEditingController controller,
  )?
  decorationBuilder;
  final List<String>? options;
  final String Function(DateTime)? dateFormatter;
  final FormWizardVisibilityPredicate? visibleWhen;
  final List<String> visibleWhenDependsOn;
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
    this.keyboardType,
    this.obscureText,
    this.decorationBuilder,
    this.customBuilder,
    this.options,
    this.dateFormatter,
    this.visibleWhen,
    this.visibleWhenDependsOn = const <String>[],
  });
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
