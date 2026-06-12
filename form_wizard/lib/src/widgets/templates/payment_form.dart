import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../../validators/validators.dart';
import '../form_wizard_form.dart';

/// Ready-to-use payment details form.
class PaymentForm extends StatefulWidget {
  /// Creates a payment template.
  const PaymentForm({
    super.key,
    required this.onSubmit,
    this.cardNumberField,
    this.expiryField,
    this.cvvField,
    this.nameField,
    this.submitLabel = 'Pay',
    this.controller,
  });

  final FormWizardFieldModel? cardNumberField;
  final FormWizardFieldModel? expiryField;
  final FormWizardFieldModel? cvvField;
  final FormWizardFieldModel? nameField;
  final String submitLabel;
  final void Function(Map<String, dynamic> paymentDetails) onSubmit;
  final FormWizardController? controller;

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  late FormWizardController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FormWizardController();
  }

  @override
  void didUpdateWidget(covariant PaymentForm oldWidget) {
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
        widget.cardNumberField ??
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
        widget.expiryField ??
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
        widget.cvvField ??
            FormWizardFieldModel(
              name: 'cvv',
              label: 'CVV',
              type: FieldType.number,
              validators: [
                Validators.required(),
                Validators.regex(RegExp(r'^\d{3,4}$'), message: 'Invalid CVV'),
              ],
            ),
        widget.nameField ??
            FormWizardFieldPresets.nameField(
              name: 'cardholder_name',
              label: 'Name on Card',
            ),
      ],
      submitButton: ElevatedButton(
        onPressed: () => _controller.submitForm(widget.onSubmit),
        child: Text(widget.submitLabel),
      ),
      onSubmit: (_) {},
    );
  }
}
