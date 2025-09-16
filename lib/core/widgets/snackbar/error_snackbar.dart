import 'package:flutter/material.dart';
import 'package:test_project/core/theme/app_colors.dart';

class ErrorSnackBar {
  static void show(
    BuildContext context, {
    String? message,
    Color backgroundColor = AppColors.ERROR,
    int durationSeconds = 4,
  }) {
    final snackBar = SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message ?? "Something went wrong!",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.fixed,
      duration: Duration(seconds: durationSeconds),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
