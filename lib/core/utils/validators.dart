/// Reusable form validators with clear error messages.
class Validators {
  Validators._();

  static String? required(String? v, {String field = 'This field'}) {
    if (v == null || v.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? v) {
    final r = required(v, field: 'Email');
    if (r != null) return r;
    final email = v!.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? v) {
    final r = required(v, field: 'Password');
    if (r != null) return r;
    if (v!.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? positiveInt(String? v, {String field = 'Quantity'}) {
    final r = required(v, field: field);
    if (r != null) return r;
    final n = int.tryParse(v!.trim());
    if (n == null || n < 1) {
      return '$field must be a positive whole number';
    }
    return null;
  }

  static String? nonNegativeNumber(String? v, {String field = 'Value'}) {
    final r = required(v, field: field);
    if (r != null) return r;
    final n = double.tryParse(v!.trim());
    if (n == null || n < 0) {
      return '$field must be zero or greater';
    }
    return null;
  }
}
