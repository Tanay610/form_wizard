import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../../validators/validators.dart';
import '../form_wizard_form.dart';
import 'login_form.dart';
import 'template_options.dart';

/// Ready-to-use signup form.
class SignupForm extends StatefulWidget {
  /// Creates a signup template.
  const SignupForm({
    super.key,
    required this.onSignup,
    this.identityType = FormWizardIdentityType.email,
    this.requireTermsAcceptance = false,
    this.nameField,
    this.identityField,
    this.passwordField,
    this.confirmPasswordField,
    this.submitLabel = 'Create Account',
    this.controller,
  });

  final FormWizardIdentityType identityType;
  final bool requireTermsAcceptance;
  final FormWizardFieldModel? nameField;
  final FormWizardFieldModel? identityField;
  final FormWizardFieldModel? passwordField;
  final FormWizardFieldModel? confirmPasswordField;
  final String submitLabel;
  final void Function(String name, String identity, String password) onSignup;
  final FormWizardController? controller;

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  late FormWizardController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FormWizardController();
  }

  @override
  void didUpdateWidget(covariant SignupForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    if (_ownsController) {
      _controller.dispose();
    }
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FormWizardController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormWizard(
      controller: _controller,
      fields: [
        widget.nameField ?? FormWizardFieldPresets.nameField(),
        widget.identityField ?? LoginForm.identityFieldFor(widget.identityType),
        widget.passwordField ?? FormWizardFieldPresets.passwordField(),
        widget.confirmPasswordField ??
            FormWizardFieldModel(
              name: 'confirm_password',
              label: 'Confirm Password',
              type: FieldType.password,
              validators: [Validators.required()],
              contextValidators: [
                Validators.matchesField(
                  'password',
                  message: 'Passwords do not match',
                ),
              ],
              validationDependsOn: const ['password'],
            ),
        if (widget.requireTermsAcceptance)
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
            () => _controller.submitForm((values) {
              widget.onSignup(
                values['name']?.toString() ?? '',
                values[LoginForm.identityName(widget.identityType)]
                        ?.toString() ??
                    '',
                values['password']?.toString() ?? '',
              );
            }),
        child: Text(widget.submitLabel),
      ),
      onSubmit: (_) {},
    );
  }
}
