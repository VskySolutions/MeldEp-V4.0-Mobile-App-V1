import 'package:intl/intl.dart';

class ConstFormats {
  ConstFormats._();

  // Dates (patterns)
  static const String DATE_MMDDYYYY = 'MM/dd/yyyy'; // 08/08/2025
  static const String DATE_YYYYMMDD = 'yyyy-MM-dd'; // 2025-08-08
  static const String DATE_MONTH_TEXT = 'MMMM'; // August

  // DateFormat instances
  static final DateFormat DATE_FORMAT = DateFormat(DATE_MMDDYYYY);
  static final DateFormat DATE_FORMAT_YMD = DateFormat(DATE_YYYYMMDD);
  static final DateFormat DATE_MONTH_TEXT_FORMAT = DateFormat(DATE_MONTH_TEXT);

  // Times (patterns)
  static const String TIME_12H = 'hh:mm a'; // 02:35 PM
  static const String TIME_24H = 'HH:mm'; // 14:35

  // TimeFormat instances
  static final DateFormat TIME_12H_FORMAT = DateFormat(TIME_12H);
  static final DateFormat TIME_24H_FORMAT = DateFormat(TIME_24H);

  // Date + time (patterns)
  static const String DATETIME_MMDDYYYY_12H = 'MM/dd/yyyy hh:mm a';
  static const String DATETIME_MMDDYYYY_12HS = 'MM/dd/yyyy hh:mm:ss a';
  static const String DATETIME_ISO = "yyyy-MM-dd'T'HH:mm:ss";

  // Date + time format instances
  static final DateFormat DATETIME_MMDDYYYY_12H_FORMAT = DateFormat(
    DATETIME_MMDDYYYY_12H,
  );
  static final DateFormat DATETIME_MMDDYYYY_12HS_FORMAT = DateFormat(
    DATETIME_MMDDYYYY_12HS,
  );
  static final DateFormat DATETIME_ISO_FORMAT = DateFormat(DATETIME_ISO);
}
