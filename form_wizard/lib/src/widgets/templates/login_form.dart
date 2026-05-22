import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../../validators/validators.dart';
import '../form_wizard_form.dart';
import 'template_options.dart';

/// Ready-to-use login form.
class LoginForm extends StatelessWidget {
  /// Creates a login template.
  LoginForm({
    super.key,
    required this.onLogin,
    this.identityType = FormWizardIdentityType.email,
    this.rememberMe = false,
    this.forgotPasswordLink,
    this.identityField,
    this.passwordField,
    this.submitLabel = 'Login',
    FormWizardController? controller,
  }) : controller = controller ?? FormWizardController();

  final FormWizardIdentityType identityType;
  final bool rememberMe;
  final VoidCallback? forgotPasswordLink;
  final FormWizardFieldModel? identityField;
  final FormWizardFieldModel? passwordField;
  final String submitLabel;
  final void Function(String identity, String password) onLogin;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context) {
    return FormWizard(
      controller: controller,
      fields: [
        identityField ?? identityFieldFor(identityType),
        passwordField ?? FormWizardFieldPresets.passwordField(),
      ],
      submitButton: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rememberMe || forgotPasswordLink != null)
            _LoginExtras(
              showRememberMe: rememberMe,
              forgotPasswordLink: forgotPasswordLink,
            ),
          ElevatedButton(
            onPressed:
                () => controller.submitForm((values) {
                  onLogin(
                    values[identityName(identityType)]?.toString() ?? '',
                    values['password']?.toString() ?? '',
                  );
                }),
            child: Text(submitLabel),
          ),
        ],
      ),
      onSubmit: (_) {},
    );
  }

  /// Builds the default identity field for [type].
  static FormWizardFieldModel identityFieldFor(FormWizardIdentityType type) {
    return switch (type) {
      FormWizardIdentityType.email => FormWizardFieldPresets.emailField(),
      FormWizardIdentityType.phone => FormWizardFieldPresets.phoneField(),
      FormWizardIdentityType.username => FormWizardFieldModel(
        name: 'username',
        label: 'Username',
        type: FieldType.text,
        validators: [Validators.required()],
      ),
    };
  }

  /// Returns the default field name for [type].
  static String identityName(FormWizardIdentityType type) {
    return switch (type) {
      FormWizardIdentityType.email => 'email',
      FormWizardIdentityType.phone => 'phone',
      FormWizardIdentityType.username => 'username',
    };
  }
}

class _LoginExtras extends StatefulWidget {
  const _LoginExtras({
    required this.showRememberMe,
    required this.forgotPasswordLink,
  });

  final bool showRememberMe;
  final VoidCallback? forgotPasswordLink;

  @override
  State<_LoginExtras> createState() => _LoginExtrasState();
}

class _LoginExtrasState extends State<_LoginExtras> {
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.showRememberMe)
          Expanded(
            child: CheckboxListTile(
              value: _rememberMe,
              onChanged:
                  (value) => setState(() => _rememberMe = value ?? false),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Remember me'),
            ),
          )
        else
          const Spacer(),
        if (widget.forgotPasswordLink != null)
          TextButton(
            onPressed: widget.forgotPasswordLink,
            child: const Text('Forgot password?'),
          ),
      ],
    );
  }
}
