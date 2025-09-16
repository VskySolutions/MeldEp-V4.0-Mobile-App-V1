import 'package:test_project/boot/network.dart';

class AuthServices {
  AuthServices._();
  static final AuthServices instance = AuthServices._();

  Future<dynamic> login(Map<String, dynamic> loginData) async {
    return await Network.anonDio.post('/auth/login', data: loginData);
  }
}
