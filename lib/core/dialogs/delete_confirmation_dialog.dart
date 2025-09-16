import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/core/theme/app_colors.dart';

Future<void> showDeleteConfirmationDialog(
  BuildContext context, {
    required String title,
    required String description,
    String? subDescription,
    required VoidCallback onDelete,
  }
){
  return showDialog(
    context: context, 
    builder: (ctx){
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
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
              const SizedBox(height: 8),

              // Sub description (e.g., date)
              if(subDescription != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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
                    onPressed: () => ctx.pop(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.PRIMARY),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ctx.pop();
                      onDelete();
                    },
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: AppColors.ERROR),
                    ),
                  ),
                ],
              ),

            ],
          ),
          ),
      );
    }
    );
}