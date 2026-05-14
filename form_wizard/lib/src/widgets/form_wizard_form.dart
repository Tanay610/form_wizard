import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/form_wizard_controller.dart';
import '../field_presets.dart';
import '../models/form_wizard_field_array_model.dart';
import '../models/form_wizard_field_model.dart';
import '../providers/form_providers.dart';
import 'form_wizard_field.dart';

/// High-performance form builder powered by internal Riverpod selectors.
///
/// Consumers do not need to add Riverpod to their app or wrap their widget tree
/// with [ProviderScope]. Each [FormWizard] owns an internal provider scope.
class FormWizard extends StatelessWidget {
  final List<FormWizardFieldModel> fields;
  final List<FormWizardFieldArrayModel> fieldArrays;
  final FormWizardController controller;
  final void Function(Map<String, dynamic> values)? onSubmit;
  final Widget? submitButton;


  const FormWizard({
    super.key,
    required this.fields,
    this.fieldArrays = const <FormWizardFieldArrayModel>[],
    required this.controller,
    this.onSubmit,
    this.submitButton,
  });

  /// Email text field preset.
  static FormWizardFieldModel emailField({
    String name = 'email',
    String label = 'Email',
    String? hint,
    bool required = true,
  }) => FormWizardFieldPresets.emailField(
    name: name,
    label: label,
    hint: hint,
    required: required,
  );

  /// Phone text field preset.
  static FormWizardFieldModel phoneField({
    String name = 'phone',
    String label = 'Phone',
    String? hint,
    bool required = true,
  }) => FormWizardFieldPresets.phoneField(
    name: name,
    label: label,
    hint: hint,
    required: required,
  );

  /// Password field preset.
  static FormWizardFieldModel passwordField({
    String name = 'password',
    String label = 'Password',
    String? hint,
    bool required = true,
    int minLength = 8,
  }) => FormWizardFieldPresets.passwordField(
    name: name,
    label: label,
    hint: hint,
    required: required,
    minLength: minLength,
  );

  /// OTP field preset.
  static FormWizardFieldModel otpField({
    String name = 'otp',
    String label = 'OTP',
    int length = 6,
  }) =>
      FormWizardFieldPresets.otpField(name: name, label: label, length: length);

  /// Name field preset.
  static FormWizardFieldModel nameField({
    String name = 'name',
    String label = 'Full Name',
    String? hint,
    bool required = true,
  }) => FormWizardFieldPresets.nameField(
    name: name,
    label: label,
    hint: hint,
    required: required,
  );

  /// Street address field preset.
  static FormWizardFieldModel streetField({
    String name = 'street',
    String label = 'Street Address',
    String? hint,
    bool required = true,
  }) => FormWizardFieldPresets.streetField(
    name: name,
    label: label,
    hint: hint,
    required: required,
  );

  /// City field preset.
  static FormWizardFieldModel cityField({
    String name = 'city',
    String label = 'City',
    bool required = true,
  }) => FormWizardFieldPresets.cityField(
    name: name,
    label: label,
    required: required,
  );

  /// ZIP/postal code field preset.
  static FormWizardFieldModel zipField({
    String name = 'zip',
    String label = 'ZIP / Postal Code',
    bool required = true,
  }) => FormWizardFieldPresets.zipField(
    name: name,
    label: label,
    required: required,
  );

  /// Country dropdown preset.
  static FormWizardFieldModel countryDropdown({
    String name = 'country',
    String label = 'Country',
    List<String> countries = const <String>[
      'Australia',
      'Brazil',
      'Canada',
      'France',
      'Germany',
      'India',
      'Japan',
      'United Kingdom',
      'United States',
    ],
    bool required = true,
  }) => FormWizardFieldPresets.countryDropdown(
    name: name,
    label: label,
    countries: countries,
    required: required,
  );

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _FormWizardView(
        fields: fields,
        fieldArrays: fieldArrays,
        controller: controller,
        onSubmit: onSubmit,
        submitButton: submitButton,
      ),
    );
  }
}

