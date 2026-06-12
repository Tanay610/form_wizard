import 'dart:async';

import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../form_wizard_form.dart';

class OTPVerificationForm extends StatefulWidget {
  const OTPVerificationForm({
    super.key,
    required this.onVerify,
    this.onResend,
    this.otpLength = 6,
    this.resendCooldownSeconds = 30,
    this.otpField,
    this.verifyLabel = 'Verify',
    this.resendLabel = 'Resend code',
    this.controller,
  });

  final int otpLength;
  final int resendCooldownSeconds;
  final FormWizardFieldModel? otpField;
  final String verifyLabel;
  final String resendLabel;
  final void Function(String otp) onVerify;
  final VoidCallback? onResend;
  final FormWizardController? controller;

  @override
  State<OTPVerificationForm> createState() => _OTPVerificationFormState();
}

class _OTPVerificationFormState extends State<OTPVerificationForm> {
  late FormWizardController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FormWizardController();
  }

  @override
  void didUpdateWidget(covariant OTPVerificationForm oldWidget) {
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
        widget.otpField ??
            FormWizardFieldPresets.otpField(
              length: widget.otpLength,
              label: '${widget.otpLength}-digit code',
            ),
      ],
      submitButton: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed:
                () => _controller.submitForm(
                  (values) => widget.onVerify(values['otp']?.toString() ?? ''),
                ),
            child: Text(widget.verifyLabel),
          ),
          if (widget.onResend != null)
            _OtpResendButton(
              label: widget.resendLabel,
              cooldownSeconds: widget.resendCooldownSeconds,
              onResend: widget.onResend!,
            ),
        ],
      ),
      onSubmit: (_) {},
    );
  }
}

class _OtpResendButton extends StatefulWidget {
  const _OtpResendButton({
    required this.label,
    required this.cooldownSeconds,
    required this.onResend,
  });

  final String label;
  final int cooldownSeconds;
  final VoidCallback onResend;

  @override
  State<_OtpResendButton> createState() => _OtpResendButtonState();
}

class _OtpResendButtonState extends State<_OtpResendButton> {
  final ValueNotifier<int> _remaining = ValueNotifier<int>(0);
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _remaining.value = widget.cooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.value <= 1) {
        timer.cancel();
        _remaining.value = 0;
      } else {
        _remaining.value--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _remaining,
      builder: (context, remaining, _) {
        return TextButton(
          onPressed:
              remaining == 0
                  ? () {
                    widget.onResend();
                    _startCooldown();
                  }
                  : null,
          child: Text(
            remaining == 0 ? widget.label : '${widget.label} ($remaining)',
          ),
        );
      },
    );
  }
}
