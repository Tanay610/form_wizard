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
class FormWizardStepper extends StatefulWidget {
  /// Creates a multi-step form.
  const FormWizardStepper({
    super.key,
    required this.steps,
    required this.onFinish,
    this.controller,
    this.onStepChanged,
    this.stepBuilder,
    this.nextLabel = 'Next',
    this.backLabel = 'Back',
    this.finishLabel = 'Finish',
  }) : assert(steps.length > 0);

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
  State<FormWizardStepper> createState() => _FormWizardStepperState();
}

class _FormWizardStepperState extends State<FormWizardStepper>
    with AutomaticKeepAliveClientMixin<FormWizardStepper> {
  late FormWizardController _controller;
  late bool _ownsController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FormWizardController();
  }

  @override
  void didUpdateWidget(covariant FormWizardStepper oldWidget) {
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
    super.build(context);
    return ProviderScope(
      child: _FormWizardStepperView(
        steps: widget.steps,
        onFinish: widget.onFinish,
        controller: _controller,
        onStepChanged: widget.onStepChanged,
        stepBuilder: widget.stepBuilder,
        nextLabel: widget.nextLabel,
        backLabel: widget.backLabel,
        finishLabel: widget.finishLabel,
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
  int _currentStep = 0;

  List<FormWizardFieldModel> get _allFields => [
    for (final step in widget.steps) ...step.fields,
  ];

  List<FormWizardFieldModel> get _currentFields =>
      widget.steps[_currentStep].fields;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachController());
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
      ..configureFields(_allFields)
      ..sync(ref.read(formStateProvider));
  }

  bool _watchStepValidity(WidgetRef ref, List<FormWizardFieldModel> fields) {
    final values = <String, dynamic>{};

    for (final field in fields) {
      values[field.name] = ref.watch(
        formStateProvider.select((state) => state.values[field.name]),
      );
      for (final dependency in field.visibleWhenDependsOn) {
        values[dependency] = ref.watch(
          formStateProvider.select((state) => state.values[dependency]),
        );
      }
    }

    for (final field in fields) {
      final isVisible = field.visibleWhen?.call(values) ?? true;
      if (!isVisible) continue;

      final value = values[field.name]?.toString();
      for (final validator in field.validators ?? const []) {
        if (validator(value) != null) return false;
      }
    }

    return true;
  }

  void _setStep(int nextStep) {
    if (nextStep < 0 || nextStep >= widget.steps.length) return;
    setState(() => _currentStep = nextStep);
    widget.onStepChanged?.call(nextStep);
  }

  void _next() {
    final notifier = ref.read(formStateProvider.notifier);
    var isValid = true;

    for (final field in _currentFields) {
      isValid = notifier.validateField(field.name) && isValid;
    }

    if (!isValid) return;

    if (_currentStep == widget.steps.length - 1) {
      widget.onFinish(widget.controller.formData);
    } else {
      _setStep(_currentStep + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(formStateProvider, (_, next) => widget.controller.sync(next));

    final fieldsWidget = _StepperFieldsList(
      fields: _currentFields,
      controller: widget.controller,
    );

    if (widget.stepBuilder != null) {
      final isValid = _watchStepValidity(ref, _currentFields);
      return widget.stepBuilder!(
        context,
        FormWizardStepperContext(
          currentStep: _currentStep,
          steps: widget.steps,
          isCurrentStepValid: isValid,
          onNext: isValid ? _next : null,
          onBack: _currentStep == 0 ? null : () => _setStep(_currentStep - 1),
          onStepTapped: _setStep,
          fields: fieldsWidget,
        ),
      );
    }

    return Stepper(
      currentStep: _currentStep,
      onStepTapped: _setStep,
      onStepContinue: _next,
      onStepCancel: _currentStep == 0 ? null : () => _setStep(_currentStep - 1),
      controlsBuilder: (context, details) {
        return _StepperControls(
          fields: _currentFields,
          watchStepValidity: _watchStepValidity,
          isLastStep: _currentStep == widget.steps.length - 1,
          isFirstStep: _currentStep == 0,
          nextLabel: widget.nextLabel,
          backLabel: widget.backLabel,
          finishLabel: widget.finishLabel,
          onNext: _next,
          onBack: () => _setStep(_currentStep - 1),
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
            isActive: index <= _currentStep,
            state:
                index < _currentStep
                    ? StepState.complete
                    : index == _currentStep
                    ? StepState.editing
                    : StepState.indexed,
            content:
                index == _currentStep ? fieldsWidget : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _StepperControls extends ConsumerWidget {
  const _StepperControls({
    required this.fields,
    required this.watchStepValidity,
    required this.isLastStep,
    required this.isFirstStep,
    required this.nextLabel,
    required this.backLabel,
    required this.finishLabel,
    required this.onNext,
    required this.onBack,
  });

  final List<FormWizardFieldModel> fields;
  final bool Function(WidgetRef ref, List<FormWizardFieldModel> fields)
  watchStepValidity;
  final bool isLastStep;
  final bool isFirstStep;
  final String nextLabel;
  final String backLabel;
  final String finishLabel;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isValid = watchStepValidity(ref, fields);

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
    final isVisible =
        field.visibleWhen?.call({
          ...ref.read(formStateProvider).values,
          ...dependentValues,
        }) ??
        true;

    if (!isVisible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FormWizardField(model: field, controller: controller),
    );
  }
}
