import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/core/theme/app_colors.dart';

/// Simple logout confirmation dialog that matches your existing dialog style.
/// onLogout is called after the dialog is dismissed.
Future<void> showLogoutConfirmationDialog(
  BuildContext context, {
  String title = 'Logout',
  String description = 'Are you sure you want to logout?',
  required VoidCallback onLogout,
}) {
  return showDialog(
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
                    onTap: () => ctx.pop(),
                    child: const Icon(Icons.close, color: AppColors.PRIMARY),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ctx.pop(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.PRIMARY),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // close dialog first (same pattern as your delete dialog)
                      ctx.pop();
                      onLogout();
                    },
                    child: const Text(
                      "Logout",
                      style: TextStyle(color: AppColors.ERROR),
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
