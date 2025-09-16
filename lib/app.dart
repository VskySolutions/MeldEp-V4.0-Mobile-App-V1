import 'package:flutter/material.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'core/routes/app_router.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;

    return MaterialApp.router(
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        primaryColor: AppColors.PRIMARY,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.PRIMARY,
        ),
        useMaterial3: true, // optional
      ),
      // theme: ThemeData(...),
    );
  }
}
