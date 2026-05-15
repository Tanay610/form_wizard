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