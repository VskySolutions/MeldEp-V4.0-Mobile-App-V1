class CalendarListResponse {
  final bool editing;
  final List<CalendarEventDto> data;
  final int total;
  final Map<String, dynamic>? customProperties;

  CalendarListResponse({
    required this.editing,
    required this.data,
    required this.total,
    this.customProperties,
  });

  factory CalendarListResponse.fromJson(Map<String, dynamic> json) {
    return CalendarListResponse(
      editing: json['editing'] as bool? ?? false,
      data: (json['data'] as List<dynamic>? ?? const [])
          .map((e) => CalendarEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      customProperties: json['customProperties'] as Map<String, dynamic>?,
    );
  }
}

class CalendarEventDto {
  final String? uid;
  final String? subject;
  final String? start;
  final String? end;
  final String? startDateStr;
  final String? endDateStr;
  final String? startTime;
  final String? endTime;
  final String? description;
  final String? location;
  final String? startDateTimeCalendar;
  final String? endDateTimeCalendar;
  final String? startTimeCalendar;
  final String? endTimeCalendar;
  final Map<String, dynamic>? customProperties;

  CalendarEventDto({
    this.uid,
    this.subject,
    this.start,
    this.end,
    this.startDateStr,
    this.endDateStr,
    this.startTime,
    this.endTime,
    this.description,
    this.location,
    this.startDateTimeCalendar,
    this.endDateTimeCalendar,
    this.startTimeCalendar,
    this.endTimeCalendar,
    this.customProperties,
  });

  factory CalendarEventDto.fromJson(Map<String, dynamic> json) {
    return CalendarEventDto(
      uid: json['uid'] as String?,
      subject: json['subject'] as String?,
      start: json['start'] as String?,
      end: json['end'] as String?,
      startDateStr: json['startDateStr'] as String?,
      endDateStr: json['endDateStr'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startDateTimeCalendar: json['startDateTimeCalendar'] as String?,
      endDateTimeCalendar: json['endDateTimeCalendar'] as String?,
      startTimeCalendar: json['startTimeCalendar'] as String?,
      endTimeCalendar: json['endTimeCalendar'] as String?,
      customProperties: json['customProperties'] as Map<String, dynamic>?,
    );
  }
}
