
import 'package:flutter/material.dart';

import '../controller/form_wizard_controller.dart';
import '../models/form_wizard_field_model.dart';
import 'form_wizard_field.dart';

class FormWizard extends StatelessWidget {
  final List<FormWizardFieldModel> fields;
  final FormWizardController controller;
  final void Function(Map<String, String?> values)? onSubmit;
  final Widget? submitButton;

  const FormWizard({
    super.key,
    required this.fields,
    required this.controller,
    this.onSubmit,
    this.submitButton,
  });

  @override
  Widget build(BuildContext context) {
    final validatorsMap = {
      for (var field in fields) field.name: field.validators
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...fields.map(
          (field) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: FormWizardField(
              model: field,
              controller: controller,
            ),
          ),
        ),
        const SizedBox(height: 16),
        submitButton ??
            ElevatedButton(
              onPressed: () {
                final isValid = controller.validateAll(validatorsMap);
                if (isValid) {
                  onSubmit?.call(controller.formData);
                }
              },
              child: const Text('Submit'),
            ),
      ],
    );
  }
}