class _FormWizardView extends ConsumerStatefulWidget {
  const _FormWizardView({
    required this.fields,
    required this.fieldArrays,
    required this.controller,
    required this.onSubmit,
    required this.submitButton,
  });

  final List<FormWizardFieldModel> fields;
  final List<FormWizardFieldArrayModel> fieldArrays;
  final FormWizardController controller;
  final void Function(Map<String, dynamic> values)? onSubmit;
  final Widget? submitButton;

  @override
  ConsumerState<_FormWizardView> createState() => _FormWizardState();
}

class _FormWizardState extends ConsumerState<_FormWizardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachController());
  }

  @override
  void didUpdateWidget(covariant _FormWizardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields ||
        oldWidget.fieldArrays != widget.fieldArrays ||
        oldWidget.controller != widget.controller) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attachController());
    }
  }

  void _attachController() {
    if (!mounted) return;
    widget.controller
      ..attach(ref.read(formStateProvider.notifier))
      ..configureFields(_configuredFields(), fieldArrays: widget.fieldArrays)
      ..sync(ref.read(formStateProvider));
  }

  List<FormWizardFieldModel> _configuredFields() {
    final state = ref.read(formStateProvider);
    return [
      ...widget.fields,
      for (final fieldArray in widget.fieldArrays)
        for (final itemId
            in state.fieldArrays[fieldArray.name] ??
                List<String>.generate(
                  fieldArray.initialItemCount,
                  (index) => 'pending_$index',
                ))
          ...fieldArray.fieldBuilder(
            FormWizardArrayItemContext(
              arrayName: fieldArray.name,
              itemId: itemId,
              index: state.fieldArrays[fieldArray.name]?.indexOf(itemId) ?? 0,
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(formStateProvider, (_, next) => widget.controller.sync(next));
    ref.listen(
      formStateProvider.select((state) => state.fieldArrays),
      (_, _) => WidgetsBinding.instance.addPostFrameCallback(
        (_) => _attachController(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormFieldsList(fields: widget.fields, controller: widget.controller),
        for (final fieldArray in widget.fieldArrays)
          _FormFieldArray(
            key: ValueKey<String>('array-${fieldArray.name}'),
            fieldArray: fieldArray,
            controller: widget.controller,
          ),
        const SizedBox(height: 16),
        widget.submitButton ??
            _SubmitButton(
              controller: widget.controller,
              onSubmit: widget.onSubmit,
            ),
      ],
    );
  }
}

class _FormFieldsList extends StatelessWidget {
  const _FormFieldsList({required this.fields, required this.controller});

  final List<FormWizardFieldModel> fields;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final field in fields)
          _FormField(
            key: ValueKey<String>(field.name),
            field: field,
            controller: controller,
          ),
      ],
    );
  }
}

class _FormField extends ConsumerWidget {
  const _FormField({super.key, required this.field, required this.controller});

  final FormWizardFieldModel field;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dependentValues = <String, dynamic>{
      for (final dependency in field.visibleWhenDependsOn)
        dependency: ref.watch(
          formStateProvider.select((state) => state.values[dependency]),
        ),
    };
    final valuesForPredicate = <String, dynamic>{
      ...ref.read(formStateProvider).values,
      ...dependentValues,
    };
    final isVisible =
        field.visibleWhen?.call(
          Map<String, dynamic>.unmodifiable(valuesForPredicate),
        ) ??
        true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(formStateProvider.notifier)
          .setFieldVisibility(field.name, isVisible);
    });

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FormWizardField(model: field, controller: controller),
    );
  }
}

class _FormFieldArray extends ConsumerWidget {
  const _FormFieldArray({
    super.key,
    required this.fieldArray,
    required this.controller,
  });

