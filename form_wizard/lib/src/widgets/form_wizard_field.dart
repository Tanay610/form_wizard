import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controller/form_wizard_controller.dart';
import '../models/form_wizard_field_model.dart';

class FormWizardField extends StatelessWidget {
  final FormWizardFieldModel model;
  final FormWizardController controller;

  const FormWizardField({
    super.key,
    required this.model,
    required this.controller,
  });

  TextInputType _getKeyboardType(FieldType type) {
    switch (type) {
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.number:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  // bool _isObscure(FieldType type) => type == FieldType.password;

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(
      text: controller.getValue(model.name) ?? model.initialValue ?? '',
    );

    return Obx(() {
      final errorText = controller.getError(model.name);

      void onChanged(String val) {
        controller.setValue(model.name, val);
        controller.validateField(model.name, val, model.validators);
      }

      // If user provides a custom builder, use that
      if (model.type == FieldType.custom && model.customBuilder != null) {
        return model.customBuilder!(textController, errorText, onChanged);
      }

      // If user provides a custom builder, use that
      if (model.type == FieldType.custom && model.customBuilder != null) {
        return model.customBuilder!(textController, errorText, onChanged);
      }

      // 🎯 Handle Dropdown field
      if (model.type == FieldType.dropdown && model.options != null) {
        return DropdownButtonFormField<String>(
          value: textController.text.isNotEmpty ? textController.text : null,
          items:
              model.options!
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          onChanged: (val) {
            if (val != null) {
              textController.text = val;
              onChanged(val);
            }
          },
          decoration:
              model.decorationBuilder?.call(errorText, textController) ??
              InputDecoration(
                labelText: model.label,
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
        );
      }

      // 🎯 Handle Date Picker field
      if (model.type == FieldType.date) {
        return TextFormField(
          controller: textController,
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              final formatted =
                  model.dateFormatter?.call(picked) ??
                  DateFormat('yyyy-MM-dd').format(picked);
              textController.text = formatted;
              onChanged(formatted);
            }
          },
          decoration:
              model.decorationBuilder?.call(errorText, textController) ??
              InputDecoration(
                labelText: model.label,
                hintText: 'Select a date',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
        );
      }

      // Default field rendering
      return TextFormField(
        controller: textController,
        obscureText: model.obscureText ?? model.type == FieldType.password,
        keyboardType:
            model.keyboardType ??
            (model.type == FieldType.number
                ? TextInputType.number
                : model.type == FieldType.email
                ? TextInputType.emailAddress
                : TextInputType.text),
        decoration:
            model.decorationBuilder != null
                ? model.decorationBuilder!(errorText, textController)
                : InputDecoration(
                  labelText: model.label,
                  hintText: model.hint,
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
        onChanged: onChanged,
      );
    });
  }
}
