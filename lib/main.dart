import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:test_project/app.dart';
import 'package:test_project/boot/auth.dart';
import 'package:test_project/boot/network.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_project/core/services/notification_services.dart';

import 'firebase_options_dev.dart' as dev;
import 'firebase_options.dart' as prod;


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final options = flavor == 'prod'
      ? prod.DefaultFirebaseOptions.currentPlatform
      : dev.DefaultFirebaseOptions.currentPlatform;
  // final options = dev.DefaultFirebaseOptions.currentPlatform;

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(options: options);
  
  await dotenv.load(fileName: 'config/.env.$flavor');

  await AuthService.instance.init();
  await Network.init();

  await NotificationServices.instance.init();

  runApp(const MyApp());
}

