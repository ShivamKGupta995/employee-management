/// Validators - Common validation functions
class Validators {
  Validators._();

  // ==========================================
  // EMAIL VALIDATION
  // ==========================================
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }

  // ==========================================
  // PASSWORD VALIDATION
  // ==========================================
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  /// Strong password validation
  static String? passwordStrong(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    
    return null;
  }

  // ==========================================
  // NAME VALIDATION
  // ==========================================
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }

  // ==========================================
  // PHONE VALIDATION
  // ==========================================
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces and dashes for validation
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cleaned.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Optional phone validation
  static String? phoneOptional(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional, so empty is valid
    }
    
    return phone(value);
  }

  // ==========================================
  // REQUIRED FIELD VALIDATION
  // ==========================================
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    return null;
  }

  // ==========================================
  // NUMBER VALIDATION
  // ==========================================
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    
    return null;
  }

  /// Number in range validation
  static String? numberInRange(String? value, {int? min, int? max}) {
    final baseValidation = number(value);
    if (baseValidation != null) return baseValidation;
    
    final num = int.parse(value!);
    
    if (min != null && num < min) {
      return 'Value must be at least $min';
    }
    
    if (max != null && num > max) {
      return 'Value must be at most $max';
    }
    
    return null;
  }

  // ==========================================
  // LENGTH VALIDATION
  // ==========================================
  static String? minLength(String? value, int min) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    if (value.length < min) {
      return 'Must be at least $min characters';
    }
    
    return null;
  }

  static String? maxLength(String? value, int max) {
    if (value == null) return null;
    
    if (value.length > max) {
      return 'Must be at most $max characters';
    }
    
    return null;
  }

  // ==========================================
  // CONFIRM PASSWORD
  // ==========================================
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      
      if (value != password) {
        return 'Passwords do not match';
      }
      
      return null;
    };
  }
}
