import 'package:flutter/material.dart';
import '../constants/formats.dart';
import '../theme/app_colors.dart';
import 'filters.dart';

/// ----------------------
/// String Extensions
/// ----------------------
extension StringExtensions on String {
  String toLowercase() => Filters.toLowercase(this);
  String toUppercase() => Filters.toUpperCase(this);
  String truncate([int length = 15]) => Filters.truncate(this, length);
  String stripHtml() => Filters.stripHTML(this);
  String toInitials() => Filters.toInitials(this);

  bool get isValidEmail {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(this);
  }
}

/// ----------------------
/// DateTime Extensions
/// ----------------------
extension DateTimeExtensions on DateTime {
  String format([String pattern = ConstFormats.DATE_MMDDYYYY]) =>
      Filters.toDate(this, format: pattern) ?? '';

  String formatDateTime([String pattern = ConstFormats.DATETIME_MMDDYYYY_12H]) =>
      Filters.toDateTime(this, format: pattern) ?? '';

  String get format12H => Filters.toDateTime(this, format: ConstFormats.TIME_12H) ?? '';

  String get format24H => Filters.toDateTime(this, format: ConstFormats.TIME_24H) ?? '';

  String get monthYear => Filters.toMonthYear(this) ?? '';
}

/// ----------------------
/// Num Extensions
/// ----------------------
extension NumExtensions on num {
  String toCurrency({int decimals = 2}) =>
      Filters.toCurrency(this, decimals) ?? '';

  String toNumeric({int decimals = 2}) =>
      Filters.toNumeric(this, decimals) ?? '';

  String toPrice({int decimals = 2}) =>
      Filters.toPrice(this, decimals) ?? '';

  String toPercentage({int decimals = 0}) =>
      Filters.toPercentage(this, decimals) ?? '';
}

