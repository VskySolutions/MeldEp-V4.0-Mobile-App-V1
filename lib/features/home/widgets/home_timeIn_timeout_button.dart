import 'package:flutter/material.dart';
import 'package:test_project/core/theme/app_colors.dart';

class HomeTimeInTimeOutButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final Color primaryColor;
  final Color disabledColor;
  final String? displayText;
  final int? badgeCount;
  final bool showBadge;

  const HomeTimeInTimeOutButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.primaryColor = AppColors.PRIMARY,
    this.disabledColor = Colors.grey,
    this.displayText,
    this.badgeCount,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2), // Added vertical margin around the entire button
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isDisabled ? null : onTap,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 80,
                maxWidth: 120,
              ),
              height: 60,
              // margin: const EdgeInsets.symmetric(vertical: 8), // Existing vertical margin for the button container
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDisabled ? disabledColor : primaryColor,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isLoading
                              ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDisabled ? disabledColor : primaryColor,
                                )
                              : Icon(
                                  icon,
                                  size: 28,
                                  color: isDisabled ? disabledColor : primaryColor,
                                ),
                          if (displayText != null && displayText!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                displayText!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (showBadge && badgeCount != null && badgeCount! > 0)
                    Positioned(
                      top: 0,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.ERROR,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}