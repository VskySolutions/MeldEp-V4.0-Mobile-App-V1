import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/core/theme/app_colors.dart';

Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? cancelText,
  String? confirmText,
  Color? confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ctx.pop(false),
                    child: const Icon(Icons.close, color: AppColors.PRIMARY),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Message
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              
              // Buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ctx.pop(false),
                    child: Text(
                      cancelText ?? "No",
                      style: const TextStyle(color: AppColors.PRIMARY),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ctx.pop(true),
                    child: Text(
                      confirmText ?? "Yes",
                      style: TextStyle(
                        color: confirmColor ?? AppColors.PRIMARY,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


Future<bool?> showNavigationConfirmationDialog(BuildContext context) {
  return showConfirmationDialog(
    context,
    title: "Confirmation",
    message: "Are you sure you want to leave without saving?",
    cancelText: "No",
    confirmText: "Yes",
    confirmColor: AppColors.ERROR,
  );
}