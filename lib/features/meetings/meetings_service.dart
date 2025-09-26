// lib/features/org_management/services/org_management_service.dart

import 'package:dio/dio.dart';
import 'package:test_project/boot/network.dart';

class TimeBuddyService {
  TimeBuddyService._();
  static final TimeBuddyService instance = TimeBuddyService._();

  Future<Response> fetchCalendarData(Map<String, dynamic> payload) async {
    return await Network.authDio.post(
      '/calendar/list',
      data: payload,
    );
  }

  Future<Response<Map<String, dynamic>>> fetchTimesheetLineByMeetingUid(
    String meetingUid,
  ) async {
    return await Network.authDio.get<Map<String, dynamic>>(
      '/timesheet/get-timesheet-line-by-meetingUId/$meetingUid',
    );
  }

    Future<dynamic> deleteTimesheetLine(String id) async {
    return await Network.authDio.delete('/Timesheet/line/$id');
  }
}
