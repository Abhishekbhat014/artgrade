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

  // =========================
  // PHONE VALIDATIONS
  // =========================

  static bool isValidPhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    return cleaned.length == 10;
  }

  static String sanitizePhone(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  // =========================
  // PASSWORD VALIDATIONS
  // =========================

  static bool isStrongPassword(String value) {
    // Min 8 chars, 1 upper, 1 lower, 1 number
    return RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$',
    ).hasMatch(value);
  }

  // =========================
  // DATE OF BIRTH VALIDATIONS
  // =========================

  static bool isValidDob(DateTime dob) {
    final now = DateTime.now();
    return dob.isBefore(now);
  }

  static bool isMinimumAge(DateTime dob, {int minAge = 13}) {
    final today = DateTime.now();
    int age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    return age >= minAge;
  }

  // =========================
  // GENDER / ENUM VALIDATION
  // =========================

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
