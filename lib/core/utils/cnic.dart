abstract final class CnicUtils {
  static final RegExp _cnicRegex = RegExp(r'^[0-9]{13}$');

  /// Strips any dashes or non-digits
  static String normalize(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Validates whether the string is a valid 13-digit Pakistani CNIC
  static bool isValid(String raw) {
    final digits = normalize(raw);
    return _cnicRegex.hasMatch(digits);
  }

  /// Formats 13 digits to standard CNIC format: `35201-1234567-1`
  static String format(String raw) {
    final digits = normalize(raw);
    if (digits.length != 13) return raw;
    return '${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12)}';
  }

  /// Masks CNIC for privacy: `•••••-•••••67-1`
  static String mask(String raw) {
    final digits = normalize(raw);
    if (digits.length != 13) return raw;
    final lastThree = digits.substring(10); // e.g. '671'
    return '•••••-•••••${lastThree.substring(0, 2)}-${lastThree.substring(2)}';
  }
}
