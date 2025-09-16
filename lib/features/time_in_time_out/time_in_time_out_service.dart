import 'package:dio/dio.dart';
import 'package:test_project/boot/network.dart';

class TimeInTimeOutService {
  TimeInTimeOutService._();
  static final TimeInTimeOutService instance = TimeInTimeOutService._();

  Future<Response> fetchEmployees() async {
    return await Network.authDio.get(
      '/employees/activedropdown/list?siteId=undefined',
    );
  }

  Future<Response> fetchShifts() async {
    return await Network.authDio.get(
      '/drop-downs-type/list?type=Employee%20Shift',
    );
  }

  Future<Response> fetchTimeData(Map<String, dynamic> payload) async {
    return await Network.authDio.post('/time-in-time-out/list', data: payload);
  }

  Future<Response> fetchTimeInTimeOutDetails(String timeInKeyGuid) async {
    return await Network.authDio.get(
      '/time-in-time-out/details/$timeInKeyGuid',
    );
  }
}
