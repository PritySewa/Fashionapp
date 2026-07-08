/// Common form field validators.
///
/// All functions return `null` when valid, or an error string when invalid.
abstract final class AppValidators {
  /// Field must not be empty.
  static String? required(String? value, {String? label}) {
    if (value == null || value.trim().isEmpty) {
      return '${label ?? 'This field'} is required';
    }
    return null;
  }

  /// Must be a valid email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  /// Password minimum length (default: 8 characters).
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Must be a positive number.
  static String? positiveNumber(String? value, {String? label}) {
    if (value == null || value.trim().isEmpty) {
      return '${label ?? 'This field'} is required';
    }
    final n = num.tryParse(value.trim());
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Must be greater than zero';
    return null;
  }

  /// Optional minimum/maximum length check.
  static String? length(String? value, {int? min, int? max, String? label}) {
    if (value == null || value.trim().isEmpty) {
      return '${label ?? 'This field'} is required';
    }
    if (min != null && value.length < min) {
      return '${label ?? 'Value'} must be at least $min characters';
    }
    if (max != null && value.length > max) {
      return '${label ?? 'Value'} must be at most $max characters';
    }
    return null;
  }
}
