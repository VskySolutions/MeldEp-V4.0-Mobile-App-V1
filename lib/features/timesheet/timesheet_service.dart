import 'package:dio/dio.dart';
import 'package:test_project/boot/network.dart';

class TimesheetService {
  TimesheetService._();
  static final TimesheetService instance = TimesheetService._();

  Future<dynamic> fetchTimesheets(Map<String, dynamic> payload) async {
    return await Network.authDio.post('/Timesheet/list', data: payload);
  }

  Future<dynamic> fetchEmployeeNameIds() async {
    return await Network.authDio.get(
      '/employees/activedropdown/list?siteId=undefined',
    );
  }

  Future<dynamic> fetchProjectNameIds() async {
    return await Network.authDio.get('/projects/dropdown/list');
  }

  Future<dynamic> fetchProjectModuleNameIds(String projectId) async {
    return await Network.authDio.get(
      '/project-modules/dropdown/list?ProjectId=$projectId',
    );
  }

  Future<dynamic> fetchProjectTasksNameIds(String projectId, String projectModuleId) async {
    return await Network.authDio.get(
      '/project-tasks/dropdown/list/$projectId/$projectModuleId/undefined',
    );
  }

  Future<dynamic> deleteTimesheet(String id) async {
    return await Network.authDio.delete('/Timesheet/$id');
  }

  Future<dynamic> fetchTimesheetById(String id) async {
    return await Network.authDio.get('/Timesheet/$id');
  }

  Future<dynamic> fetchProjectNameDropdownIds() async {
    return await Network.authDio.get(
      '/projects/dropdown/list?statuses=Open&statuses=New&statuses=In%20progress',
    );
  }

  Future<dynamic> fetchModuleNameIds(String projectId) async {
    return await Network.authDio.get(
      '/project-modules/dropdown/list?ProjectId=$projectId',
    );
  }

  Future<dynamic> fetchTaskNameIds(
    String projectId,
    String moduleId,
    String? employeeId,
  ) async {
    return await Network.authDio.get(
      '/project-tasks/dropdown/list/$projectId/$moduleId/$employeeId',
    );
  }

  Future<dynamic> fetchActivityNameIds(
    String projectId,
    String moduleId,
    String taskId,
    String date,
  ) async {
    return await Network.authDio.get(
      '/project-activities/dailytimesheetdropdown/list/$projectId/$moduleId/$taskId/$date',
    );
  }

  Future<Response> saveTimesheet(Map<String, dynamic> payload) async {
    return await Network.authDio.post('/Timesheet', data: payload);
  }

  Future<Response> updateTimesheet(
    String timesheetId,
    Map<String, dynamic> payload,
  ) async {
    return await Network.authDio.put('/Timesheet/$timesheetId', data: payload);
  }
}
