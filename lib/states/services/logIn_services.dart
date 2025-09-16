import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:test_project/states/model/LogInCred.dart';

class LoginServices {
  final String username;
  final String password;

  LoginServices({ required this.username, required this.password});

  Future<LogInCred> getAll() async {
    const url = 'https://dev4-0api.meldep.com/auth/login';
    final uri = Uri.parse(url);

    Map<String, String> body = {
      'username' : username,
      'password' : password,
    };

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    final Response = await http.post(
      uri,
      body: json.encode(body),
      headers: headers
    );

    if (Response.statusCode == 200){
      final json = jsonDecode(Response.body);
      return LogInCred.fromJson(json);
    }
    throw 'Something went wrong';
  }
}
