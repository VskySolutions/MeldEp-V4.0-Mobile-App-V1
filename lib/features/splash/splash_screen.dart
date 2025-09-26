// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:test_project/core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Center(
        child: Image.asset(
          'assets/icon/vskyLogo.png',
          width: 150, // Adjust size as needed
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback in case the image fails to load
            return const Icon(
              Icons.apps_rounded,
              size: 100,
              color: AppColors.PRIMARY,
            );
          },
        ),
      ),
    );
  }
}