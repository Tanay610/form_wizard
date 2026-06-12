import 'package:flutter/material.dart';

import '../../controller/form_wizard_controller.dart';
import '../../field_presets.dart';
import '../../models/form_wizard_field_model.dart';
import '../../validators/validators.dart';
import '../form_wizard_form.dart';

/// Ready-to-use address form.
class AddressForm extends StatefulWidget {
  /// Creates an address template.
  const AddressForm({
    super.key,
    required this.onSubmit,
    this.includeState = true,
    this.streetField,
    this.cityField,
    this.stateField,
    this.zipField,
    this.countryField,
    this.submitLabel = 'Save Address',
    this.controller,
  });

  final bool includeState;
  final FormWizardFieldModel? streetField;
  final FormWizardFieldModel? cityField;
  final FormWizardFieldModel? stateField;
  final FormWizardFieldModel? zipField;
  final FormWizardFieldModel? countryField;
  final String submitLabel;
  final void Function(Map<String, dynamic> addressMap) onSubmit;
  final FormWizardController? controller;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  late FormWizardController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FormWizardController();
  }

  @override
  void didUpdateWidget(covariant AddressForm oldWidget) {
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
        widget.streetField ?? FormWizardFieldPresets.streetField(),
        widget.cityField ?? FormWizardFieldPresets.cityField(),
        if (widget.includeState)
          widget.stateField ??
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
        widget.zipField ?? FormWizardFieldPresets.zipField(),
        widget.countryField ?? FormWizardFieldPresets.countryDropdown(),
      ],
      submitButton: ElevatedButton(
        onPressed: () => _controller.submitForm(widget.onSubmit),
        child: Text(widget.submitLabel),
      ),
      onSubmit: (_) {},
    );
  }
}
