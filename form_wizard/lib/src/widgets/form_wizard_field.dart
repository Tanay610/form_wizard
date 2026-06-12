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
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  final GlobalKey _fieldKey = GlobalKey();

  FormWizardFieldModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: model.initialValue?.toString() ?? '',
    );
    _focusNode = FocusNode();
    _ownsFocusNode = true;
    _focusNode.addListener(_handleFocusChanged);
    widget.controller.registerField(model.name, _focusNode, _fieldKey);
  }

  @override
  void didUpdateWidget(covariant FormWizardField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.name != widget.model.name ||
        oldWidget.model.initialValue != widget.model.initialValue) {
      final newValue = widget.model.initialValue?.toString() ?? '';
      if (_textController.text != newValue) {
        _textController.text = newValue;
      }
    }

    if (oldWidget.model.name != widget.model.name) {
      widget.controller.unregisterField(oldWidget.model.name, _focusNode);
      widget.controller.registerField(widget.model.name, _focusNode, _fieldKey);
    }
  }

  @override
  void dispose() {
    widget.controller.unregisterField(model.name, _focusNode);
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _textController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(formStateProvider.notifier).updateFieldValue(model.name, value);
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      ref.read(formStateProvider.notifier).markFieldTouched(model.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formValue = ref.watch(
      formStateProvider.select((state) => state.values[model.name]),
    );
    final errorText = ref.watch(
      formStateProvider.select((state) => state.errors[model.name]),
    );
    final isValidating = ref.watch(fieldValidatingProvider(model.name));

    final newText = formValue?.toString() ?? '';
    if (_textController.text != newText) {
      _textController.value = _textController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    }

    if (model.type == FieldType.custom && model.customBuilder != null) {
      return KeyedSubtree(
        key: _fieldKey,
        child: model.customBuilder!(_textController, errorText, _onChanged),
      );
    }

    if (model.type == FieldType.dropdown && model.options != null) {
      return KeyedSubtree(
        key: _fieldKey,
        child: DropdownButtonFormField<String>(
          key: ValueKey<String>('${model.name}-${_textController.text}'),
          focusNode: _focusNode,
          initialValue:
              _textController.text.isNotEmpty ? _textController.text : null,
          items: [
            for (final option in model.options!)
              DropdownMenuItem<String>(value: option, child: Text(option)),
          ],
          onChanged:
              model.enabled
                  ? (value) {
                    if (value == null) return;
                    _textController.text = value;
                    _onChanged(value);
                  }
                  : null,
          decoration:
              model.decorationBuilder?.call(errorText, _textController) ??
              _decoration(errorText, isValidating),
        ),
      );
    }

    if (model.type == FieldType.date) {
      return KeyedSubtree(
        key: _fieldKey,
        child: TextFormField(
          controller: _textController,
          focusNode: _focusNode,
          enabled: model.enabled,
          readOnly: true,
          onTap: () async {
            if (!model.enabled) return;
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
              _decoration(errorText, isValidating, hintText: 'Select a date'),
        ),
      );
    }

    return KeyedSubtree(
      key: _fieldKey,
      child: TextFormField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: model.enabled,
        readOnly: model.readOnly,
        obscureText: model.obscureText ?? model.type == FieldType.password,
        keyboardType: model.keyboardType ?? _keyboardTypeFor(model.type),
        textInputAction: model.textInputAction,
        inputFormatters: model.inputFormatters,
        autofillHints: model.autofillHints,
        maxLength: model.maxLength,
        maxLines: model.obscureText == true ? 1 : model.maxLines,
        minLines: model.minLines,
        textCapitalization: model.textCapitalization,
        decoration:
            model.decorationBuilder != null
                ? model.decorationBuilder!(errorText, _textController)
                : _decoration(errorText, isValidating),
        onChanged: _onChanged,
        onFieldSubmitted: model.onSubmitted,
      ),
    );
  }

  InputDecoration _decoration(
    String? errorText,
    bool isValidating, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: model.label,
      hintText: hintText ?? model.hint,
      errorText: errorText,
      border: const OutlineInputBorder(),
      suffixIcon:
          isValidating
              ? const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
              : null,
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
