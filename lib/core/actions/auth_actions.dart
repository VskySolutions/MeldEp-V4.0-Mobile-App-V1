import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_project/boot/auth.dart';
import 'package:test_project/core/dialogs/logout_confirmation_dialog.dart';

/// Call this from anywhere with a BuildContext (e.g. AppBar logout button).
/// onComplete can be used to navigate to login screen / clear state after successful logout.
Future<void> performLogout(
  BuildContext context, {
  VoidCallback? onComplete,
}) async {
  // show dialog; the onLogout callback triggers the real logout logic
  await showLogoutConfirmationDialog(
    context,
    title: 'Logout',
    description: 'Are you sure you want to logout?',
    onLogout: () {
      // fire-and-forget the async logout task so the dialog flow isn't blocked
      _logoutAndHandle(context, onComplete: onComplete);
    },
  );
}

Future<void> _logoutAndHandle(
  BuildContext context, {
  VoidCallback? onComplete,
}) async {
  try {
    await AuthService.instance.logout();
    // callback to allow navigation/clearing state
    onComplete?.call();
  } catch (e) {
    // Fluttertoast.showToast(
    //   msg: "An error occurred while logging out",
    //   toastLength: Toast.LENGTH_SHORT,
    //   gravity: ToastGravity.BOTTOM,
    // );
  }
}
