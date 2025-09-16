import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:test_project/core/constants/formats.dart';
import 'package:test_project/core/dialogs/confirmation_dialog.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/utils/validators.dart';
import 'package:test_project/core/widgets/input_field/custom_rich_quill_value.dart';
import 'package:test_project/core/widgets/snackbar/custom_snackbar.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_service.dart';
import 'package:test_project/states/model/projectDetailsByIdModel.dart';

class FillTimesheetScreen extends StatefulWidget {
  final String activityIds;
  final String? activityMins;
  const FillTimesheetScreen(this.activityIds,
      {super.key, this.activityMins = null});

  @override
  FillTimesheetScreenState createState() => FillTimesheetScreenState();
}

class FillTimesheetScreenState extends State<FillTimesheetScreen> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  // Data
  List<projectDetailsByIdModel> _projectList = <projectDetailsByIdModel>[];

  // Submission
  Map<String, dynamic> _submitActivityPayload = <String, dynamic>{};

  // Loading flags
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Date
  DateTime _selectedDate = DateTime.now();
  String? _dateError;
  final TextEditingController _dateController = TextEditingController();

  // Per-project controllers and errors
  final Map<String, TextEditingController> _activityDetailsControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _hoursControllers =
      <String, TextEditingController>{};
  final Map<String, String?> _activityDetailsErrors = <String, String?>{};
  final Map<String, String?> _hoursErrors = <String, String?>{};

  @override
  void initState() {
    super.initState();
    _fetchProjectActivityDetailsByIds(widget.activityIds);
    _dateController.text = _selectedDate.format();
  }

  @override
  void dispose() {
    _activityDetailsControllers.forEach(
      (key, controller) => controller.dispose(),
    );
    _hoursControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Validates a single field (activity or hours) for the given project id as the user types. [3][1]
  void _onFieldChanged(String projectId, String fieldType, String value) {
    setState(() {
      if (fieldType == 'activity') {
        _activityDetailsErrors[projectId] = Validators.validateDescription(
          value.trim(),
          fieldName: "Activity details",
        );
      } else {
        _hoursErrors[projectId] = Validators.validateHours(
          value.trim(),
          fieldName: "Activity hours",
        );
      }
    });
  }

  /// Saves timesheet lines and navigates back on success; performs validation and API submission. [3][1]
  Future<void> _onSaveAndClosePressed(BuildContext context) async {
    bool hasError = false;

    for (var p in _projectList) {
      final desc = _activityDetailsControllers[p.id]!.text.trim();
      final hrs = _hoursControllers[p.id]!.text.trim();

      _activityDetailsErrors[p.id] = Validators.validateDescription(
        desc,
        fieldName: "Activity details",
      );
      _hoursErrors[p.id] = Validators.validateHours(
        hrs,
        fieldName: "Activity hours",
      );

      if (_activityDetailsErrors[p.id] != null ||
          _hoursErrors[p.id] != null ||
          _dateError != null) {
        hasError = true;
      }
    }

    setState(() {});

    if (hasError) return;

    Fluttertoast.showToast(
      msg: "Submitting details.... Please wait",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    setState(() {
      _isSubmitting = true;
    });

    _buildSubmitActivityPayload();

    try {
      await MyTaskAndActivityService.instance.onSaveAndClose(
        _submitActivityPayload,
      );

      showCustomSnackBar(
        context,
        message: 'Timesheet submitted successfully!',
        durationSeconds: 2,
      );
      setState(() => _isSubmitting = false);
      context.pop(true);
    } catch (e) {
      showCustomSnackBar(
        context,
        message: 'Failed to submit timesheet',
        backgroundColor: AppColors.ERROR,
      );
      setState(() => _isSubmitting = false);
    }
  }

  /// Updates date error state when the user edits the date text field. [3][1]
  void _onDateChanged(String text) {
    setState(() {
      _dateError = Validators.validateDate(text, lastDate: DateTime.now());
    });
    if (_dateError == null) {
      final DateTime parsedDate = ConstFormats.DATE_FORMAT.parseStrict(text);
      _selectedDate = parsedDate;
    }
  }

  /// Opens a date picker and writes the chosen date back to the text field. [3][1]
  Future<void> _pickDate() async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formatted = picked.format();
      _dateController.text = formatted;
      _onDateChanged(formatted);
    }
  }

  /// Asks for navigation confirmation before leaving the screen. [3][1]
  Future<bool> _shouldGoBack(BuildContext context) async {
    final shouldNavigate = await showNavigationConfirmationDialog(context);
    return shouldNavigate ?? false;
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Fetches project/activity details for the provided ids and initializes controllers/errors. [3][1]
  Future<void> _fetchProjectActivityDetailsByIds(String ids) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await MyTaskAndActivityService.instance
          .getProjectActivityDetailsByIds(ids);
      final data = response.data;

      setState(() {
        _projectList = List<projectDetailsByIdModel>.from(
          data.map((json) => projectDetailsByIdModel.fromJson(json)),
        );

        for (var project in _projectList) {
          _activityDetailsControllers[project.id] = TextEditingController();
          if (widget.activityMins == null || widget.activityMins == 'null') {
            _hoursControllers[project.id] = TextEditingController();
          } else {
            _hoursControllers[project.id] =
                TextEditingController(text: widget.activityMins);
          }
          _activityDetailsErrors[project.id] = null;
          _hoursErrors[project.id] = null;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Builds the timesheet submission payload from the current controllers and selected date. [3][1]
  void _buildSubmitActivityPayload() {
    _submitActivityPayload.clear();

    final timesheetDateStr = _selectedDate.format();

    final timesheetLineModel = _projectList.asMap().entries.map((entry) {
      final project = entry.value;
      final description = _activityDetailsControllers[project.id]?.text ?? "";
      final hours =
          double.tryParse(_hoursControllers[project.id]?.text ?? "0") ?? 0.0;
      String guid = _generateGuid();

      print(timesheetDateStr);

      return {
        "name": project.name,
        "projectName": project.projectName,
        "projectModuleName": project.projectModuleName,
        "taskName": project.taskName,
        "estimateHours": project.estimateHours,
        "active": project.active,
        "deleted": project.deleted,
        "sortOrder": project.sortOrder,
        "targetMonth": project.targetMonth,
        "activitiesCount": project.activitiesCount,
        "assignedTo": {
          "active": project.assignedTo.active,
          "estimateHrs": project.assignedTo.estimateHrs,
          "person": {
            "firstName": project.assignedTo.person.firstName,
            "lastName": project.assignedTo.person.lastName,
            "isCustomer": project.assignedTo.person.isCustomer,
            "personSiteFlag": project.assignedTo.person.personSiteFlag,
            "customProperties": {},
          },
          "employeeTypeModel": [],
          "employeeStatusModel": [],
          "employeeDepartmentModel": [],
          "employeeDesignationModel": [],
          "employeeOrgLocationModel": [],
          "employeeClientLocationModel": [],
          "employeeDepartment": [],
          "employeeDesignation": [],
          "employeeStatuses": [],
          "employeeType": [],
          "employeeOrgLocation": [],
          "employeeClientLocation": [],
          "id": project.assignedTo.id,
          "customProperties": {},
        },
        "project": {
          "year": project.project.year,
          "name": project.project.name,
          "active": project.project.active,
          "editing": false,
          "projectNotesCount": project.project.projectNotesCount,
          "completedTaskCount": project.project.completedTaskCount,
          "totalTaskCount": project.project.totalTaskCount,
          "projectSwimlaneCount": project.project.projectSwimlaneCount,
          "completedIssueCount": project.project.completedIssueCount,
          "totalIssueCount": project.project.totalIssueCount,
          "completedRequirementCount":
              project.project.completedRequirementCount,
          "totalRequirementCount": project.project.totalRequirementCount,
          "totalTaskEstimateHours": project.project.totalTaskEstimateHours,
          "totalActivityHours": project.project.totalActivityHours,
          "totalModuleCount": project.project.totalModuleCount,
          "isTemplate": project.project.isTemplate,
          "isPinned": project.project.isPinned,
          "sortOrder": project.project.sortOrder,
          "createdOnUtc": project.project.createdOnUtc,
          "deleted": project.project.deleted,
          "projectActivities": [],
          "projectEmployeeMappings": [],
          "projectFileList": [],
          "projectTasks": [],
          "storyBoards": [],
          "projectModules": [],
          "projectsMessages": [],
          "projectUserMappings": [],
          "projectTags": [],
          "id": project.project.id,
          "customProperties": {},
        },
        "task": {
          "projectTaskNumber": project.task.projectTaskNumber,
          "name": project.task.name,
          "estimateTime": project.task.estimateTime,
          "active": project.task.active,
          "isMoved": project.task.isMoved,
          "sortOrder": project.task.sortOrder,
          "activitiesCount": project.task.activitiesCount,
          "isDuplicate": project.task.isDuplicate,
          "projectNotesCount": project.task.projectNotesCount,
          "projectTaskNotesCount": project.task.projectTaskNotesCount,
          "createdOnUtc": project.task.createdOnUtc,
          "totalTimesheetEstHours": project.task.totalTimesheetEstHours,
          "projectActivityModel": [],
          "projectActivities": [],
          "projectTaskStatusLog": [],
          "projectTaskFilesList": [],
          "projectTask_Tags": [],
          "id": project.task.id,
          "customProperties": {},
        },
        "projectModule": {
          "name": project.projectModule.name,
          "projectModuleNumber": project.projectModule.projectModuleNumber,
          "active": project.projectModule.active,
          "sortOrder": project.projectModule.sortOrder,
          "isDuplicate": project.projectModule.isDuplicate,
          "isMoved": project.projectModule.isMoved,
          "projectTasksCount": project.projectModule.projectTasksCount,
          "createdOnUtc": project.projectModule.createdOnUtc,
          "projectModuleNotesCount":
              project.projectModule.projectModuleNotesCount,
          "projectActivities": [],
          "projectTasks": [],
          "projectModuleDocumentModel": [],
          "projectTaskModel": [],
          "projectModuleFilesList": [],
          "id": project.projectModule.id,
          "customProperties": {},
        },
        "projectActivities": [],
        "projectActivityLines": [],
        "projectEmployeeMappings": [],
        "projectTaskActivityFilesList": [],
        "projectTasks": [],
        "storyBoards": [],
        "id": guid,
        "customProperties": {},
        "editing": false,
        "projectId": project.project.id,
        "projectModuleId": project.projectModule.id,
        "projectTaskId": project.task.id,
        "projectActivityId": project.id,
        "description": description,
        "moduleName": project.projectModuleName,
        "projectActivityName": project.name,
        "rowCounter": 2,
        "isMyTaskActivity": true,
        "flag": "Edit",
        "hours": hours,
      };
    }).toList();

    _submitActivityPayload = {
      "timesheetDate": timesheetDateStr,
      "timesheetLineModel": timesheetLineModel,
    };
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Utilities
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Generates a new GUID string for a timesheet line id. [3][1]
  String _generateGuid() {
    var uuid = Uuid();
    return uuid.v4();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldNavigate = await _shouldGoBack(context);
        if (shouldNavigate) {
          return true;
        } else
          return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              bool shouldNavigate = await _shouldGoBack(context);
              shouldNavigate ? context.pop() : null;
            },
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            'Fill Timesheet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.PRIMARY,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.PRIMARY))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: SizedBox()),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _dateController,
                              keyboardType: TextInputType.datetime,
                              decoration: InputDecoration(
                                labelText: 'Timesheet Date',
                                hintText: ConstFormats.DATE_MMDDYYYY,
                                errorText: _dateError,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_month),
                                  onPressed: _pickDate,
                                ),
                              ),
                              onChanged: _onDateChanged,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ..._projectList.map(
                        (project) => Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      project.projectName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      Icons.double_arrow,
                                      color: Colors.grey[600],
                                      size: 18,
                                    ),
                                    Text(project.projectModuleName),
                                    Icon(
                                      Icons.double_arrow,
                                      color: Colors.grey[600],
                                      size: 18,
                                    ),
                                    Text(project.taskName),
                                    if ((project.name).isNotEmpty) ...[
                                      Text(
                                        '(${project.name})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Divider(),
                                InputDecorator(
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: "Activity Details",
                                    border: const OutlineInputBorder(),
                                    hintText: "Enter activity details here",
                                    errorText:
                                        _activityDetailsErrors[project.id],
                                    contentPadding: const EdgeInsets.all(8),
                                  ),
                                  child: HtmlEmailEditor(
                                    onChanged: (html) {
                                      _activityDetailsControllers[project.id]
                                          ?.text = html;
                                      _onFieldChanged(
                                          project.id, 'activity', html);
                                    },
                                    initialHtml:
                                        _activityDetailsControllers[project.id]
                                            ?.text,
                                    editorHeight: 140,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _hoursControllers[project.id],
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Hours",
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    hintText: "hh.mm",
                                    errorText: _hoursErrors[project.id],
                                  ),
                                  onChanged: (val) =>
                                      _onFieldChanged(project.id, 'hours', val),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  heroTag: "save",
                  onPressed: _isLoading || _isSubmitting
                      ? null
                      : () => _onSaveAndClosePressed(context),
                  backgroundColor: AppColors.PRIMARY,
                  child: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Icon(Icons.save, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 56,
              width: 56,
              child: FloatingActionButton(
                heroTag: "back",
                onPressed: () async {
                  bool shouldNavigate = await _shouldGoBack(context);
                  if (shouldNavigate) context.pop();
                },
                backgroundColor: AppColors.PRIMARY,
                child: Icon(Icons.arrow_back, color: Colors.white),
                tooltip: "Back",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
