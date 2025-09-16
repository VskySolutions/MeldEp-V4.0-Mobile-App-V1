import 'package:flutter/material.dart';
import 'package:test_project/core/theme/app_colors.dart';

class SuccessSnackBar {
  static void show(
    BuildContext context, {
    String? message,
    Color backgroundColor = AppColors.SUCCESS,
    int durationSeconds = 3,
  }) {
    final snackBar = SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message ?? "Action completed successfully!",
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
