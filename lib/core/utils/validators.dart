import '../constants/formats.dart';

class Validators {
  Validators._();

  /// Helper to choose correct "is/are" based on field name
  static String _requiredMessage(String fieldName) {
    final needsAre = fieldName.trim().endsWith('s');
    return "$fieldName ${needsAre ? 'are' : 'is'} required";
  }

  /// Validate a simple text (not null, not empty, not just spaces)
  static String? validateText(String? value, {String fieldName = "Field"}) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage(fieldName);
    }
    return null;
  }

  /// Validate description text (<= 200 words)
  static String? validateDescription(
    String? value, {
    String fieldName = "Description",
  }) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage(fieldName);
    }
    final wordCount = value.trim().split(RegExp(r'\s+')).length;
    if (wordCount > 200) {
      return "$fieldName must be less than 200 words";
    }
    return null;
  }

  /// Validate integer number (no decimals allowed)
  static String? validateInteger(String? value, {String fieldName = "Number"}) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage(fieldName);
    }

    final pattern = RegExp(r'^\d+$');
    if (!pattern.hasMatch(value.trim())) {
      return "Enter valid $fieldName";
    }

    return null;
  }

  /// Validate number (decimals allowed)
  static String? validateDecimal(String? value, {String fieldName = "Number"}) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage(fieldName);
    }

    final pattern = RegExp(r'^\d+(\.\d+)?$'); // digits with optional decimal
    if (!pattern.hasMatch(value.trim())) {
      return "Enter valid $fieldName";
    }

    return null;
  }

  /// Validate hours (format hh.mm)
  static String? validateHours(String? value, {String fieldName = "Hours"}) {
    if (value == null || value.trim().isEmpty) {
      return _requiredMessage(fieldName);
    }
    final pattern = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!pattern.hasMatch(value.trim())) {
      return "Enter valid hh.mm (e.g. 01.50)";
    }
    final numValue = double.tryParse(value.trim());
    if (numValue == null || numValue >= 100) {
      return "Invalid hour format";
    }
    return null;
  }

  /// Validate date string using your formats (MM/dd/yyyy by default)
  static String? validateDate(
    String? value, {
    String format = ConstFormats.DATE_MMDDYYYY,
    DateTime? lastDate,
  }) {
    if (value == null || value.trim().isEmpty) {
      return "Date is required";
    }

    try {
      final parts = value.split('/');
      if (parts.length != 3) return "Enter valid date ($format)";

      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (month == null || day == null || year == null) {
        return "Enter valid date ($format)";
      }

      if (month < 1 || month > 12) {
        return "Month must be between 1 and 12";
      }

      if (year < 2000 || year > 2050) {
        return "Year must be between 2000 and 2050";
      }

      // Days in month check, including leap years
      final maxDay = DateTime(year, month + 1, 0).day;
      if (day < 1 || day > maxDay) {
        return "Day must be between 1 and $maxDay for month $month";
      }

      final parsedDate = DateTime(year, month, day);
      // Optional: Check for trailing characters by comparing reconstructed date
      if (parsedDate.month != month ||
          parsedDate.day != day ||
          parsedDate.year != year) {
        return "Enter valid date ($format)";
      }

      // Validate against lastDate if provided
      if (lastDate != null && parsedDate.isAfter(lastDate)) {
        // Format lastDate to match the expected input format (MM/dd/yyyy)
        final formattedLastDate =
            "${lastDate.month}/${lastDate.day}/${lastDate.year}";
        return "Date must be on or before $formattedLastDate";
      }

      return null; // Valid date
    } catch (_) {
      return "Enter valid date ($format)";
    }
  }
}
