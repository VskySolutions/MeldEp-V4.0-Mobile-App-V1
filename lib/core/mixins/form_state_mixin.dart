import 'package:flutter/material.dart';
import 'package:test_project/core/dialogs/confirmation_dialog.dart';

/// Mixin to handle form state and navigation confirmation
mixin FormStateMixin<T extends StatefulWidget> on State<T> {
  bool _hasUnsavedChanges = false;

  /// Set whether the form has unsaved changes
  void setFormChanged(bool changed) {
    if (mounted) {
      setState(() {
        _hasUnsavedChanges = changed;
      });
    }
  }

  /// Check if form has unsaved changes
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Handle navigation attempt with confirmation dialog
  /// Returns true if navigation should proceed, false if cancelled
  Future<bool> handleNavigationAttempt({
    String title = 'Confirmation',
    String message = 'Are you sure you want to leave without saving?',
    String cancelText = 'No',
    String confirmText = 'Yes',
  }) async {
    if (!_hasUnsavedChanges) return true;

    final shouldNavigate = await showNavigationConfirmationDialog(context);
    return shouldNavigate ?? false;
  }

  /// Reset form changes
  void resetFormChanges() {
    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
      });
    }
  }

  /// Handle back button press with confirmation
  Future<void> handleBackButton() async {
    if (await handleNavigationAttempt()) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Handle custom navigation with confirmation
  Future<void> handleCustomNavigation({
    required VoidCallback onNavigate,
    String? title,
    String? message,
  }) async {
    final shouldNavigate = await handleNavigationAttempt(
      title: title ?? 'Confirmation',
      message: message ?? 'Are you sure you want to leave without saving?',
    );
    
    if (shouldNavigate && mounted) {
      onNavigate();
    }
  }
}