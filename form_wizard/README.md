# form_wizard <span style="font-size: 3rem;">🧙‍♂️</span>

[![pub package](https://img.shields.io/pub/v/form_wizard.svg)](https://pub.dev/packages/form_wizard)
[![pub points](https://img.shields.io/pub/points/form_wizard)](https://pub.dev/packages/form_wizard/score)
[![likes](https://img.shields.io/pub/likes/form_wizard)](https://pub.dev/packages/form_wizard)
[![GitHub](https://img.shields.io/badge/GitHub-Open-blue)](https://github.com/Tanay610/form_wizard)

> The most performant, customizable, lightweight, and powerful form builder for Flutter.

`form_wizard` is built for every serious Flutter form, from simple login screens to complex onboarding, checkout, KYC, dashboard, survey, dynamic-array, and multi-step workflows.

Under the hood, `form_wizard` uses Riverpod for surgical, field-level reactivity. In your app, it feels dependency-free: no `ProviderScope`, no Riverpod setup, no state-management lock-in. Install it, define your fields, and ship fast forms that stay fast.

---

## Why form_wizard?

Flutter forms should not become slower, messier, or harder to maintain as they grow. `form_wizard` gives you the performance, validation engine, dynamic UI, templates, and customization needed to build production forms without rebuilding the world on every keystroke.

`form_wizard` is built for Flutter teams who want forms that feel simple to create, powerful to extend, and fast no matter how complex the workflow becomes.

`form_wizard` brings the most in-demand form-builder features into one lightweight package:

| In-demand feature | Built into form_wizard |
|-------------------|------------------------|
| High-performance forms | Only the field being edited rebuilds |
| Server-side checks | Debounced async validators with stale-result cancellation |
| Cross-field rules | Dependency-aware validation for password match, date ranges, totals, and more |
| Conditional fields | Show/hide fields reactively based on other values |
| Repeatable groups | Dynamic field arrays with add, remove, reorder, and stable item values |
| Multi-step flows | `FormWizardStepper` with active-step-only rendering |
| Ready-made forms | Login, Signup, OTP, Address, and Payment templates |
| Common inputs | Email, phone, password, OTP, address, ZIP, country, and name presets |
| Production UX | Dirty/touched/validating state, typed values, and focus-first-invalid submit |
| Full customization | Custom fields, custom decorations, custom buttons, and custom stepper UI |

Use it for a login screen, checkout, KYC flow, dashboard editor, survey, onboarding wizard, team-member array, or any form that should stay fast as it grows.

---

## Demo

### Fine-Grained Form UI
![Form Preview](https://raw.githubusercontent.com/Tanay610/form_wizard/main/form_wizard/screenshots/gif-1.gif)

### Real-Time Validation
![Validation](https://raw.githubusercontent.com/Tanay610/form_wizard/main/form_wizard/screenshots/gif-2.gif)

### Custom Field Validation
![Custom Widget](https://raw.githubusercontent.com/Tanay610/form_wizard/main/form_wizard/screenshots/gif-3.gif)

---

## What's New in v0.2.0

v0.2.0 upgrades `form_wizard` from a fast form builder into a production-ready validation engine.

| Upgrade | Why it matters |
|---------|----------------|
| Debounced async validators | Check usernames, emails, invite codes, coupon codes, or server rules without blocking the UI |
| Stale async cancellation | Fast typing cannot let an old async response overwrite the newest value |
| Dependency-aware validation | Confirm password, start/end date, min/max amount, and related fields revalidate correctly |
| Dirty/touched/submitted/validating state | Build polished validation UX without whole-form subscriptions |
| Typed value transformers | Keep text input fast, submit clean typed values |
| Focus first invalid field | Failed submit takes users directly to the field they need to fix |
| Richer field options | Input formatters, autofill hints, keyboard actions, max length, read-only/enabled state, and more |
| Safer templates | Built-in templates now own and dispose internal controllers correctly |

---

## Install

```yaml
dependencies:
  form_wizard: ^0.2.0
```

```dart
import 'package:form_wizard/form_wizard.dart';
```

No app-level Riverpod setup is required.

---

## Quick Start

```dart
final controller = FormWizardController();

FormWizard(
  controller: controller,
  fields: [
    FormWizard.emailField(),
    FormWizard.passwordField(),
  ],
  onSubmit: (values) {
    print(values);
  },
)
```

That is enough to get validation, submit handling, fine-grained rebuilds, and internal state management.

---

## Performance Architecture

`form_wizard` stores form values, errors, visibility, arrays, and validation state in one immutable `FormState`.

Each field listens only to its own slice:

```dart
ref.watch(formStateProvider.select((state) => state.values[fieldName]));
ref.watch(formStateProvider.select((state) => state.errors[fieldName]));
ref.watch(fieldValidatingProvider(fieldName));
```

When a user edits `email`, the `email` field reacts. Other fields stay still unless they explicitly depend on `email`.

### What does not rebuild unnecessarily?

- Sibling fields when one field changes
- Hidden conditional fields
- Inactive stepper steps
- Field-array siblings unless the item list changes
- Submit controls unless validity/pending state changes
- Unrelated cross-field validators

### Dependency-aware updates

If `confirm_password` declares:

```dart
validationDependsOn: ['password']
```

then changing `password` revalidates `password` and `confirm_password`, not the whole form.

---

## Feature Overview

### Core

- Fine-grained state updates
- Internal Riverpod 3 powered store
- No external `ProviderScope` required
- `FormWizardController` with `ValueListenable`s
- Sync validation
- Debounced async validation
- Cross-field validation
- Hidden-field-aware validity
- Dirty, touched, submitted, and validating state
- Focus/scroll to first invalid field

### Fields

- Text
- Email
- Password
- Number
- Dropdown
- Date
- Custom widgets
- Input formatters
- Autofill hints
- Keyboard actions
- Typed value transformers
- Custom decorations

### Advanced

- Conditional visibility
- Dynamic field arrays
- Add/remove/reorder repeatable groups
- Multi-step forms with `FormWizardStepper`
- Built-in templates
- Field presets

---

## Async Validation

Use async validators for server-backed or expensive checks.

```dart
FormWizardFieldModel(
  name: 'username',
  label: 'Username',
  type: FieldType.text,
  validators: [Validators.required()],
  asyncValidationDebounce: const Duration(milliseconds: 300),
  asyncValidators: [
    (value, context) async {
      final available = await api.isUsernameAvailable(value ?? '');
      return available ? null : 'Username is already taken';
    },
  ],
)
```

Submit with async validators:

```dart
await controller.submitFormAsync((values) {
  saveProfile(values);
});
```

The async engine is debounced per field and ignores stale responses.

---

## Cross-Field Validation

Use `contextValidators` when a field depends on other values.

```dart
FormWizardFieldModel(
  name: 'confirm_password',
  label: 'Confirm Password',
  type: FieldType.password,
  validators: [Validators.required()],
  contextValidators: [
    Validators.matchesField(
      'password',
      message: 'Passwords do not match',
    ),
  ],
  validationDependsOn: ['password'],
)
```

The dependency list is important. It tells `form_wizard` exactly which fields should revalidate together.

---

## Conditional Visibility

Show or hide fields based on other values without waking the whole form.

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

Hidden fields keep their values, but they do not block submit or form validity.

---

## Dynamic Field Arrays

Use field arrays for repeatable groups: phone numbers, addresses, team members, invoices, dependents, emergency contacts, and more.

```dart
FormWizard(
  controller: controller,
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

Each item receives a stable ID, so values stay attached to the right row during reorder operations.

```dart
controller.addFieldArrayItem('team_members');
controller.removeFieldArrayItem('team_members', itemId);
controller.reorderFieldArrayItem('team_members', oldIndex, newIndex);
```

Read grouped values:

```dart
final members = controller.getFieldArrayValues('team_members');
```

---

## Multi-Step Forms

`FormWizardStepper` creates isolated multi-step forms. Only the active step's fields are in the widget tree.

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
  onFinish: (values) {
    print(values);
  },
)
```

Stepper features:

- Active-step-only rendering
- Per-step validation
- Persistent data across steps
- Optional `onStepChanged`
- Custom UI with `stepBuilder`
- Material stepper by default

---

## Built-In Templates

Ship common forms in minutes, then override anything.

### Login

```dart
LoginForm(
  identityType: FormWizardIdentityType.email,
  rememberMe: true,
  forgotPasswordLink: () => openForgotPassword(),
  onLogin: (identity, password) {
    auth.login(identity, password);
  },
)
```

### Signup

```dart
SignupForm(
  identityType: FormWizardIdentityType.email,
  requireTermsAcceptance: true,
  onSignup: (name, identity, password) {
    auth.createAccount(name, identity, password);
  },
)
```

### OTP Verification

```dart
OTPVerificationForm(
  otpLength: 6,
  resendCooldownSeconds: 30,
  onVerify: verifyOtp,
  onResend: resendOtp,
)
```

### Address

```dart
AddressForm(
  includeState: true,
  onSubmit: saveAddress,
)
```

### Payment

```dart
PaymentForm(
  submitLabel: 'Pay Now',
  onSubmit: processPayment,
)
```

---

## Field Presets

Use presets when you want composable building blocks instead of full templates.

```dart
FormWizard(
  controller: controller,
  fields: [
    FormWizard.nameField(),
    FormWizard.emailField(
      asyncValidators: [
        (value, context) async {
          final exists = await api.emailExists(value ?? '');
          return exists ? 'Email already exists' : null;
        },
      ],
    ),
    FormWizard.passwordField(),
    FormWizard.phoneField(),
    FormWizard.streetField(),
    FormWizard.cityField(),
    FormWizard.zipField(),
    FormWizard.countryDropdown(),
    FormWizard.otpField(length: 6),
  ],
  onSubmit: save,
)
```

---

## Typed Submit Values

Raw field input stays simple and fast. Transform values only when you need typed output.

```dart
FormWizardFieldModel(
  name: 'age',
  label: 'Age',
  type: FieldType.number,
  validators: [Validators.required(), Validators.number()],
  valueTransformer: (value, context) {
    return int.tryParse(value?.toString() ?? '');
  },
)
```

```dart
await controller.submitFormAsync(
  (values) {
    print(values['age']); // int?
  },
  transformValues: true,
);
```

---

## Custom Field Widgets

Use `customBuilder` when you want total control.

```dart
FormWizardFieldModel(
  name: 'budget',
  label: 'Budget',
  type: FieldType.custom,
  validators: [
    (value) {
      final amount = double.tryParse(value ?? '');
      return amount != null && amount >= 1000
          ? null
          : 'Minimum budget is 1000';
    },
  ],
  customBuilder: (controller, errorText, onChanged) {
    final value = double.tryParse(controller.text) ?? 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          min: 1000,
          max: 10000,
          divisions: 9,
          value: value,
          onChanged: (next) {
            controller.text = next.toStringAsFixed(0);
            onChanged(controller.text);
          },
        ),
        if (errorText != null)
          Text(
            errorText,
            style: const TextStyle(color: Colors.red),
          ),
      ],
    );
  },
)
```

---

## Controller API

```dart
final controller = FormWizardController();

controller.updateFieldValue('email', 'ava@example.com');
controller.validateField('email');
await controller.validateFieldAsync('username');
controller.validateForm();
await controller.validateFormAsync();

controller.formData;
controller.transformedFormData;
controller.isFormValid;
controller.isValidating;
controller.fieldErrors;

controller.focusFirstInvalidField();
controller.dispose();
```

---

## Supported Field Types

| Type | Use case |
|------|----------|
| `FieldType.text` | Standard text input |
| `FieldType.email` | Email keyboard and email validation |
| `FieldType.password` | Obscured password input |
| `FieldType.number` | Numeric input |
| `FieldType.dropdown` | Select from options |
| `FieldType.date` | Date picker with formatting |
| `FieldType.custom` | Fully custom widget |

---

## Validation Toolkit

```dart
Validators.required()
Validators.email()
Validators.minLength(8)
Validators.maxLength(64)
Validators.number()
Validators.phone()
Validators.exactLength(6)
Validators.regex(RegExp(r'^[a-z0-9_]+$'))
Validators.matchesField('password')
```

Custom validators are just functions:

```dart
validators: [
  (value) => value == 'magic' ? null : 'Only magic is accepted',
]
```

---

## API Docs

- [Package on pub.dev](https://pub.dev/packages/form_wizard)
- [API documentation](https://pub.dev/documentation/form_wizard/latest/form_wizard/)
- [GitHub repository](https://github.com/Tanay610/form_wizard)

---

## Contributing

Contributions are welcome.

Good contribution areas:

- Additional field presets
- More validation helpers
- Accessibility improvements
- Better examples
- Performance benchmarks
- Documentation improvements

Before opening a pull request:

```bash
dart format .
flutter analyze
flutter test
```

---

## License

`form_wizard` is released under the MIT License. See [LICENSE](LICENSE).

---

Built with Flutter, Riverpod, and an unreasonable obsession with form performance by [Tanay](https://github.com/Tanay610).
