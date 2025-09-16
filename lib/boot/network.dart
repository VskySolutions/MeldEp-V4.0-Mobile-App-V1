import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/core/services/local_storage.dart';

class Network {
  static late Dio authDio;
  static late Dio anonDio;

  static Future<void> init() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

    final baseOptions = BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => true, 
    );

    anonDio = Dio(baseOptions);

    authDio = Dio(baseOptions);

    final token = await LocalStorage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      authDio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}