import 'package:flutter/material.dart';

enum FieldType {
  text,
  number,
  password,
  email,
  custom,
  dropdown,
  date,
}

class FormWizardFieldModel {
  final String name;
  final String label;
  final FieldType type;

  final String? hint;
  final String? initialValue;
  final List<String? Function(String?)>? validators;

  final TextInputType? keyboardType;
  final bool? obscureText;
    final InputDecoration Function(String? errorText, TextEditingController controller)? decorationBuilder;
    final List<String>? options; // for dropdown
final String Function(DateTime)? dateFormatter;
  final Widget Function(
    TextEditingController controller,
    String? errorText,
    void Function(String) onChanged,
  )? customBuilder;

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
    this.dateFormatter
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
