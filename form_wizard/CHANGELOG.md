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
