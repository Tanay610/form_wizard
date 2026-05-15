import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/form_wizard_controller.dart';
import '../../models/form_wizard_field_model.dart';
import '../../providers/form_providers.dart';
import '../form_wizard_field.dart';

/// Defines one step in a [FormWizardStepper].
class FormWizardStep {
  /// Creates a step with a title and fields.
  const FormWizardStep({
    required this.title,
    required this.fields,
    this.subtitle,
  });

  /// Step title shown by the default Material stepper.
  final String title;

  /// Optional subtitle shown by the default Material stepper.
  final String? subtitle;

  /// Fields rendered while this step is active.
  final List<FormWizardFieldModel> fields;
}

/// Context passed to [FormWizardStepperBuilder].
class FormWizardStepperContext {
  /// Creates immutable stepper context.
  const FormWizardStepperContext({
    required this.currentStep,
    required this.steps,
    required this.isCurrentStepValid,
    required this.onNext,
    required this.onBack,
    required this.onStepTapped,
    required this.fields,
  });

  /// Current step index.
  final int currentStep;

  /// All steps.
  final List<FormWizardStep> steps;

  /// Whether the active step can move forward.
  final bool isCurrentStepValid;

  /// Advances or finishes.
  final VoidCallback? onNext;

  /// Goes back one step.
  final VoidCallback? onBack;

  /// Jumps to a step.
  final ValueChanged<int> onStepTapped;

  /// Active step fields. Previous and next step fields are not in the tree.
  final Widget fields;
}

/// Builder for custom stepper chrome.
typedef FormWizardStepperBuilder =
    Widget Function(BuildContext context, FormWizardStepperContext stepper);

/// Multi-step form wizard with internal ProviderScope and persistent state.
class FormWizardStepper extends StatelessWidget {
  /// Creates a multi-step form.
  FormWizardStepper({
    super.key,
    required this.steps,
    required this.onFinish,
    this.controller,
    this.onStepChanged,
    this.stepBuilder,
    this.nextLabel = 'Next',
    this.backLabel = 'Back',
    this.finishLabel = 'Finish',
  }) : assert(steps.isNotEmpty);

  /// Steps in the wizard.
  final List<FormWizardStep> steps;

  /// Called after the final step validates.
  final void Function(Map<String, dynamic> values) onFinish;

  /// Optional external controller.
  final FormWizardController? controller;

  /// Called whenever the current step changes.
  final ValueChanged<int>? onStepChanged;

  /// Optional custom stepper builder.
  final FormWizardStepperBuilder? stepBuilder;

  /// Default next button label.
  final String nextLabel;

  /// Default back button label.
  final String backLabel;

  /// Default final button label.
  final String finishLabel;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _FormWizardStepperView(
        steps: steps,
        onFinish: onFinish,
        controller: controller ?? FormWizardController(),
        onStepChanged: onStepChanged,
        stepBuilder: stepBuilder,
        nextLabel: nextLabel,
        backLabel: backLabel,
        finishLabel: finishLabel,
      ),
    );
  }
}

class _FormWizardStepperView extends ConsumerStatefulWidget {
  const _FormWizardStepperView({
    required this.steps,
    required this.onFinish,
    required this.controller,
    required this.onStepChanged,
    required this.stepBuilder,
    required this.nextLabel,
    required this.backLabel,
    required this.finishLabel,
  });

  final List<FormWizardStep> steps;
  final void Function(Map<String, dynamic> values) onFinish;
  final FormWizardController controller;
  final ValueChanged<int>? onStepChanged;
  final FormWizardStepperBuilder? stepBuilder;
  final String nextLabel;
  final String backLabel;
  final String finishLabel;

  @override
  ConsumerState<_FormWizardStepperView> createState() =>
      _FormWizardStepperViewState();
}