  final FormWizardFieldArrayModel fieldArray;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemIds = ref.watch(
      formStateProvider.select(
        (state) => state.fieldArrays[fieldArray.name] ?? const <String>[],
      ),
    );
    final canAdd =
        fieldArray.maxItems == null || itemIds.length < fieldArray.maxItems!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fieldArray.label != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              fieldArray.label!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        for (var index = 0; index < itemIds.length; index++) ...[
          _FormFieldArrayItem(
            key: ValueKey<String>('${fieldArray.name}-${itemIds[index]}'),
            fieldArray: fieldArray,
            itemId: itemIds[index],
            index: index,
            itemCount: itemIds.length,
            controller: controller,
          ),
          SizedBox(height: fieldArray.itemSpacing),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child:
              fieldArray.addButtonBuilder?.call(
                context,
                canAdd
                    ? () => ref
                        .read(formStateProvider.notifier)
                        .addFieldArrayItem(fieldArray.name)
                    : () {},
              ) ??
              TextButton.icon(
                onPressed:
                    canAdd
                        ? () => ref
                            .read(formStateProvider.notifier)
                            .addFieldArrayItem(fieldArray.name)
                        : null,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
        ),
      ],
    );
  }
}

class _FormFieldArrayItem extends StatelessWidget {
  const _FormFieldArrayItem({
    super.key,
    required this.fieldArray,
    required this.itemId,
    required this.index,
    required this.itemCount,
    required this.controller,
  });

  final FormWizardFieldArrayModel fieldArray;
  final String itemId;
  final int index;
  final int itemCount;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context) {
    final itemContext = FormWizardArrayItemContext(
      arrayName: fieldArray.name,
      itemId: itemId,
      index: index,
    );
    final fields = fieldArray.fieldBuilder(itemContext);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ArrayIconButton(
                  icon: Icons.keyboard_arrow_up,
                  tooltip: 'Move up',
                  isEnabled: index > 0,
                  customBuilder: fieldArray.moveUpButtonBuilder,
                  onPressed:
                      () => controller.reorderFieldArrayItem(
                        fieldArray.name,
                        index,
                        index - 1,
                      ),
                ),
                _ArrayIconButton(
                  icon: Icons.keyboard_arrow_down,
                  tooltip: 'Move down',
                  isEnabled: index < itemCount - 1,
                  customBuilder: fieldArray.moveDownButtonBuilder,
                  onPressed:
                      () => controller.reorderFieldArrayItem(
                        fieldArray.name,
                        index,
                        index + 1,
                      ),
                ),
                _ArrayIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Remove',
                  isEnabled: itemCount > fieldArray.minItems,
                  customBuilder: fieldArray.removeButtonBuilder,
                  onPressed:
                      () => controller.removeFieldArrayItem(
                        fieldArray.name,
                        itemId,
                      ),
                ),
              ],
            ),
            for (final field in fields)
              _FormField(
                key: ValueKey<String>(field.name),
                field: field,
                controller: controller,
              ),
          ],
        ),
      ),
    );
  }
}

class _ArrayIconButton extends StatelessWidget {
  const _ArrayIconButton({
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    required this.onPressed,
    this.customBuilder,
  });

  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback onPressed;
  final FormWizardArrayControlBuilder? customBuilder;

  @override
  Widget build(BuildContext context) {
    if (customBuilder != null) {
      return customBuilder!(context, isEnabled ? onPressed : () {});
    }

    return IconButton(
      onPressed: isEnabled ? onPressed : null,
      tooltip: tooltip,
      icon: Icon(icon),
    );
  }
}

class _SubmitButton extends ConsumerWidget {
  const _SubmitButton({required this.controller, 
  required this.onSubmit
  });

  final FormWizardController controller;
  final void Function(Map<String, dynamic> values)? onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFormValid = ref.watch(formValidityProvider);

    return ElevatedButton(
      onPressed: isFormValid ? () => controller.submitForm(onSubmit) : null,
      child:  Text('Submit'),
    );
  }
}
