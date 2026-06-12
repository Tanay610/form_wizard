## 0.2.0

### Validation Engine
- Added dependency-aware cross-field validation with `contextValidators` and `validationDependsOn`.
- Added debounced async validators with stale-result cancellation for server-backed checks.
- Added `Validators.matchesField(...)` for confirm-password and related field matching.
- Added `validateFieldAsync`, `validateFieldsAsync`, `validateFormAsync`, and `submitFormAsync`.

### Performance
- Kept field updates selective: edited fields and explicitly dependent fields update, unrelated fields stay static.
- Full-form validation now batches errors into a single state update instead of emitting once per field.
- Async validation tracks pending fields without rebuilding the whole form.

### Field State & UX
- Added dirty, touched, submitted, and validating state to `FormState`.
- Added narrow providers for field value, error, dirty, touched, and validating state.
- Added `FormWizardController.isValidating`.
- Added focus/scroll to the first invalid rendered field on failed submit.

### Field APIs
- Added `valueTransformer` and `transformedFormData` for typed submit values.
- Added common TextField options: input formatters, autofill hints, text input actions, max/min lines, max length, enabled/read-only state, capitalization, and submit callbacks.
- Improved field presets with autofill hints, input formatters, and keyboard actions.

### Reliability
- Hardened built-in templates so internally owned controllers are created and disposed by widget lifecycle.
- Updated the example app with async username validation and dependency-aware confirm password validation.

## 0.1.2

### Performance
- Collapsed field value updates and field validation into a single provider state emission per edit.
- Added no-op guards around form configuration to avoid redundant setup emissions.
- Fixed `formValidityProvider` to use the same hidden-field-aware validity logic as `FormState.isValid`.
- Cleaned stepper validity watching to avoid broad selector churn.

### Reliability
- Replaced deprecated dropdown `value` usage with `initialValue`.
- Fixed OTP resend cooldown internals so timers/notifiers are owned and disposed safely.
- Improved internally owned stepper controller lifecycle.
- Fixed a rare tab/page switching lifecycle issue where internally scoped forms could trigger `setState()` after dispose.

### Documentation
- Added a clear v0.1.2 performance upgrade section to README.
- Updated README examples for current template, stepper, field array, and preset APIs.

## 0.1.1

- 🧙‍♂️ Added wizard icon to README
- Minor documentation improvements

## 0.1.0
### ✨ New Features
- **FormWizardStepper**: Multi-step forms with step isolation
- **Conditional Visibility**: Show/hide fields reactively
- **Dynamic Field Arrays**: Add/remove/reorder repeating field groups
- **Built-in Templates**: LoginForm, SignupForm, OTPVerificationForm, AddressForm, PaymentForm
- **Field Presets**: emailField, phoneField, passwordField, otpField, nameField, streetField, cityField, zipField, countryDropdown

### ⚡ Performance Upgrade
- Stepper only rebuilds on navigation or current step validity change
- Inactive steps are disposed (zero memory overhead)
- Each field watches only its own value via `.select()`

### 🔧 Internal
- Upgraded `flutter_riverpod` to `^3.3.1`
- Migrated to `NotifierProvider` internally

### 📚 Documentation
- Updated README with all new features
- Added performance comparison section
- Added API reference for templates

### Breaking Changes
- None (fully backward compatible)