class _FormWizardStepperViewState
    extends ConsumerState<_FormWizardStepperView> {
  late final ValueNotifier<int> _currentStepNotifier;
  late final List<String> _allFieldNames;
  late final List<List<String>> _stepFieldNames;



  @override
  void initState() {
    super.initState();
    _currentStepNotifier = ValueNotifier(0);
    _stepFieldNames = widget.steps.map((step) {
      return step.fields.map((f) => f.name).toList();
    }).toList();
    _allFieldNames = _stepFieldNames.expand((e) => e).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachController());
  }


  @override
  void dispose() {
    _currentStepNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _FormWizardStepperView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps != widget.steps ||
        oldWidget.controller != widget.controller) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attachController());
    }
  }

  void _attachController() {
     if (!mounted) return;
    widget.controller
      ..attach(ref.read(formStateProvider.notifier))
      ..configureFields(_allFieldNames.map((name) {
        // Find the actual field model for each name
        for (final step in widget.steps) {
          for (final field in step.fields) {
            if (field.name == name) return field;
          }
        }
        throw Exception('Field $name not found');
      }).toList())
      ..sync(ref.read(formStateProvider));
  }

  /// Watches validity of current step with fine-grained selectivity
  bool _isCurrentStepValid(int currentStep) {
    final stepFields = _stepFieldNames[currentStep];
    if (stepFields.isEmpty) return true;

    // Watch all field values and errors in this step
    final values = ref.watch(formStateProvider.select((state) {
      final result = <String, dynamic>{};
      for (final name in stepFields) {
        result[name] = state.values[name];
      }
      return result;
    }));

    final errors = ref.watch(formStateProvider.select((state) {
      final result = <String, String?>{};
      for (final name in stepFields) {
        final error = state.errors[name];
        if (error != null) result[name] = error;
      }
      return result;
    }));

    // Check each field for validation
    for (final name in stepFields) {
      // Has error?
      if (errors[name] != null && errors[name]!.isNotEmpty) return false;
      // Required but empty?
      final field = _findFieldByName(name);
      if (field != null) {

        final value = values[name];
        if (value == null || value.toString().isEmpty) return false;
      }
    }
    return true;
  }

  FormWizardFieldModel? _findFieldByName(String name) {
    for (final step in widget.steps) {
      for (final field in step.fields) {
        if (field.name == name) return field;
      }
    }
    return null;
  }

  
  void _setStep(int nextStep) {
    if (nextStep < 0 || nextStep >= widget.steps.length) return;
    _currentStepNotifier.value = nextStep;
    widget.onStepChanged?.call(nextStep);
  }


 
  void _next() {
    final notifier = ref.read(formStateProvider.notifier);
    final currentStep = _currentStepNotifier.value;
    final stepFields = _stepFieldNames[currentStep];

    // Validate all fields in current step
    var isValid = true;
    for (final fieldName in stepFields) {
      final validated = notifier.validateField(fieldName);
      if (!validated) isValid = false;
    }

    if (!isValid) return;

    if (currentStep == widget.steps.length - 1) {
      widget.onFinish(widget.controller.formData);
    } else {
      _setStep(currentStep + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
     // Sync controller on form changes
    ref.listen(formStateProvider, (_, next) => widget.controller.sync(next));
    return ValueListenableBuilder(
      valueListenable: _currentStepNotifier,
      builder: (context, currentStep, _) {
                final currentFields = widget.steps[currentStep].fields;
        final isCurrentStepValid = _isCurrentStepValid(currentStep);
        final isLastStep = currentStep == widget.steps.length - 1;
        final isFirstStep = currentStep == 0;

          final fieldsWidget = _StepperFieldsList(
          fields: currentFields,
          controller: widget.controller,
        );

           // ✅ SUPPORT CUSTOM STEP BUILDER
        if (widget.stepBuilder != null) {
          final stepperContext = FormWizardStepperContext(
            currentStep: currentStep,
            steps: widget.steps,
            isCurrentStepValid: isCurrentStepValid,
            onNext: isCurrentStepValid ? _next : null,
            onBack: isFirstStep ? null : () => _setStep(currentStep - 1),
            onStepTapped: _setStep,
            fields: fieldsWidget,
          );
          return widget.stepBuilder!(context, stepperContext);
        }

        return Stepper(
          currentStep: currentStep,
          onStepTapped: _setStep,
          onStepContinue: isCurrentStepValid ? _next : null,
          onStepCancel: isFirstStep ? null : () => _setStep(currentStep - 1),
          controlsBuilder: (context, details) {
            return _StepperControls(
              isValid: isCurrentStepValid,
              isLastStep:  isLastStep,
              isFirstStep: isFirstStep,
              nextLabel: widget.nextLabel,
              backLabel: widget.backLabel,
              finishLabel: widget.finishLabel,
              onNext: _next,
              onBack: () => _setStep(currentStep - 1),
            );
          },
          steps: [
            for (var index = 0; index < widget.steps.length; index++)
              Step(
                title: Text(widget.steps[index].title),
                subtitle:
                    widget.steps[index].subtitle == null
                        ? null
                        : Text(widget.steps[index].subtitle!),
                isActive: index <= currentStep,
                state:
                    index < currentStep
                        ? StepState.complete
                        : index ==currentStep
                        ? StepState.editing
                        : StepState.indexed,
                content: index == currentStep ? fieldsWidget : const SizedBox.shrink(),
              ),
          ],
        );
      }
    );
  }
}

class _StepperControls extends ConsumerWidget {
  const _StepperControls({
    required this.isValid,
    required this.isLastStep,
    required this.isFirstStep,
    required this.nextLabel,
    required this.backLabel,
    required this.finishLabel,
    required this.onNext,
    required this.onBack,
  });

  final bool isValid;
  final bool isLastStep;
  final bool isFirstStep;
  final String nextLabel;
  final String backLabel;
  final String finishLabel;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          FilledButton(
            key: const ValueKey<String>('form_wizard_stepper_primary_button'),
            onPressed: isValid ? onNext : null,
            child: Text(isLastStep ? finishLabel : nextLabel),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isFirstStep ? null : onBack,
            child: Text(backLabel),
          ),
        ],
      ),
    );
  }
}

class _StepperFieldsList extends StatelessWidget {
  const _StepperFieldsList({required this.fields, required this.controller});

  final List<FormWizardFieldModel> fields;
  final FormWizardController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final field in fields)
          _StepperField(
            key: ValueKey<String>(field.name),
            field: field,
            controller: controller,
          ),
      ],
    );
  }
}

class _StepperField extends ConsumerWidget {
  const _StepperField({
    super.key,
    required this.field,
    required this.controller,
  });

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

    if (!isVisible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FormWizardField(model: field, controller: controller),
    );
  }
}
