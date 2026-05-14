import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../../validators/validators.dart';
import '../form_wizard_form.dart';

/// Ready-to-use address form.
class AddressForm extends StatelessWidget {
  /// Creates an address template.
  AddressForm({
    super.key,
    required this.onSubmit,
    this.includeState = true,
    this.streetField,
    this.cityField,
    this.stateField,
    this.zipField,
    this.countryField,
    this.submitLabel = 'Save Address',
    FormWizardController? controller,
  }) : controller = controller ?? FormWizardController();

  final bool includeState;
  final FormWizardFieldModel? streetField;
  final FormWizardFieldModel? cityField;
  final FormWizardFieldModel? stateField;
  final FormWizardFieldModel? zipField;
  final FormWizardFieldModel? countryField;
  final String submitLabel;
  final void Function(Map<String, dynamic> addressMap) onSubmit;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context) {
    return FormWizard(
      controller: controller,
      fields: [
        streetField ?? FormWizardFieldPresets.streetField(),
        cityField ?? FormWizardFieldPresets.cityField(),
        if (includeState)
          stateField ??
              FormWizardFieldModel(
                name: 'state',
                label: 'State',
                type: FieldType.text,
                validators: [Validators.required()],
                visibleWhenDependsOn: const ['country'],
                visibleWhen:
                    (values) =>
                        values['country'] == null ||
                        values['country'] == 'United States' ||
                        values['country'] == 'Canada' ||
                        values['country'] == 'India',
              ),
        zipField ?? FormWizardFieldPresets.zipField(),
        countryField ?? FormWizardFieldPresets.countryDropdown(),
      ],
      submitButton: ElevatedButton(
        onPressed: () => controller.submitForm(onSubmit),
        child: Text(submitLabel),
      ),
      onSubmit: (_) {},
    );
  }
}
