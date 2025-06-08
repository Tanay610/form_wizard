typedef Validator = String? Function(String?);

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

  static Validator regex(RegExp pattern, {String message = 'Invalid format'}) {
  return (value) {
    if (value == null || value.isEmpty) return null;
    return pattern.hasMatch(value) ? null : message;
  };
}
}
