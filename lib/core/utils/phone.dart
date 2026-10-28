abstract final class PhoneUtils {
  static final RegExp _pkPhoneRegex = RegExp(r'^923[0-9]{9}$');

  /// Normalizes any Pakistani mobile number format:
  /// `03001234567`, `+923001234567`, `923001234567`, `0300 1234567`
  /// to normalized digits-only string: `923001234567`
  static String normalize(String raw) {
    String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('03') && digits.length == 11) {
      digits = '92${digits.substring(1)}';
    } else if (digits.startsWith('3') && digits.length == 10) {
      digits = '92$digits';
    }
    return digits;
  }

  /// Checks if the input is a valid Pakistani mobile number.
  static bool isValid(String raw) {
    final normalized = normalize(raw);
    return _pkPhoneRegex.hasMatch(normalized);
  }

  /// Formats a normalized `923XXXXXXXXX` (or any valid raw number) into display format:
  /// `0300 1234567`
  static String formatDisplay(String raw) {
    final normalized = normalize(raw);
    if (normalized.length != 12 || !normalized.startsWith('923')) {
      return raw;
    }
    final national = '0${normalized.substring(2)}'; // 03001234567
    return '${national.substring(0, 4)} ${national.substring(4)}';
  }

  /// Returns international format with + prefix:
  /// `+92 300 1234567` or `+923001234567`
  static String formatInternational(String raw, {bool withSpaces = false}) {
    final normalized = normalize(raw);
    if (normalized.length != 12) return raw;
    if (withSpaces) {
      return '+92 ${normalized.substring(2, 5)} ${normalized.substring(5)}';
    }
    return '+$normalized';
  }
}
