import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:test_project/app.dart';
import 'package:test_project/boot/auth.dart';
import 'package:test_project/boot/network.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_project/core/services/notification_services.dart';

import 'firebase_options_dev.dart' as dev;
import 'firebase_options_uat.dart' as uat;
import 'firebase_options.dart' as prod;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  // Determine Firebase options based on flavor
  final FirebaseOptions options;
  switch (flavor) {
    case 'prod':
      options = prod.DefaultFirebaseOptions.currentPlatform;
      break;
    case 'uat':
      options = uat.DefaultFirebaseOptions.currentPlatform;
      break;
    case 'dev':
    default:
      options = dev.DefaultFirebaseOptions.currentPlatform;
      break;
  }

  // Initialize Firebase FIRST before any Firebase services
  await Firebase.initializeApp(options: options);

  // Register background handler AFTER Firebase initialization
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Load environment variables (all flavors need this)
  await dotenv.load(fileName: 'config/.env.$flavor');

  // Initialize core services (all flavors need these)
  await AuthService.instance.init();
  await Network.init();

  // Initialize notification services (now works for all flavors)
  await NotificationServices.instance.init();

  runApp(const MyApp());
}
