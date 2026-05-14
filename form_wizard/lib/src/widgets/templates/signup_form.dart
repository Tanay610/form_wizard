import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../../validators/validators.dart';
import '../form_wizard_form.dart';
import 'login_form.dart';
import 'template_options.dart';

/// Ready-to-use signup form.
class SignupForm extends StatelessWidget {
  /// Creates a signup template.
  SignupForm({
    super.key,
    required this.onSignup,
    this.identityType = FormWizardIdentityType.email,
    this.requireTermsAcceptance = false,
    this.nameField,
    this.identityField,
    this.passwordField,
    this.confirmPasswordField,
    this.submitLabel = 'Create Account',
    FormWizardController? controller,
  }) : controller = controller ?? FormWizardController();

  final FormWizardIdentityType identityType;
  final bool requireTermsAcceptance;
  final FormWizardFieldModel? nameField;
  final FormWizardFieldModel? identityField;
  final FormWizardFieldModel? passwordField;
  final FormWizardFieldModel? confirmPasswordField;
  final String submitLabel;
  final void Function(String name, String identity, String password) onSignup;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context) {
    return FormWizard(
      controller: controller,
      fields: [
        nameField ?? FormWizardFieldPresets.nameField(),
        identityField ?? LoginForm.identityFieldFor(identityType),
        passwordField ?? FormWizardFieldPresets.passwordField(),
        confirmPasswordField ??
            FormWizardFieldModel(
              name: 'confirm_password',
              label: 'Confirm Password',
              type: FieldType.password,
              validators: [
                Validators.required(),
                (value) =>
                    value == controller.formData['password']
                        ? null
                        : 'Passwords do not match',
              ],
            ),
        if (requireTermsAcceptance)
          FormWizardFieldModel(
            name: 'terms',
            label: 'Terms',
            type: FieldType.dropdown,
            options: const ['Accepted'],
            validators: [Validators.required(message: 'Accept the terms')],
          ),
      ],
      submitButton: ElevatedButton(
        onPressed:
            () => controller.submitForm((values) {
              onSignup(
                values['name']?.toString() ?? '',
                values[LoginForm.identityName(identityType)]?.toString() ?? '',
                values['password']?.toString() ?? '',
              );
            }),
        child: Text(submitLabel),
      ),
      onSubmit: (_) {},
    );
  }
}
