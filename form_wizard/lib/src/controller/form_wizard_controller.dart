import 'package:get/get.dart';

class FormWizardController extends GetxController {
  final RxMap<String, String?> _formValues = <String, String?>{}.obs;
  final RxMap<String, String?> _fieldErrors = <String, String?>{}.obs;

  void setValue(String fieldName, String? value) {
    _formValues[fieldName] = value;
    _fieldErrors[fieldName] = null;
  }

  String? getValue(String fieldName) => _formValues[fieldName];
  String? getError(String fieldName) => _fieldErrors[fieldName];

  void setError(String fieldName, String? error) {
    _fieldErrors[fieldName] = error;
  }

  bool validateField(
    String fieldName,
    String? value,
    List<String? Function(String?)>? validators,
  ) {
    if (validators != null) {
      for (var validator in validators) {
        final result = validator(value);
        if (result != null) {
          setError(fieldName, result);
          return false;
        }
      }
    }
    setError(fieldName, null);
    return true;
  }

  bool validateAll(Map<String, List<String? Function(String?)>?> validatorsMap) {
    bool allValid = true;
    validatorsMap.forEach((key, validators) {
      final valid = validateField(key, _formValues[key], validators);
      if (!valid) allValid = false;
    });
    return allValid;
  }

  Map<String, String?> get formData => _formValues;
}
