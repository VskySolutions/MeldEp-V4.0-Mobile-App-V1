import 'package:flutter/foundation.dart';
import 'package:test_project/boot/network.dart';
import 'package:test_project/core/services/local_storage.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final instance = AuthService._();

  String? _token;
  bool _rememberMe = false;
  bool _tempRememberMe = false;
  bool get isLoggedIn => _token != null && (_rememberMe || _tempRememberMe);

  Future<void> init() async {
    _token = await LocalStorage.getAuthToken();
    _rememberMe = await LocalStorage.getRememberMe() ?? false;
    if(!_rememberMe) await LocalStorage.clearAll();
    notifyListeners();
  }

  Future<void> login(String token, bool rememberMe) async {
    _token = token;
    if(rememberMe){
      _rememberMe = rememberMe;
    } else {_tempRememberMe = true;}
    await LocalStorage.setRememberMe(rememberMe);
    await LocalStorage.setAuthToken(token);
    await Network.init();
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    await LocalStorage.clearAll();
    notifyListeners();
  }

  String? get token => _token;
}