import 'package:flutter/material.dart';
import 'package:form_wizard/form_wizard_main.dart';
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
      home: const ExampleFormPage(),
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
    FormWizardFieldModel(
      name: 'username',
      label: 'Username',
      type: FieldType.text,
      validators: [
        Validators.required(),
        Validators.regex(
          RegExp(r'^[a-zA-Z0-9_]+$'),
          message: 'Only letters, numbers and underscores allowed',
        ),
      ],
      decorationBuilder:
          (errorText, controller) => InputDecoration(
            prefixIcon: const Icon(Icons.person),
            suffixIcon: Builder(
              builder: (context) {
                if (controller.text.isEmpty) {
                  return SizedBox();
                }
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                  },
                );
              },
            ),
            labelText: 'Username',
            hintText: 'e.g. tanay_dev_99',
            helperText: 'Only letters, numbers, and underscore allowed',
            errorText: errorText,
            errorStyle: TextStyle(color: Colors.red[800]),
            // filled: true,
            // fillColor: Colors.grey[200],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
    ),

    FormWizardFieldModel(
      name: 'email',
      label: 'Email Address',
      type: FieldType.email,
      validators: [Validators.required(), Validators.email()],
      decorationBuilder:
          (errorText, controller) => InputDecoration(
            prefixIcon: const Icon(Icons.email),
            labelText: 'Email',
            errorText: errorText,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
    ),
    FormWizardFieldModel(
      name: 'password',
      label: 'Password',
      type: FieldType.custom,
      validators: [Validators.required(), Validators.minLength(6)],
      customBuilder: (controller, errorText, onChanged) {
        return _PasswordFieldWithToggle(
          controller: controller,
          errorText: errorText,
          onChanged: onChanged,
        );
      },
    ),
    FormWizardFieldModel(
      name: 'country',
      label: 'Country',
      type: FieldType.dropdown,
      options: ['India', 'USA', 'Canada'],
      validators: [Validators.required()],
      decorationBuilder:
          (errorText, controller) => InputDecoration(
            prefixIcon: const Icon(Icons.flag),
            labelText: 'Country',
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
      validators: [
        Validators.required(),
        Validators.number()
      ],
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FormWizard Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: FormWizard(
            fields: _fields,
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
      ),
    );
  }
}

class _PasswordFieldWithToggle extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String) onChanged;

  const _PasswordFieldWithToggle({
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  @override
  State<_PasswordFieldWithToggle> createState() =>
      _PasswordFieldWithToggleState();
}

class _PasswordFieldWithToggleState extends State<_PasswordFieldWithToggle> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
