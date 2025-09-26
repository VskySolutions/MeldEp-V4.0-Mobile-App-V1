import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import 'package:test_project/core/dialogs/confirmation_dialog.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/validators.dart';
import 'package:test_project/core/widgets/custom_snackbar.dart';
import 'package:test_project/core/widgets/dropdown/activity_status_field_dropdown.dart';
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

  String? _selectedActivityStatusId;
  String? _descriptionInitialHtml;

  // Loading flags
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Data
  ProjectActivityDetailsModel? _activityDetails;
  List<Map<String, String>> activityStatusDropdown = [];

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
    _initializeData();
  }

  void _initializeData() async {
    setState(() => _isLoading = true);
    await _fetchActivityDetails();
    await _fetchActivityStatus();
    setState(() => _isLoading = false);
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
          _descriptionInitialHtml = _activityDetails?.description ?? '';
        });
      }
    } catch (e) {
      debugPrint('Fetch activity details error: $e');
    }
  }

  /// Validates and submits changes; shows feedback and navigates back on success.
  Future<void> _updateActivityDetails(BuildContext context) async {

    final payload = {
      'name': _activityDetails?.name ?? '',
      'projectId': _activityDetails?.projectId ?? '',
      'projectModuleId': _activityDetails?.projectModuleId ?? '',
      'taskId': _activityDetails?.taskId ?? '',
      'startDateStr': '',
      'endDateStr': '',
      'activityStatusId': _selectedActivityStatusId ?? _activityDetails?.activityStatus.id ?? '',
      'assignedToId': _activityDetails?.assignedToId ?? '',
      'estimateHours': _estimateHoursController.text,
      'description': _descriptionController.text,
    };

    try {
      final response = await MyTaskAndActivityService.instance
          .updateProjectActivity(widget.id, payload);

      if (response.statusCode == 204) {
        showCustomSnackBar(
          context,
          message: 'Activity updated successfully',
          durationSeconds: 2,
        );
        context.pop(true);
      } else {
        showCustomSnackBar(
          context,
          message: 'Failed to update task',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e) {
      debugPrint('Update activity error: $e');
      showCustomSnackBar(
        context,
        message: 'Error updating task',
        backgroundColor: AppColors.ERROR,
      );
    }
  }

  Future<void> _fetchActivityStatus() async {
    try {
      final response =
          await MyTaskAndActivityService.instance.fetchActivityStatus();
      final List<dynamic> dataList = response.data;

      final fetchedActivityStatus = dataList
          .map((json) => ActivityStatusModel.fromJson(json))
          .where((m) => m.name != "Close")
          .toList();

      setState(() {
        activityStatusDropdown = fetchedActivityStatus
            .map((module) => {"id": module.id, "name": module.name})
            .toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<bool> _updateActivityStatus(BuildContext context) async {
    String? selectedActivityStatusName = activityStatusDropdown.firstWhere(
      (element) => element["id"] == _selectedActivityStatusId,
      orElse: () => {},
    )["name"];

    if (_selectedActivityStatusId == null || _activityDetails?.id == null || selectedActivityStatusName == null) return false;

    final Map<String, dynamic> payload = {
      "activityIds": [_activityDetails?.id],
      "activityStatusId": _selectedActivityStatusId,
    };

    try {
      final response =
          await MyTaskAndActivityService.instance.changeActivityStatus(payload);
      if (response.statusCode == 204) {
        return true;
      } else {
        showCustomSnackBar(
          context,
          message: 'Failed to change activity status',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e) {
      debugPrint('Change activity status error: $e');
      showCustomSnackBar(
        context,
        message: 'Error changing activity status',
        backgroundColor: AppColors.ERROR,
      );
    }
    finally {
      return false;
    }
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Validate conditions and update activity details and activity status.
  void _onSavePressed(BuildContext context) async {
    if (_estimateHoursError != null) return;
    String? selectedActivityStatusName = activityStatusDropdown.firstWhere(
      (element) => element["id"] == _selectedActivityStatusId,
      orElse: () => {},
    )["name"];
    if (selectedActivityStatusName != null &&
        selectedActivityStatusName.toLowerCase() == 'open' &&
        _descriptionController.text.isEmpty) {
      showCustomSnackBar(
        context,
        message: 'Description is required when status is Open',
        backgroundColor: AppColors.ERROR,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    Fluttertoast.showToast(
      msg: 'Submitting.... Please wait',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    try {
      await _updateActivityDetails(context);
    } catch (e) {
      debugPrint('Error in onSavePressed: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

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
                    ActivityStatusFieldDropdown(
                      items: activityStatusDropdown,
                      currentId: _activityDetails!.activityStatus.id,
                      currentName:
                          _activityDetails!.activityStatus.dropDownValue,
                      labelText: 'Status',
                      enabled: true,
                      onChanged: (id) {
                        setState(() => _selectedActivityStatusId = id);
                      },
                    ),

                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Activity Details',
                        border: OutlineInputBorder(),
                        hintText: 'Enter activity details',
                        isDense: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                      child: HtmlEditorInputField(
                        editorHeight: 180,
                        initialHtml: _descriptionInitialHtml,
                        onChanged: (html) {
                          setState(() {});
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
                      : () => _onSavePressed(context),
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

class ActivityStatusModel {
  final String id;
  final String name;

  ActivityStatusModel({required this.id, required this.name});

  factory ActivityStatusModel.fromJson(Map<String, dynamic> json) {
    return ActivityStatusModel(
      id: json['id'] ?? '',
      name: json['dropdownValue'] ?? '',
    );
  }
}
