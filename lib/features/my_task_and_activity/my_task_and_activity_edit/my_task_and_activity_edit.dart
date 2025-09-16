import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import 'package:test_project/core/dialogs/confirmation_dialog.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/validators.dart';
import 'package:test_project/core/widgets/custom_snackbar.dart';
import 'package:test_project/core/widgets/input_field/custom_rich_quill_value.dart';
import 'package:test_project/features/my_task_and_activity/model/project_activity_details_model.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_service.dart';

/// Screen to edit a single project activity’s estimate and description.
class MyTaskAndActivityEditScreen extends StatefulWidget {
  const MyTaskAndActivityEditScreen({super.key, required this.id});

  /// Project activity identifier to edit.
  final String id;

  @override
  State<MyTaskAndActivityEditScreen> createState() =>
      _ProjectActivityEditScreenState();
}

class _ProjectActivityEditScreenState
    extends State<MyTaskAndActivityEditScreen> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  ProjectActivityDetailsModel? _activityDetails;

  // Loading flags
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Controllers
  final TextEditingController _estimateHoursController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Validation errors
  String? _estimateHoursError;

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchActivityDetails();
  }

  @override
  void dispose() {
    _estimateHoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Fetches activity details by id and populates form fields.
  Future<void> _fetchActivityDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await MyTaskAndActivityService.instance
          .getProjectActivityDetails(widget.id);

      if (response.statusCode == 200) {
        setState(() {
          _activityDetails =
              ProjectActivityDetailsModel.fromJson(response.data);
          _estimateHoursController.text =
              (_activityDetails?.estimateHours ?? '').toString();
          _descriptionController.text = _activityDetails?.description ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Fetch activity details error: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Validates and submits changes; shows feedback and navigates back on success.
  Future<void> _saveChanges(BuildContext context) async {
    if (_estimateHoursError != null) return;

    setState(() => _isSubmitting = true);
    Fluttertoast.showToast(
      msg: 'Submitting.... Please wait',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    final payload = {
      'name': _activityDetails?.name ?? '',
      'projectId': _activityDetails?.projectId ?? '',
      'projectModuleId': _activityDetails?.projectModuleId ?? '',
      'taskId': _activityDetails?.taskId ?? '',
      'startDateStr': '',
      'endDateStr': '',
      'assignedToId': _activityDetails?.assignedToId ?? '',
      'estimateHours': _estimateHoursController.text,
      'description': _descriptionController.text,
    };

    try {
      final response = await MyTaskAndActivityService.instance
          .updateProjectActivity(widget.id, payload);

      if (response.statusCode == 204) {
        setState(() => _isSubmitting = false);
        showCustomSnackBar(
          context,
          message: 'Task updated successfully',
          durationSeconds: 2,
        );
        context.pop(true);
      } else {
        setState(() => _isSubmitting = false);
        showCustomSnackBar(
          context,
          message: 'Failed to update task',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('Update activity error: $e');
      showCustomSnackBar(
        context,
        message: 'Error updating task',
        backgroundColor: AppColors.ERROR,
      );
    }
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Validates estimate hours as the user types.
  void _onEstimateHoursChanged(String value) {
    setState(() {
      _estimateHoursError = Validators.validateHours(
        value.trim(),
        fieldName: 'Estimated hours',
      );
    });
  }

  /// Prompts for confirmation before navigating away from the screen.
  Future<bool> _shouldGoBack(BuildContext context) async {
    final shouldNavigate = await showNavigationConfirmationDialog(context);
    return shouldNavigate ?? false;
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Builds the edit form UI for the activity.
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldNavigate = await _shouldGoBack(context);
        return shouldNavigate ? true : false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              final shouldNavigate = await _shouldGoBack(context);
              if (shouldNavigate) context.pop();
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: const Text(
            'Task Assignment',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.PRIMARY,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumbs
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Project - ${_activityDetails?.projectName ?? '-'} > ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.PRIMARY,
                            ),
                          ),
                          Text(
                            'Module - ${_activityDetails?.projectModuleName ?? '-'} > ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.PRIMARY,
                            ),
                          ),
                          Text(
                            'Task - ${_activityDetails?.taskName ?? '-'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.PRIMARY,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Activity Owner (read-only)
                    InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        labelText: 'Activity Owner',
                      ),
                      child: Text(
                        '${_activityDetails?.assignedTo.person.firstName ?? ''} '
                        '${_activityDetails?.assignedTo.person.lastName ?? ''}',
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Activity Name (read-only)
                    InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        labelText: 'Activity Name',
                      ),
                      child: Text(_activityDetails?.name ?? '-'),
                    ),

                    const SizedBox(height: 12),

                    // Estimate Hours
                    TextFormField(
                      controller: _estimateHoursController,
                      decoration: InputDecoration(
                        labelText: 'Estimate Hours*',
                        border: const OutlineInputBorder(),
                        errorText: _estimateHoursError,
                        hintText: 'Enter estimate hours',
                        isDense: true,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: _onEstimateHoursChanged,
                    ),

                    const SizedBox(height: 12),

                    // Activity Details editor
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Activity Details',
                        border: OutlineInputBorder(),
                        hintText: 'Enter activity details',
                        isDense: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                      child: HtmlEmailEditor(
                        editorHeight: 180,
                        initialHtml: _descriptionController.text,
                        onChanged: (html) {
                          _descriptionController.text = html;
                        },
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Opacity(
              opacity: _isLoading || _isSubmitting ? 0.6 : 1,
              child: SizedBox(
                height: 56,
                width: 56,
                child: FloatingActionButton(
                  onPressed: _isLoading || _isSubmitting
                      ? null
                      : () => _saveChanges(context),
                  backgroundColor: AppColors.PRIMARY,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: _isSubmitting ? 0.6 : 1,
              child: SizedBox(
                height: 56,
                width: 56,
                child: FloatingActionButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final shouldNavigate = await _shouldGoBack(context);
                          if (shouldNavigate) context.pop();
                        },
                  heroTag: 'back',
                  backgroundColor: AppColors.PRIMARY,
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
