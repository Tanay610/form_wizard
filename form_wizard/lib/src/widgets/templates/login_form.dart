import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../../validators/validators.dart';
import '../form_wizard_form.dart';
import 'template_options.dart';

/// Ready-to-use login form.
class LoginForm extends StatefulWidget {
  /// Creates a login template.
  const LoginForm({
    super.key,
    required this.onLogin,
    this.identityType = FormWizardIdentityType.email,
    this.rememberMe = false,
    this.forgotPasswordLink,
    this.identityField,
    this.passwordField,
    this.submitLabel = 'Login',
    this.controller,
  });

  final FormWizardIdentityType identityType;
  final bool rememberMe;
  final VoidCallback? forgotPasswordLink;
  final FormWizardFieldModel? identityField;
  final FormWizardFieldModel? passwordField;
  final String submitLabel;
  final void Function(String identity, String password) onLogin;
  final FormWizardController? controller;

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

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late FormWizardController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FormWizardController();
  }

  @override
  void didUpdateWidget(covariant LoginForm oldWidget) {
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
        widget.identityField ?? LoginForm.identityFieldFor(widget.identityType),
        widget.passwordField ?? FormWizardFieldPresets.passwordField(),
      ],
      submitButton: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.rememberMe || widget.forgotPasswordLink != null)
            _LoginExtras(
              showRememberMe: widget.rememberMe,
              forgotPasswordLink: widget.forgotPasswordLink,
            ),
          ElevatedButton(
            onPressed:
                () => _controller.submitForm((values) {
                  widget.onLogin(
                    values[LoginForm.identityName(widget.identityType)]
                            ?.toString() ??
                        '',
                    values['password']?.toString() ?? '',
                  );
                }),
            child: Text(widget.submitLabel),
          ),
        ],
      ),
      onSubmit: (_) {},
    );
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
