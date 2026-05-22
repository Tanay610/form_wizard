import 'package:flutter/material.dart';

import 'models/form_wizard_field_model.dart';
import 'validators/validators.dart';

/// Composable field presets for common form inputs.
class FormWizardFieldPresets {
  const FormWizardFieldPresets._();

  /// Email text field with required and email validation.
  static FormWizardFieldModel emailField({
    String name = 'email',
    String label = 'Email',
    String? hint,
    bool required = true,
    List<Validator> validators = const <Validator>[],
  }) {
    return FormWizardFieldModel(
      name: name,
      label: label,
      hint: hint,
      type: FieldType.email,
      validators: [
        if (required) Validators.required(),
        Validators.email(),
        ...validators,
      ],
      keyboardType: TextInputType.emailAddress,
    );
  }

  /// Phone field with phone validation.
  static FormWizardFieldModel phoneField({
    String name = 'phone',
    String label = 'Phone',
    String? hint,
    bool required = true,
    List<Validator> validators = const <Validator>[],
  }) {
    return FormWizardFieldModel(
      name: name,
      label: label,
      hint: hint,
      type: FieldType.text,
      keyboardType: TextInputType.phone,
      validators: [
        if (required) Validators.required(),
        Validators.phone(),
        ...validators,
      ],
    );
  }

  /// Password field with obscured input.
  static FormWizardFieldModel passwordField({
    String name = 'password',
    String label = 'Password',
    String? hint,
    bool required = true,
    int minLength = 8,
    List<Validator> validators = const <Validator>[],
  }) {
    return FormWizardFieldModel(
      name: name,
      label: label,
      hint: hint,
      type: FieldType.custom,
      validators: [
        if (required) Validators.required(),
        Validators.minLength(minLength),
        ...validators,
      ],
      customBuilder: (controller, errorText, onChanged) {
        return _PasswordFieldPreset(
          controller: controller,
          errorText: errorText,
          onChanged: onChanged,
          label: label,
          hint: hint,
        );
      },
    );
  }

  /// Numeric OTP field for 4 or 6 digit codes.
  static FormWizardFieldModel otpField({
    String name = 'otp',
    String label = 'OTP',
    int length = 6,
    List<Validator> validators = const <Validator>[],
  }) {
    return FormWizardFieldModel(
      name: name,
      label: label,
      type: FieldType.number,
      keyboardType: TextInputType.number,
      validators: [
        Validators.required(),
        Validators.number(),
        Validators.exactLength(length, message: 'Enter the $length-digit code'),
        ...validators,
      ],
    );
  }

  /// Full name field.
  static FormWizardFieldModel nameField({
    String name = 'name',
    String label = 'Full Name',
    String? hint,
    bool required = true,
    List<Validator> validators = const <Validator>[],
  }) {
    return FormWizardFieldModel(
      name: name,
      label: label,
      hint: hint,
      type: FieldType.text,
      validators: [if (required) Validators.required(), ...validators],
    );
  }

  /// Street address field.
  static FormWizardFieldModel streetField({
    String name = 'street',
    String label = 'Street Address',
    String? hint,
    bool required = true,
    List<Validator> validators = const <Validator>[],
  }) {
    return FormWizardFieldModel(
      name: name,
      label: label,
      hint: hint,
      type: FieldType.text,
      validators: [if (required) Validators.required(), ...validators],
    );
  }

  /// City field.
  static FormWizardFieldModel cityField({
    String name = 'city',
    String label = 'City',
    bool required = true,
    List<Validator> validators = const <Validator>[],
  }) {
    return FormWizardFieldModel(
      name: name,
      label: label,
      type: FieldType.text,
      validators: [if (required) Validators.required(), ...validators],
    );
  }

  /// ZIP/postal code field.
  static FormWizardFieldModel zipField({
    String name = 'zip',
    String label = 'ZIP / Postal Code',
    bool required = true,
    List<Validator> validators = const <Validator>[],
  }) {
    return FormWizardFieldModel(
      name: name,
      label: label,
      type: FieldType.text,
      keyboardType: TextInputType.streetAddress,
      validators: [if (required) Validators.required(), ...validators],
    );
  }

  /// Country dropdown with a practical default country list.
  static FormWizardFieldModel countryDropdown({
    String name = 'country',
    String label = 'Country',
    List<String> countries = const <String>[
      'Australia',
      'Brazil',
      'Canada',
      'France',
      'Germany',
      'India',
      'Japan',
      'United Kingdom',
      'United States',
    ],
    bool required = true,
    List<Validator> validators = const <Validator>[],
  }) {
    return FormWizardFieldModel(
      name: name,
      label: label,
      type: FieldType.dropdown,
      options: countries,
      validators: [if (required) Validators.required(), ...validators],
    );
  }
}

class _PasswordFieldPreset extends StatefulWidget {
  const _PasswordFieldPreset({
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final String label;
  final String? hint;

  @override
  State<_PasswordFieldPreset> createState() => _PasswordFieldPresetState();
}

class _PasswordFieldPresetState extends State<_PasswordFieldPreset> {
  late final ValueNotifier<bool> _obscureNotifier;

  @override
  void initState() {
    super.initState();
    _obscureNotifier = ValueNotifier(true);
  }

  @override
  void dispose() {
    _obscureNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _obscureNotifier,
      builder: (context, obscure, _) {
        return TextField(
          controller: widget.controller,
          obscureText: obscure,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            errorText: widget.errorText,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: obscure ? 'Show password' : 'Hide password',
              onPressed: () => _obscureNotifier.value = !obscure,
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        );
      },
    );
  }
}
