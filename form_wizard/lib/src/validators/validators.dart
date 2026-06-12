/// Synchronous validator for a single field value.
typedef Validator = String? Function(String?);

/// Synchronous validator that can inspect the full form value map.
typedef FormWizardContextValidator =
    String? Function(String? value, FormWizardValidationContext context);

/// Asynchronous validator for server-backed or expensive checks.
typedef FormWizardAsyncValidator =
    Future<String?> Function(
      String? value,
      FormWizardValidationContext context,
    );

/// Transforms a raw field value into the value callers want to submit.
typedef FormWizardValueTransformer =
    dynamic Function(dynamic value, FormWizardValidationContext context);

/// Read-only validation context passed to advanced validators.
class FormWizardValidationContext {
  /// Creates a validation context from the latest form values.
  const FormWizardValidationContext(this.values);

  /// Current form values keyed by field name.
  final Map<String, dynamic> values;

  /// Returns the value for [fieldName].
  dynamic value(String fieldName) => values[fieldName];
}

class Validators {
  static Validator required({String message = 'This field is required'}) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  static Validator email({String message = 'Invalid email address'}) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(value) ? null : message;
    };
  }

  static Validator minLength(int length, {String? message}) {
    return (value) {
      if (value == null || value.length < length) {
        return message ?? 'Minimum length is $length characters';
      }
      return null;
    };
  }

  static Validator maxLength(int length, {String? message}) {
    return (value) {
      if (value != null && value.length > length) {
        return message ?? 'Maximum length is $length characters';
      }
      return null;
    };
  }

  static Validator number({String message = 'Only numbers allowed'}) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      final numberRegex = RegExp(r'^\d+$');
      return numberRegex.hasMatch(value) ? null : message;
    };
  }

  static Validator phone({String message = 'Invalid phone number'}) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,20}$');
      return phoneRegex.hasMatch(value) ? null : message;
    };
  }

  static Validator exactLength(int length, {String? message}) {
    return (value) {
      if (value == null || value.length != length) {
        return message ?? 'Must be $length characters';
      }
      return null;
    };
  }

  static Validator matches(
    String otherValue, {
    String message = 'Values do not match',
  }) {
    return (value) => value == otherValue ? null : message;
  }

  static FormWizardContextValidator matchesField(
    String otherFieldName, {
    String message = 'Values do not match',
  }) {
    return (value, context) {
      return value == context.value(otherFieldName)?.toString()
          ? null
          : message;
    };
  }

  static Validator regex(RegExp pattern, {String message = 'Invalid format'}) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      return pattern.hasMatch(value) ? null : message;
    };
  }
}
