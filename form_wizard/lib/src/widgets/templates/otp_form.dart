import 'dart:async';

import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../form_wizard_form.dart';

class OTPVerificationForm extends StatelessWidget {
  OTPVerificationForm({
    super.key,
    required this.onVerify,
    this.onResend,
    this.otpLength = 6,
    this.resendCooldownSeconds = 30,
    this.otpField,
    this.verifyLabel = 'Verify',
    this.resendLabel = 'Resend code',
    FormWizardController? controller,
  }) : controller = controller ?? FormWizardController();

  final int otpLength;
  final int resendCooldownSeconds;
  final FormWizardFieldModel? otpField;
  final String verifyLabel;
  final String resendLabel;
  final void Function(String otp) onVerify;
  final VoidCallback? onResend;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context) {
    return FormWizard(
      controller: controller,
      fields: [
        otpField ??
            FormWizardFieldPresets.otpField(
              length: otpLength,
              label: '$otpLength-digit code',
            ),
      ],
      submitButton: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed:
                () => controller.submitForm(
                  (values) => onVerify(values['otp']?.toString() ?? ''),
                ),
            child: Text(verifyLabel),
          ),
          if (onResend != null)
            _OtpResendButton(
              label: resendLabel,
              cooldownSeconds: resendCooldownSeconds,
              onResend: onResend!,
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
