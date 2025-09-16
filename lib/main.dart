import 'package:flutter/material.dart';
import 'package:test_project/app.dart';
import 'package:test_project/boot/auth.dart';
import 'package:test_project/boot/network.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  await dotenv.load(fileName: 'config/.env.$flavor');

  // Initialize authentication and network
  await AuthService.instance.init();
  await Network.init();

  runApp(const MyApp());
}
