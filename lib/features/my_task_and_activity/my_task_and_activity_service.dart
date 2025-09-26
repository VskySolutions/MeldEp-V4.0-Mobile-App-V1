import 'package:dio/dio.dart';
import 'package:test_project/boot/network.dart';

class MyTaskAndActivityService {
  MyTaskAndActivityService._();
  static final MyTaskAndActivityService instance = MyTaskAndActivityService._();

  Future<dynamic> fetchTasks(Map<String, dynamic> payload) async {
    return await Network.authDio.post(
      '/project-activities/list',
      data: payload,
    );
  }

  Future<dynamic> fetchProjectNameIds() async {
    return await Network.authDio.get('/projects/dropdown/list');
  }

  Future<dynamic> fetchProjectModuleNameIds(String? projectId) async {
    final id = projectId ?? 'undefined';
    return await Network.authDio.get(
      '/project-modules/dropdown/list?ProjectId=$id',
    );
  }

  Future<dynamic> fetchEmployeeNameIds(String? siteId) async {
    final id = siteId ?? 'undefined';
    return await Network.authDio.get(
      '/employees/activedropdown/list?siteId=$id',
    );
  }

  Future<dynamic> fetchActivityName() async {
    return await Network.authDio.get(
      '/drop-downs-type/list?type=Project%20Activities',
    );
  }

  Future<dynamic> fetchActivityStatus() async {
    return await Network.authDio.get(
      '/drop-downs-type/list?type=Activity%20Status',
    );
  }

  Future<dynamic> fetchTaskStatus() async {
    return await Network.authDio.get(
      '/drop-downs-type/list?type=Task%20Status',
    );
  }

  Future<dynamic> getProjectActivityDetailsByIds(String? ids) async {
    return await Network.authDio.get(
      '/project-activities/project-activity-detailsbyids?ids=$ids',
    );
  }

  Future<dynamic> getProjectActivityDetails(String? id) async {
    return await Network.authDio.get('/project-activities/$id');
  }

  Future<dynamic> onSaveAndClose(Map<String, dynamic> payload) async {
    return await Network.authDio.post('/Timesheet', data: payload);
  }

  Future<dynamic> updateProjectActivity(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final formData = FormData.fromMap(payload);
    return await Network.authDio.put(
      '/project-activities/$id',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<dynamic> getTaskNoteDetails(String? id) async {
    return await Network.authDio.get(
      '/notes/?subModuleId=$id&type=project%20Activities',
    );
  }

  Future<dynamic> postUpdateTaskNote(Map<String, dynamic> payload) async {
    return await Network.authDio.post('/notes', data: payload);
  }

  Future<dynamic> deleteTaskNote(String? id) async {
    return await Network.authDio.delete('/notes/deletenote/?id=$id');
  }

  Future<dynamic> makeTaskStatusActiveInactive( String? id, bool? status) async {
    return await Network.authDio.put('/project-activities/$id/$status');
  }

  Future<dynamic> changeActivityStatus( Map<String, dynamic> payload) async {
    return await Network.authDio.put('/project-activities/updateTaskActivityStatus', data: payload);
  }
}
