import 'package:dio/dio.dart';
import 'package:test_project/boot/network.dart';

class OrgManagementService {
  OrgManagementService._();
  static final OrgManagementService instance = OrgManagementService._();

  Future<Response> fetchLeaveDropdownStatus() async {
    return await Network.authDio.get(
      '/drop-downs-type/list?type=Leave%20Status',
    );
  }

  Future<Response> fetchLeaveDropdownCategory() async {
    return await Network.authDio.get(
      '/drop-downs-type/list?type=Leave%20Category',
    );
  }

  Future<Response> fetchLeaveData(Map<String, dynamic> payload) async {
    return await Network.authDio.post(
      '/employee-leave/list',
      data: payload,
    );
  }

    Future<Response> applyLeave(FormData formData) async {
    return await Network.authDio.post(
      '/employee-leave',
      data: formData,
    );
  }

  Future<Response> fetchCategories() async {
    return await Network.authDio.get(
      '/drop-downs-type/list?type=Leave%20Category',
    );
  }
  
  Future<Response> fetchLeaveBalanceDetails() async {
    return await Network.authDio.get(
      '/employee-leave/leavebalancedetails/undefined',
    );
  }
}
