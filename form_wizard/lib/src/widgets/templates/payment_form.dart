import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../../validators/validators.dart';
import '../form_wizard_form.dart';

/// Ready-to-use payment details form.
class PaymentForm extends StatelessWidget {
  /// Creates a payment template.
  PaymentForm({
    super.key,
    required this.onSubmit,
    this.cardNumberField,
    this.expiryField,
    this.cvvField,
    this.nameField,
    this.submitLabel = 'Pay',
    FormWizardController? controller,
  }) : controller = controller ?? FormWizardController();

  final FormWizardFieldModel? cardNumberField;
  final FormWizardFieldModel? expiryField;
  final FormWizardFieldModel? cvvField;
  final FormWizardFieldModel? nameField;
  final String submitLabel;
  final void Function(Map<String, dynamic> paymentDetails) onSubmit;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context) {
    return FormWizard(
      controller: controller,
      fields: [
        cardNumberField ??
            FormWizardFieldModel(
              name: 'card_number',
              label: 'Card Number',
              type: FieldType.number,
              validators: [
                Validators.required(),
                Validators.regex(
                  RegExp(r'^\d{13,19}$'),
                  message: 'Invalid card number',
                ),
              ],
            ),
        expiryField ??
            FormWizardFieldModel(
              name: 'expiry',
              label: 'Expiry MM/YY',
              type: FieldType.text,
              validators: [
                Validators.required(),
                Validators.regex(
                  RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$'),
                  message: 'Use MM/YY',
                ),
              ],
            ),
        cvvField ??
            FormWizardFieldModel(
              name: 'cvv',
              label: 'CVV',
              type: FieldType.number,
              validators: [
                Validators.required(),
                Validators.regex(RegExp(r'^\d{3,4}$'), message: 'Invalid CVV'),
              ],
            ),
        nameField ??
            FormWizardFieldPresets.nameField(
              name: 'cardholder_name',
              label: 'Name on Card',
            ),
      ],
      submitButton: ElevatedButton(
        onPressed: () => controller.submitForm(onSubmit),
        child: Text(submitLabel),
      ),
      onSubmit: (_) {},
    );
  }
}
