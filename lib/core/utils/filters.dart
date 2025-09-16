import 'package:intl/intl.dart';
import '../constants/formats.dart';

class Filters {
  Filters._();

  static String? toCurrency(num? value, int precisions) {
    if (value != null) {
      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: '\$',
        decimalDigits: precisions,
      );
      return formatter.format(value);
    }
    return null;
  }

  static String? toNumeric(num? value, int precisions) {
    if (value != null) {
      final formatter = NumberFormat.decimalPattern('en_US')
        ..minimumFractionDigits = precisions
        ..maximumFractionDigits = precisions;
      return formatter.format(value);
    }
    return null;
  }

  static String? toPrice(num? value, int precisions) {
    if (value != null) {
      final newVal = value < 10 ? double.parse("0$value") : value;
      return newVal.toStringAsFixed(2);
    }
    return null;
  }

  static String? toPercentage(num? value, int precisions) {
    if (value != null) {
      final formatter = NumberFormat.decimalPattern('en_US')
        ..minimumFractionDigits = precisions
        ..maximumFractionDigits = precisions;
      return '${formatter.format(value)}%';
    }
    return null;
  }

  static String? toPhone(String? value, {String countryCode = ''}) {
    if (value == null || value.isEmpty) return null;
    if (countryCode == 'IN') {
      return '+91 $value';
    } else {
      return '+1 ${value.replaceFirstMapped(RegExp(r'(\d{3})(\d{3})(\d{4})'), (m) => '(${m[1]})${m[2]}-${m[3]}')}';
    }
  }

  static String? toFax(String? value) {
    if (value == null || value.isEmpty) return null;
    return value.replaceFirstMapped(
      RegExp(r'(\d{3})(\d{3})(\d{4})'),
      (m) => '(${m[1]})${m[2]}-${m[3]}',
    );
  }

  static String toName(
    String? lastName,
    String? firstName,
    String? middleName,
  ) {
    return '${lastName ?? ''}, ${firstName ?? ''} ${middleName ?? ''}'.trim();
  }

    static String toInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';

    return fullName
        .trim()
        .split(RegExp(r'\s+')) // split by spaces
        .where((e) => e.isNotEmpty) // clean empty
        .map((e) => e[0]) // first letter of each part
        .take(2) // only first 2 letters
        .join()
        .toUpperCase();
  }

  static String? toDate(
    DateTime? value, {
    String format = ConstFormats.DATE_MMDDYYYY,
  }) {
    if (value != null) {
      return DateFormat(format).format(value);
    }
    return null;
  }

  static String? toDateTime(
    DateTime? value, {
    String format = ConstFormats.DATETIME_MMDDYYYY_12H,
  }) {
    if (value != null) {
      return DateFormat(format).format(value);
    }
    return null;
  }

  static String? toMonthYear(DateTime? value) {
    if (value != null) {
      final month = ConstFormats.DATE_MONTH_TEXT_FORMAT.format(value);
      return '$month-${value.year}';
    }
    return null;
  }

  // static String? format(
  //   String? input, {
  //   String inputFormat = ConstFormats.DATE_MMDDYYYY,
  //   String outputFormat = ConstFormats.DATE_MMDDYYYY,
  // }) {
  //   if (input == null || input.trim().isEmpty) return null;
  //   try {
  //     final parsed = DateFormat(inputFormat).parseStrict(input);
  //     return DateFormat(outputFormat).format(parsed);
  //   } catch (_) {
  //     return null; // invalid string
  //   }
  // }

  // static String? toDate(String? input, {String inputFormat = ConstFormats.DATE_MMDDYYYY}) {
  //   return format(input, inputFormat: inputFormat, outputFormat: ConstFormats.DATE_MMDDYYYY);
  // }

  // static String? toDateTime(String? input,
  //     {String inputFormat = ConstFormats.DATETIME_MMDDYYYY_12H}) {
  //   return format(input,
  //       inputFormat: inputFormat, outputFormat: ConstFormats.DATETIME_MMDDYYYY_12H);
  // }

  // static String? toMonthYear(String? input,
  //     {String inputFormat = ConstFormats.DATE_MMDDYYYY}) {
  //   if (input == null || input.trim().isEmpty) return null;
  //   try {
  //     final parsed = DateFormat(inputFormat).parseStrict(input);
  //     final month = ConstFormats.DATE_MONTH_TEXT_FORMAT.format(parsed);
  //     return '$month-${parsed.year}';
  //   } catch (_) {
  //     return null;
  //   }
  // }

  static String truncate(String? value, [int length = 15]) {
    if (value == null || value.isEmpty) return '';
    return value.length <= length ? value : '${value.substring(0, length)}...';
  }

  static String toLowercase(dynamic value) {
    return (value != null) ? value.toString().toLowerCase() : '';
  }

  static String toUpperCase(dynamic value) {
    return (value != null) ? value.toString().toUpperCase() : '';
  }

  static String stripHTML(String str) {
    return str.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static int randomIntFromInterval(int min, int max) {
    return min + (max - min + 1) * (DateTime.now().microsecond % 1000) ~/ 1000;
  }
}
