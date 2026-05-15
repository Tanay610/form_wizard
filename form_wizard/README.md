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

# form_wizard <span style="font-size: 3rem;">🧙‍♂️</span>

[![pub package](https://img.shields.io/pub/v/form_wizard.svg)](https://pub.dev/packages/form_wizard)
[![GitHub Repo](https://img.shields.io/badge/GitHub-Open-blue)](https://github.com/Tanay610/form_wizard)

> The most performant, customizable, lightweight, and powerful form builder for Flutter.

## ✨ Demo

### 🐧 Clean Form UI
![Form Preview](https://raw.githubusercontent.com/Tanay610/form_wizard/main/form_wizard/screenshots/gif-1.gif)

### 🌩️ Real-time Validation
![Validation](https://raw.githubusercontent.com/Tanay610/form_wizard/main/form_wizard/screenshots/gif-2.gif)

### 🪛 Custom Widget Validation
![Custom Widget](https://raw.githubusercontent.com/Tanay610/form_wizard/main/form_wizard/screenshots/gif-3.gif)


---

## 🎉 What's New in v0.1.0

| Feature | Description |
|---------|-------------|
| **Performance** | Only the field being edited rebuilds — **up to 90% fewer rebuilds**|
| **FormWizardStepper** | Multi‑step forms with step isolation — inactive steps are disposed |
| **Conditional Visibility** | Show/hide fields reactively with `visibleWhen` + `visibleWhenDependsOn` |
| **Dynamic Field Arrays** | Add, remove, and reorder repeating field groups (phone numbers, addresses, etc.) |
| **Built‑in Templates** | LoginForm, SignupForm, OTPForm, AddressForm, PaymentForm — ready to use |
| **Field Presets** | `emailField()`, `phoneField()`, `passwordField()`, `otpField()`, `nameField()`, etc. |


---

## 🚀 Features

### Core
- Smart validation with reactive `FormWizardController`
- Fine-grained state updates using `formStateProvider.select(...)`
- `ValueListenable` access to `isFormValid`, `formValues`, and field errors

### Fields
- Built‑in: text, email, password, number, dropdown, date
- Custom widgets via `customBuilder`
- Fully customizable with `decorationBuilder`

### Advanced
- Conditional visibility for dependent fields
- Dynamic field arrays for repeatable groups
- Multi‑step forms with `FormWizardStepper`

### Templates (new)
- LoginForm, SignupForm, OTPForm, AddressForm, PaymentForm
- Field presets for common use cases


---

## ⚡ Performance

Only the field being edited rebuilds. The rest of the form stays static.

`form_wizard` uses Riverpod 3 internally to avoid whole-form rebuilds. You do not
need to install, import, or initialize Riverpod in your app to use the package.

The package stores values and errors in a single immutable `FormState`, exposed through `formStateProvider`. Each rendered field listens only to its own slice of state:

```dart
ref.watch(formStateProvider.select((state) => state.values[fieldName]));
ref.watch(formStateProvider.select((state) => state.errors[fieldName]));
```

When a user edits `email`, only the `email` field receives the changed selected value. Sibling fields keep their existing widget subtrees, which makes large forms much cheaper to type into. Conditional fields also declare their dependencies, so a `state` field can react to `country` without every other field waking up.

Global UI, such as submit buttons, can listen to the controller's `isFormValid`
`ValueListenable`, so it rebuilds only when validity changes. Advanced users can
also import the exported providers directly, but the normal API does not require
Riverpod knowledge.

---

## 🧪 Usage

Here’s how to use `FormWizard` in your project:

### 🪄 Step-by-Step

1. Initialize a `FormWizardController`.
2. Define fields with `FormWizardFieldModel`.
3. Pass the fields and controller to `FormWizard`.
4. Handle submission with `onSubmit`.

```dart
import 'package:form_wizard/form_wizard.dart';

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
      options: ['Male', 'Female', 'Other'],
    ),
    FormWizardFieldModel(
      name: 'country',
      label: 'Country',
      type: FieldType.dropdown,
      options: ['India', 'USA', 'Canada'],
    ),
    FormWizardFieldModel(
      name: 'state',
      label: 'State',
      type: FieldType.text,
      visibleWhenDependsOn: ['country'],
      visibleWhen: (values) => values['country'] == 'USA',
    ),
  ],
  fieldArrays: [
    FormWizardFieldArrayModel(
      name: 'phones',
      label: 'Phone Numbers',
      initialItemCount: 1,
      minItems: 1,
      fieldBuilder: (item) => [
        FormWizardFieldModel(
          name: item.fieldName('number'),
          label: 'Phone ${item.index + 1}',
          type: FieldType.text,
          validators: [Validators.required()],
        ),
      ],
    ),
  ],
  onSubmit: (values) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Form Submitted'),
        content: Text(values.toString()),
      ),
    );
  },
)
```

---

## 🎯 Conditional Visibility

Show or hide any field based on other field values:

```dart
FormWizardFieldModel(
  name: 'company_name',
  label: 'Company Name',
  type: FieldType.text,
  validators: [Validators.required()],
  visibleWhenDependsOn: ['account_type'],
  visibleWhen: (values) => values['account_type'] == 'Business',
)
```

Why `visibleWhenDependsOn` matters: it keeps visibility reactive without making the entire form rebuild. In the example above, `company_name` only reevaluates when `account_type` changes.

Hidden fields keep their values but do not block validation. If a required field is hidden, submit can still pass.

---

## 🔁 Dynamic Field Arrays

Use field arrays when users need to add as many groups as they want: phone numbers, addresses, team members, dependents, invoices, emergency contacts, anything repeatable.

```dart
FormWizard(
  controller: formController,
  fields: const [],
  fieldArrays: [
    FormWizardFieldArrayModel(
      name: 'team_members',
      label: 'Team Members',
      initialItemCount: 1,
      minItems: 1,
      maxItems: 10,
      fieldBuilder: (item) => [
        FormWizardFieldModel(
          name: item.fieldName('name'),
          label: 'Member ${item.index + 1} Name',
          type: FieldType.text,
          validators: [Validators.required()],
        ),
        FormWizardFieldModel(
          name: item.fieldName('email'),
          label: 'Member ${item.index + 1} Email',
          type: FieldType.email,
          validators: [Validators.email()],
        ),
      ],
    ),
  ],
)
```

Each array item receives a stable internal ID, so values stay attached to the right item when users reorder rows. The generated names look like:

```dart
team_members.fw_0.name
team_members.fw_0.email
team_members.fw_1.name
```

You can also control arrays imperatively:

```dart
formController.addFieldArrayItem('team_members');
formController.removeFieldArrayItem('team_members', itemId);
formController.reorderFieldArrayItem('team_members', oldIndex, newIndex);
```

On submit, you can read either the full flat value map or grouped array values:

```dart
final members = formController.getFieldArrayValues('team_members');
// [
//   {'name': 'Ava', 'email': 'ava@example.com'},
//   {'name': 'Noah', 'email': 'noah@example.com'},
// ]
```

The default UI includes add, remove, move up, and move down controls. You can replace them with `addButtonBuilder`, `removeButtonBuilder`, `moveUpButtonBuilder`, and `moveDownButtonBuilder`.

---

## 🧭 Multi-Step Forms (FormWizardStepper)
Create complex, multi-step forms with zero performance penalty. Each step is isolated — typing in Step 2 does NOT rebuild Step 1.

### Features
- Step isolation	Only the active step is in the widget tree
- Per-step validation	Next button enables only when current step is valid
- Data persistence	All step data preserved in global form state
- Custom UI	Full control via stepBuilder
- Performance	No rebuilds of inactive steps

`Basic Usage`

```dart
FormWizardStepper(
  steps: [
    FormWizardStep(
      title: 'Personal',
      fields: [
        FormWizard.nameField(name: 'name'),
        FormWizard.emailField(name: 'email'),
      ],
    ),
    FormWizardStep(
      title: 'Address',
      fields: [
        FormWizard.streetField(name: 'street'),
        FormWizard.cityField(name: 'city'),
      ],
    ),
  ],
  onFinish: (values) => print('Form completed: $values'),
)
```

-  Custom UI with stepBuilder
Take full control of the stepper layout:

```dart
FormWizardStepper(
  steps: [...],
  stepBuilder: (context, stepper) {
    return Column(
      children: [
        // Custom progress indicator
        LinearProgressIndicator(
          value: (stepper.currentStep + 1) / stepper.steps.length,
        ),
        // Step title
        Text(stepper.steps[stepper.currentStep].title),
        const SizedBox(height: 16),
        // Form fields
        stepper.fields,
        const SizedBox(height: 24),
        // Custom navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (stepper.currentStep > 0)
              ElevatedButton(
                onPressed: stepper.onBack,
                child: Text('Back'),
              ),
            ElevatedButton(
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
)
```


⚡ `Performance Note`
Only the active step's fields are in the widget tree. When you navigate away from a step, its widgets are disposed — saving memory and preventing unnecessary rebuilds.


---

### 📦  Built-in Form Templates

Stop rewriting the same forms. Use our pre-built, fully customizable templates. Available Templates


 `LoginForm`
```dart
LoginForm(
  identityType: IdentityType.email, // or .phone, .username
  onLogin: (identity, password) async {
    await authService.login(identity, password);
  },
  forgotPasswordLink: () => navigateToForgotPassword(),
  rememberMe: true,
  submitButtonText: 'Sign In',
)
```

 `SignupForm`
```dart
SignupForm(
  identityType: IdentityType.email,
  requireTermsAcceptance: true,
  onSignup: (name, identity, password) async {
    await authService.register(name, identity, password);
  },
  submitButtonText: 'Create Account',
)
```


`OTPVerificationForm`
```dart
OTPVerificationForm(
  identifier: 'user@example.com', // phone or email
  resendCooldownSeconds: 30,
  onVerify: (otp) async {
    await authService.verifyOTP(otp);
  },
  onResend: () async {
    await authService.resendOTP();
  },
)
```

 `AddressForm`
```dart
AddressForm(
  onSubmit: (address) async {
    await saveAddress(address);
  },
  includeState: true, // state dropdown depends on country
  submitButtonText: 'Save Address',
)
```

`PaymentForm`
```dart
PaymentForm(
  onSubmit: (paymentDetails) async {
    await processPayment(paymentDetails);
  },
  submitButtonText: 'Pay Now',
)
```


---

### 🧩 Field Presets (Composable)

Don't want a full template? Use individual field presets to build your own forms:
```dart
FormWizard(
  fields: [
    FormWizard.nameField(),
    FormWizard.emailField(),
    FormWizard.passwordField(),
    FormWizard.phoneField(),
    FormWizard.addressField(),
    FormWizard.cityField(),
    FormWizard.zipField(),
    FormWizard.countryDropdown(),
    FormWizard.otpField(),
  ],
  onSubmit: (values) => print(values),
)
```


🎯 Complete Example: Multi-step Checkout
```dart
FormWizardStepper(
  steps: [
    FormWizardStep(
      title: 'Shipping',
      fields: [AddressForm.fields()], // Reuse address fields
    ),
    FormWizardStep(
      title: 'Payment',
      fields: [PaymentForm.fields()], // Reuse payment fields
    ),
    FormWizardStep(
      title: 'Review',
      fields: [
        FormWizard.reviewField(
          builder: (values) => OrderSummary(values),
        ),
      ],
    ),
  ],
  onFinish: (values) => placeOrder(values),
)
```

---

## 🧱 Supported Field Types

| Field Type | Description                              |
| ---------- | ---------------------------------------- |
| `text`     | Standard text field                      |
| `email`    | Validates email format                   |
|  `Otp Field`| OTP Input Field                                  |
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

> Crafted with ❤️ by [Tanay](https://github.com/Tanay610) & powered by Flutter + RiverPod.
