import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/utils/validators.dart';
import 'package:test_project/features/home/home_service.dart';

/// Bottom sheet to add a movement register entry.
class MovementRegisterBottomSheet extends StatefulWidget {
  const MovementRegisterBottomSheet({super.key});

  @override
  State<MovementRegisterBottomSheet> createState() =>
      _MovementRegisterBottomSheetState();
}

class _MovementRegisterBottomSheetState extends State<MovementRegisterBottomSheet> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Disposes the text controller to free resources.
  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Sends a new movement register message to the API and shows feedback.
  Future<void> _addMovementRegister(String message) async {
    setState(() => _isSubmitting = true);

    final String? employeeId = await LocalStorage.getEmployeeId();
    final MovementRegisterRequest request = MovementRegisterRequest(
      momentRegisterDetailsId: null,
      employeeId: employeeId,
      dateStr: DateTime.now().format(),
      message: message,
      date: null,
    );

    try {
      final response =
          await HomeService.instance.addMovementRegister(request.toJson());
      if (response.statusCode == 200) {
        if (!mounted) return;
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to movement register successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed with status code ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.ERROR,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Validates the form and triggers submission when valid.
  void _onSubmitPressed() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    final text = _descriptionController.text.trim();
    _addMovementRegister(text);
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGrabHandle(),
              const SizedBox(height: 12),
              _buildTitleBar(context),
              const SizedBox(height: 10),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI Helpers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Builds the top grab handle for the bottom sheet.
  Widget _buildGrabHandle() {
    return Center(
      child: Container(
        height: 5,
        width: 45,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Builds the title bar with close action.
  Widget _buildTitleBar(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Add Movement Register',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  /// Builds the description input field with validation.
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      validator: (value) => Validators.validateDescription(
        (value ?? '').trim(),
        fieldName: 'Mov. Register Description',
      ),
      onFieldSubmitted: (_) => _onSubmitPressed(),
      decoration: const InputDecoration(
        labelText: 'Mov. Register Description',
        hintText: 'Add movement description.',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  /// Builds the save floating button aligned to the end.
  Widget _buildSaveButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'saveMovementRegister',
          backgroundColor: AppColors.PRIMARY,
          onPressed: _isSubmitting ? null : _onSubmitPressed,
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save, color: Colors.white),
        ),
      ],
    );
  }
}

/// --------------------------------------------------------------------------------------------------------------------------------------------------
/// Model
/// --------------------------------------------------------------------------------------------------------------------------------------------------

/// Request payload model for creating a movement register entry.
class MovementRegisterRequest {
  MovementRegisterRequest({
    required this.momentRegisterDetailsId,
    required this.employeeId,
    required this.dateStr,
    required this.message,
    required this.date,
  });

  final String? momentRegisterDetailsId;
  final String? employeeId;
  final String dateStr;
  final String message;
  final String? date;

  /// Converts the request to a JSON-serializable map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'momentRegisterDetailsId': momentRegisterDetailsId,
        'employeeId': employeeId,
        'dateStr': dateStr,
        'message': message,
        'date': date,
      };
}
