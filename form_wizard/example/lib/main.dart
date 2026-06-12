import 'package:flutter/material.dart';
import 'package:form_wizard/form_wizard.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormWizard Demo',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const DemoShell(),
    );
  }
}

class DemoShell extends StatelessWidget {
  const DemoShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FormWizard Demo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Form'),
              Tab(text: 'Stepper'),
              Tab(text: 'Templates'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ExampleFormPage(),
            FormStepperWidget(),
            TemplatesShowcase(),
          ],
        ),
      ),
    );
  }
}

class ExampleFormPage extends StatefulWidget {
  const ExampleFormPage({super.key});

  @override
  State<ExampleFormPage> createState() => _ExampleFormPageState();
}

class _ExampleFormPageState extends State<ExampleFormPage> {
  final FormWizardController _controller = FormWizardController();

  final List<FormWizardFieldModel> _fields = [
    FormWizardFieldPresets.nameField(label: 'Full Name', required: true),

    FormWizardFieldPresets.emailField(label: 'Email Address', required: true),
    FormWizardFieldModel(
      name: 'username',
      label: 'Username',
      type: FieldType.text,
      hint: 'Try "taken"',
      validators: [Validators.required()],
      asyncValidationDebounce: const Duration(milliseconds: 250),
      asyncValidators: [
        (value, context) async {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          return value == 'taken' ? 'Username is already taken' : null;
        },
      ],
    ),
    FormWizardFieldPresets.passwordField(label: 'Password', required: true),
    FormWizardFieldModel(
      name: 'confirm_password',
      label: 'Confirm Password',
      type: FieldType.password,
      validators: [Validators.required()],
      contextValidators: [
        Validators.matchesField('password', message: 'Passwords do not match'),
      ],
      validationDependsOn: const ['password'],
    ),
    FormWizardFieldPresets.countryDropdown(
      label: 'Country',
      required: true,
      countries: const [
        'USA',
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
    ),
    FormWizardFieldModel(
      name: 'state',
      label: 'State',
      type: FieldType.text,
      hint: 'Required only for USA',
      validators: [Validators.required()],
      visibleWhenDependsOn: const ['country'],
      visibleWhen: (values) => values['country'] == 'USA',
      decorationBuilder:
          (errorText, controller) => InputDecoration(
            prefixIcon: const Icon(Icons.map),
            labelText: 'State',
            errorText: errorText,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
    ),

    FormWizardFieldModel(
      name: 'dob',
      label: 'Date of Birth',
      type: FieldType.date,
      validators: [Validators.required()],
      dateFormatter: (date) => DateFormat('dd MMM yyyy').format(date),
      decorationBuilder: (errorText, controller) {
        return InputDecoration(
          prefixIcon: const Icon(Icons.calendar_month),
          labelText: 'Date of Birth',
          errorText: errorText,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        );
      },
    ),

    FormWizardFieldModel(
      name: 'number',
      label: 'Number',
      type: FieldType.number,
      validators: [Validators.required(), Validators.number()],
      decorationBuilder:
          (errorText, controller) => InputDecoration(
            prefixIcon: const Icon(Icons.phone),
            labelText: 'Number',
            errorText: errorText,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
    ),
    FormWizardFieldModel(
      name: 'custom_slider',
      label: 'Custom Field',
      type: FieldType.custom,
      customBuilder: (controller, errorText, onChanged) {
        double value = double.tryParse(controller.text) ?? 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select value"),
            Slider(
              min: 0,
              max: 100,
              divisions: 100,
              value: value,
              onChanged: (val) {
                controller.text = val.toString();
                onChanged(val.toString());
              },
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4),
                child: Text(
                  errorText,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
      validators: [
        (val) {
          final v = double.tryParse(val ?? '');
          if (v == null || v < 20) return "Value must be at least 20";
          return null;
        },
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: FormWizard(
          fields: _fields,
          fieldArrays: [
            FormWizardFieldArrayModel(
              name: 'phones',
              label: 'Phone Numbers',
              initialItemCount: 1,
              minItems: 1,
              maxItems: 4,
              fieldBuilder: (item) {
                return [
                  FormWizardFieldModel(
                    name: item.fieldName('number'),
                    label: 'Phone ${item.index + 1}',
                    type: FieldType.number,
                    validators: [Validators.required(), Validators.number()],
                    decorationBuilder:
                        (errorText, controller) => InputDecoration(
                          prefixIcon: const Icon(Icons.phone),
                          labelText: 'Phone ${item.index + 1}',
                          errorText: errorText,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                  ),
                ];
              },
            ),
          ],
          controller: _controller,
          onSubmit: (values) {
            showDialog(
              context: context,
              builder:
                  (_) => AlertDialog(
                    title: const Text('Form Submitted'),
                    content: Text(values.toString()),
                  ),
            );
          },
        ),
      ),
    );
  }
}

class LoginFormTemplate extends StatelessWidget {
  const LoginFormTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginForm(
      onLogin: (name, password) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Login Submitted'),
                content: Text('Identity: $name\nPassword: $password'),
              ),
        );
      },
    );
  }
}

class FormStepperWidget extends StatelessWidget {
  const FormStepperWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormWizardStepper(
        steps: [
          FormWizardStep(
            title: 'Personal',
            fields: [FormWizard.nameField(name: 'name')],
          ),
          FormWizardStep(
            title: 'Contact',
            fields: [FormWizard.emailField(name: 'email')],
          ),
          FormWizardStep(
            title: 'Address',
            fields: [
              FormWizard.streetField(),
              FormWizard.cityField(),
              FormWizard.zipField(),
            ],
          ),
        ],
        onStepChanged: (_) {},
        onFinish: (values) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text('Stepper Submitted'),
                  content: Text(values.toString()),
                ),
          );
        },
        stepBuilder: (context, stepper) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (stepper.currentStep + 1) / stepper.steps.length,
              ),
              const SizedBox(height: 16),
              Text(
                stepper.steps[stepper.currentStep].title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              stepper.fields,
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: stepper.onBack,
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey<String>('next-step'),
                    onPressed: stepper.onNext,
                    child: Text(
                      stepper.currentStep == stepper.steps.length - 1
                          ? 'Finish'
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class TemplatesShowcase extends StatelessWidget {
  const TemplatesShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TemplatePanel(
          title: 'LoginForm',
          child: LoginForm(
            rememberMe: true,
            forgotPasswordLink: () => _show(context, 'Forgot password tapped'),
            onLogin:
                (identity, password) =>
                    _show(context, 'Login: $identity / $password'),
          ),
        ),
        _TemplatePanel(
          title: 'SignupForm',
          child: SignupForm(
            requireTermsAcceptance: true,
            onSignup:
                (name, identity, password) =>
                    _show(context, 'Signup: $name / $identity'),
          ),
        ),
        _TemplatePanel(
          title: 'OTPVerificationForm',
          child: OTPVerificationForm(
            otpLength: 4,
            resendCooldownSeconds: 10,
            onVerify: (otp) => _show(context, 'OTP: $otp'),
            onResend: () => _show(context, 'OTP resent'),
          ),
        ),
        _TemplatePanel(
          title: 'AddressForm',
          child: AddressForm(
            onSubmit: (address) => _show(context, address.toString()),
          ),
        ),
        _TemplatePanel(
          title: 'PaymentForm',
          child: PaymentForm(
            submitLabel: 'Pay Now',
            onSubmit: (payment) => _show(context, payment.toString()),
          ),
        ),
      ],
    );
  }

  static void _show(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Template Submitted'),
            content: Text(message),
          ),
    );
  }
}

class _TemplatePanel extends StatelessWidget {
  const _TemplatePanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title),
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
      ],
    );
  }
}
