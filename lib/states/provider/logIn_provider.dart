// import 'package:flutter/material.dart';
// import 'package:test_project/states/model/LogInCred.dart';
// import 'package:test_project/states/services/logIn_services.dart';

// class LoginProvider extends ChangeNotifier {
//   String username = '';
//   String password = '';
//   late LoginServices _services;

//   bool isLoading = false;

//   late LogInCred _logInCred;
//   LogInCred get logInCred => _logInCred;

//   // LoginProvider(){
//   //   _services = LoginServices(username: username, password: password);
//   // }

//   void updateCredentials(String username, String password) {
//     this.username = username;
//     this.password = password;
//     _services = LoginServices(username: username, password: password);
//   }

//   Future<void> getAllLoginCred() async {
//     isLoading = true;
//     notifyListeners();

//     final response = await _services.getAll();

//     print(response.createdAt);
//     print(response.email);
//     print(response.employeeId);

//     _logInCred = response;
//     isLoading = false;
//     notifyListeners();
//   }
// }