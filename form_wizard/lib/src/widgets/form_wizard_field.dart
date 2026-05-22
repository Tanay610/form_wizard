import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controller/form_wizard_controller.dart';
import '../models/form_wizard_field_model.dart';
import '../providers/form_providers.dart';

/// A self-contained form field that listens only to its own value and error.
class FormWizardField extends ConsumerStatefulWidget {
  final FormWizardFieldModel model;
  final FormWizardController controller;

  const FormWizardField({
    super.key,
    required this.model,
    required this.controller,
  });

  @override
  ConsumerState<FormWizardField> createState() => _FormWizardFieldState();
}

class _FormWizardFieldState extends ConsumerState<FormWizardField> {
  late final TextEditingController _textController;

  FormWizardFieldModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: model.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant FormWizardField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.name != widget.model.name ||
        oldWidget.model.initialValue != widget.model.initialValue) {
      final newValue = widget.model.initialValue ?? '';
      if (_textController.text != newValue) {
        _textController.text = newValue;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(formStateProvider.notifier).updateFieldValue(model.name, value);
  }

  @override
  Widget build(BuildContext context) {
    final formValue = ref.watch(
      formStateProvider.select((state) => state.values[model.name]),
    );
    final errorText = ref.watch(
      formStateProvider.select((state) => state.errors[model.name]),
    );

    final newText = formValue?.toString() ?? '';
    if (_textController.text != newText) {
      _textController.value = _textController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    }

    if (model.type == FieldType.custom && model.customBuilder != null) {
      return model.customBuilder!(_textController, errorText, _onChanged);
    }

    if (model.type == FieldType.dropdown && model.options != null) {
      return DropdownButtonFormField<String>(
        initialValue:
            _textController.text.isNotEmpty ? _textController.text : null,
        items: [
          for (final option in model.options!)
            DropdownMenuItem<String>(value: option, child: Text(option)),
        ],
        onChanged: (value) {
          if (value == null) return;
          _textController.text = value;
          _onChanged(value);
        },
        decoration:
            model.decorationBuilder?.call(errorText, _textController) ??
            InputDecoration(
              labelText: model.label,
              errorText: errorText,
              border: const OutlineInputBorder(),
            ),
      );
    }

    if (model.type == FieldType.date) {
      return TextFormField(
        controller: _textController,
        readOnly: true,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked == null) return;

          final formatted =
              model.dateFormatter?.call(picked) ??
              DateFormat('yyyy-MM-dd').format(picked);
          _textController.text = formatted;
          _onChanged(formatted);
        },
        decoration:
            model.decorationBuilder?.call(errorText, _textController) ??
            InputDecoration(
              labelText: model.label,
              hintText: 'Select a date',
              errorText: errorText,
              border: const OutlineInputBorder(),
            ),
      );
    }

    return TextFormField(
      controller: _textController,
      obscureText: model.obscureText ?? model.type == FieldType.password,
      keyboardType: model.keyboardType ?? _keyboardTypeFor(model.type),
      decoration:
          model.decorationBuilder != null
              ? model.decorationBuilder!(errorText, _textController)
              : InputDecoration(
                labelText: model.label,
                hintText: model.hint,
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
      onChanged: _onChanged,
    );
  }

  TextInputType _keyboardTypeFor(FieldType type) {
    return switch (type) {
      FieldType.number => TextInputType.number,
      FieldType.email => TextInputType.emailAddress,
      _ => TextInputType.text,
    };
  }
}
