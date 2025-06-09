<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# 🧙‍♂️ form_wizard

[![pub package](https://img.shields.io/pub/v/form_wizard.svg)](https://pub.dev/packages/form_wizard)
[![GitHub Repo](https://img.shields.io/badge/GitHub-Open-blue)](https://github.com/Tanay610/form_wizard)

> The most customizable, lightweight, and powerful form builder for Flutter.

## ✨ Demo

### 🐧 Clean Form UI
![Form Preview](https://raw.githubusercontent.com/Tanay610/form_wizard/main/form_wizard/screenshots/gif-1.gif)

### 🌩️ Real-time Validation
![Validation](https://raw.githubusercontent.com/Tanay610/form_wizard/main/form_wizard/screenshots/gif-2.gif)

### 🪛 Custom Widget Validation
![Custom Widget](https://raw.githubusercontent.com/Tanay610/form_wizard/main/form_wizard/screenshots/gif-3.gif)


---

### ✨ Features

- ✅ Smart validation with reactive controller
- 🎨 Fully customizable fields with `decorationBuilder`
- 🔐 Built-in support for `Text`, `Email`, `Password`, `Dropdown`, and `DatePicker`
- 💡 Easy field setup using `FieldType`
- 🧩 Support for custom widgets via `customBuilder`
- ⚡ Built with `GetX` for lightweight performance

---

## 🧪 Usage

Here’s how to use `FormWizard` in your project:

### 🪄 Step-by-Step

1. **Initialize a controller** to manage form state.
2. **Wrap your fields** with `FormWizard` and pass the controller.
3. **Define fields** using `FormWizardField`.
4. **Provide validators** if needed.
5. **Handle submission** using `onSubmit`.

```dart

final formController = FormWizardController();

FormWizard(
  controller: formController,
  fields: [
    FormWizardFieldModel(
      name: 'email',
      label: 'Email',
      hint: 'Enter your email address',
      type: FieldType.email,
      validators: [
        Validators.required(),
        Validators.email(),
      ],
    ),
    FormWizardFieldModel(
      name: 'password',
      label: 'Password',
      type: FieldType.password,
      hint: 'Enter a strong password',
      validators: [
        Validators.required(),
        Validators.minLength(8),
      ],
    ),
    FormWizardFieldModel(
      name: 'dob',
      label: 'Date of Birth',
      type: FieldType.date,
    ),
    FormWizardFieldModel(
      name: 'gender',
      label: 'Gender',
      type: FieldType.dropdown,
      dropdownOptions: ['Male', 'Female', 'Other'],
    ),
  ],
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
)
```

---

## 🧱 Supported Field Types

| Field Type | Description                              |
| ---------- | ---------------------------------------- |
| `text`     | Standard text field                      |
| `email`    | Validates email format                   |
| `password` | With obsecure text                       |
| `number`   | Numeric input                            |
| `date`     | Date picker with formatting              |
| `dropdown` | Dropdown menu from a list of options     |
| `custom`   | Pass your own widget via `customBuilder` |

---

## 🎨 Custom Decoration

Use `decorationBuilder` to pass your own `InputDecoration`:

```dart
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
```

---

## 🛠️ Validators

Use the built-in `Validators` class:

```dart
validators: [   Validators.required(),   Validators.email(),   Validators.minLength(6), Validators.maxLength(6), Validators.number(),  Validators.regex() ]
```

Or define your own:

```dart
validators: [   (value) => value == 'magic' ? null : 'Only "magic" is accepted!', ]
```

---

## 💡 Custom Field Widget

```dart
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
```

---

## 🔗 API Reference

👉 form_wizard API Docs on pub.dev

---
## 🤝 Contributing

We welcome contributions from the community to make **FormWizard** even better, smarter, and more flexible!

Whether it's fixing bugs, adding new features, improving documentation, or just sharing ideas — every contribution counts.

### 🚀 How to Contribute

1. **Fork** the repository.
2. Create a new branch: `git checkout -b your-feature-name`
3. Make your changes and commit them with clear messages.
4. **Push** to your fork: `git push origin your-feature-name`
5. Open a **Pull Request** on the `main` branch.

### 🧠 Contribution Ideas

- Add more custom field types (e.g., phone number, image picker, multi-select).
- Improve accessibility (a11y) support.
- Create more built-in decorators or validators.
- Help write or translate documentation.
- Suggest enhancements or refactor logic.

### 📝 Guidelines

- Follow Flutter/Dart formatting: `dart format .`
- Keep your PR focused and well-scoped.
- Update tests and examples if needed.
- Be kind and respectful in code reviews.

---

Thanks for helping make `FormWizard` the smartest form solution for Flutter! ❤️

---

## 📃 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

> Crafted with ❤️ by [Tanay](https://github.com/Tanay610) & powered by Flutter + GetX.
