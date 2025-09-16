import 'package:flutter/material.dart';
import 'package:test_project/core/actions/auth_actions.dart';
import 'package:test_project/core/theme/app_colors.dart';

class ReusableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double height;
  final bool showLogout;

  const ReusableAppBar({
    Key? key,
    required this.title,
    this.height = kToolbarHeight,
    this.showLogout = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Image.asset('assets/images/meld-epLogo.png'),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.PRIMARY,
      actions: [
        if (showLogout)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // call the global logout helper:
              performLogout(
                context,
                onComplete: () {
                  // default behaviour: navigate to login (adjust route name)
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
