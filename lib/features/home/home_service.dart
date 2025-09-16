import 'package:dio/dio.dart';
import 'package:test_project/boot/network.dart';

class HomeService {
  HomeService._();
  static final HomeService instance = HomeService._();

  Future<dynamic> getMovementRegisterList(Map<String, dynamic> payload) async {
    return await Network.authDio.post('/movementRegister/list', data: payload);
  }

  Future<Response> getTimeInTimeOutDetails(String? timeInKeyGuid) async {
    return await Network.authDio.get(
      '/time-in-time-out/details/$timeInKeyGuid',
    );
  }

  Future<Response> postTimeIn(Map<String, dynamic> payload) async {
    return await Network.authDio.post('/time-in-time-out', data: payload);
  }

  Future<Response> putTimeOut(
    String timeInKeyGuid,
    Map<String, dynamic> payload,
  ) async {
    return await Network.authDio.put(
      '/time-in-time-out/$timeInKeyGuid',
      data: payload,
    );
  }

  Future<Response> putBreak(
    String timeInKeyGuid,
    Map<String, dynamic> payload,
  ) async {
    return await Network.authDio.put(
      '/time-in-time-out/$timeInKeyGuid/addUpdateBreak',
      data: payload,
    );
  }

  Future<Response> addMovementRegister(Map<String, dynamic> payload) async {
    return await Network.authDio.post(
      '/movementRegister/add-movement-register',
      data: payload,
    );
  }
}
