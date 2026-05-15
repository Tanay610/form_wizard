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
    final remainingNotifier = ValueNotifier<int>(0);
    Timer? timer;

    void startCooldown() {
      timer?.cancel();
      remainingNotifier.value = resendCooldownSeconds;
      timer = Timer.periodic(const Duration(seconds: 1), (activeTimer) {
        if (remainingNotifier.value <= 1) {
          activeTimer.cancel();
          remainingNotifier.value = 0;
        } else {
          remainingNotifier.value--;
        }
      });
    }

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
            onPressed: () => controller.submitForm(
              (values) => onVerify(values['otp']?.toString() ?? ''),
            ),
            child: Text(verifyLabel),
          ),
          if (onResend != null)
            ValueListenableBuilder(
              valueListenable: remainingNotifier,
              builder: (context, remaining, _) {
                return TextButton(
                  onPressed: remaining == 0
                      ? () {
                          onResend!();
                          startCooldown();
                        }
                      : null,
                  child: Text(
                    remaining == 0
                        ? resendLabel
                        : '$resendLabel ($remaining)',
                  ),
                );
              },
            ),
        ],
      ),
      onSubmit: (_) {},
    );
  }
}