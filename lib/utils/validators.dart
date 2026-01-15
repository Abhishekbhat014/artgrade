class Validators {
  // =========================
  // BASIC VALIDATIONS
  // =========================

  static bool isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email.trim());
  }

  // =========================
  // NAME VALIDATIONS
  // =========================

  static bool isValidName(String value) {
    return RegExp(r'^[a-zA-Z ]+$').hasMatch(value.trim()) &&
        value.trim().length >= 2;
  }



  static bool isValidDob(DateTime dob) {
    final now = DateTime.now();
    return dob.isBefore(now);
  }

  static bool isValidGender(String value) {
    const allowed = ['Male', 'Female', 'Other'];
    return allowed.contains(value);
  }

  static bool isValidNetworkUri(Uri uri) {
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static bool isValidPdfUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool isPdfFile(List<int> bytes) {
    if (bytes.length < 5) return false;
    final header = String.fromCharCodes(bytes.take(5));
    return header.startsWith('%PDF-');
  }
}
