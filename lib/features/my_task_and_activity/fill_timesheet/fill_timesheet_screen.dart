import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/widgets/draggable_scrollable_sheet/show_task_detail_bottom_sheet.dart';
import 'package:test_project/core/widgets/input_field/custom_type_ahead_field.dart';
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

List<Map<String, String>> toItems(List<TimesheetDropdownValuesModel> src) {
  return src
      .map((r) => {
            'id': (r.id ?? '').toString(),
            'name': (r.name ?? '').toString(),
            'description': (r.description ?? '').toString(),
          })
      .toList();
}

class FillTimesheetScreenState extends State<FillTimesheetScreen> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  // Data
  List<projectDetailsByIdModel> _projectList = <projectDetailsByIdModel>[];
  List<TimesheetDropdownValuesModel> _projectDropdownList =
      <TimesheetDropdownValuesModel>[];

  // Timesheet line cards
  List<TimesheetCardsModel> _timesheetCardsList = <TimesheetCardsModel>[];

  // Submission
  Map<String, dynamic> _submitActivityPayload = <String, dynamic>{};

  // Loading flags
  bool _isLoading = true;
  bool _isInitialLoading = true;
  bool _isSubmitting = false;

  // Date
  DateTime _selectedDate = DateTime.now();
  String? _dateError;
  final TextEditingController _dateController = TextEditingController();

  // Per-project controllers and errors
  // final Map<String, TextEditingController> _activityDetailsControllers =
  //     <String, TextEditingController>{};
  // final Map<String, TextEditingController> _hoursControllers =
  //     <String, TextEditingController>{};
  // final Map<String, String?> _activityDetailsInitial = <String, String?>{};
  // final Map<String, String?> _activityDetailsErrors = <String, String?>{};
  // final Map<String, String?> _hoursErrors = <String, String?>{};

  @override
  void initState() {
    super.initState();
    _initialLoadData();
  }

  Future<void> _initialLoadData() async {
    setState(() {
      _isInitialLoading = true;
    });
    await _fetchProjectActivityDetailsByIds(widget.activityIds);
    await _loadProjectOptions();
    _dateController.text = _selectedDate.format();
    setState(() {
      _isInitialLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Saves timesheet lines and navigates back on success; performs validation and API submission. [3][1]
  Future<void> _onSaveAndClosePressed(BuildContext context) async {
    bool hasError = false;

    // for (var p in _projectList) {
    //   final desc = _activityDetailsControllers[p.id]!.text.trim();
    //   final hrs = _hoursControllers[p.id]!.text.trim();

    //   _activityDetailsErrors[p.id] = Validators.validateDescription(
    //     desc,
    //     fieldName: "Activity details",
    //   );
    //   _hoursErrors[p.id] = Validators.validateHours(
    //     hrs,
    //     fieldName: "Activity hours",
    //   );

    //   if (_activityDetailsErrors[p.id] != null ||
    //       _hoursErrors[p.id] != null ||
    //       _dateError != null) {
    //     hasError = true;
    //   }
    // }

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
  Future<void> _onPickDatePressed() async {
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

  /// Adds a new empty line card with fresh controllers.
  void _onAddLinePressed() {
    setState(() {
      final newControllers = FieldControllerModel(
        projectDropdownController: TextEditingController(text: ''),
        moduleDropdownController: TextEditingController(text: ''),
        TaskDropdownController: TextEditingController(text: ''),
        activityDropdownController: TextEditingController(text: ''),
        activityDetailsFieldController: TextEditingController(text: ''),
        hoursFieldController: TextEditingController(text: ''),
      );

      _timesheetCardsList.add(
        TimesheetCardsModel(
          inputFieldsController: newControllers,
          projectModulesDropdown: [],
          projectTaskDropdown: [],
          projectActivityDropdown: [],
        ),
      );
    });
  }

  /// Removes a line card; marks server line as deleted when applicable.
  void _onRemoveLinePressed(int index, String? linerId) {
    if (_timesheetCardsList.length <= 1) {
      Fluttertoast.showToast(
        msg: "You must have at least one timesheet entry.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.ERROR,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _timesheetCardsList.removeAt(index);
      if (_projectList.length > index) _projectList.removeAt(index);
    });
  }

  /// Validates all cards and returns true when the form is ready to submit.
  Future<bool> _validateTimesheetForm(BuildContext context) async {
    bool hasError = false;

    for (var t in _timesheetCardsList) {
      final desc = t.inputFieldsController?.activityDetailsFieldController?.text
              .trim() ??
          '';
      final hrs =
          t.inputFieldsController?.hoursFieldController?.text.trim() ?? '';

      // t.detailsError = Validators.validateDescription(
      //   desc,
      //   fieldName: "Activity details",
      // );
      t.hoursError = Validators.validateHours(hrs, fieldName: "Hours");

      t.projectError = Validators.validateText(
        t.inputFieldsController?.projectDropdownController?.text,
        fieldName: "Project name",
      );
      t.moduleError = Validators.validateText(
        t.inputFieldsController?.moduleDropdownController?.text,
        fieldName: "Module name",
      );
      t.taskError = Validators.validateText(
        t.inputFieldsController?.TaskDropdownController?.text,
        fieldName: "Task name",
      );
      t.activityError = Validators.validateText(
        t.inputFieldsController?.activityDropdownController?.text,
        fieldName: "Activity name",
      );

      if (t.detailsError != null ||
          t.hoursError != null ||
          t.projectError != null ||
          t.moduleError != null ||
          t.taskError != null ||
          t.activityError != null ||
          _dateError != null) {
        hasError = true;
      }
    }

    setState(() {});

    return !hasError;
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

        final List<TimesheetCardsModel> fetchedCards = [];

        for (final rawLine in _projectList) {
          fetchedCards.add(TimesheetCardsModel.fromTimesheetLine(rawLine));
        }

        _timesheetCardsList = fetchedCards;

        // for (var project in _projectList) {
        //   if (widget.activityMins == null || widget.activityMins == 'null') {
        //     _hoursControllers[project.id] = TextEditingController();
        //   } else {
        //     _hoursControllers[project.id] =
        //         TextEditingController(text: widget.activityMins);
        //   }
        //   _activityDetailsErrors[project.id] = null;
        //   _hoursErrors[project.id] = null;
        // }
      });
      for (int i = 0; i < _timesheetCardsList.length; i++) {
        await _loadModuleOptionsForProject(i);
        await _loadTaskOptionsForModule(i);
        await _loadActivityOptionsForTask(i);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Builds the timesheet submission payload from the current controllers and selected date. [3][1]
  void _buildSubmitActivityPayload() {
    _submitActivityPayload.clear();

    final timesheetDateStr = _selectedDate.format();

    final timesheetLineModel = _timesheetCardsList.asMap().entries.map((entry) {
      final i = entry.key;
      final card = entry.value;
      final isProjectListHaveData = i < _projectList.length;

      final description =
          card.inputFieldsController?.activityDetailsFieldController?.text ??
              "";
      final hoursStr =
          card.inputFieldsController?.hoursFieldController?.text ?? "0";
      final hours = double.tryParse(hoursStr) ?? 0.0;

      String guid = _generateGuid();
      if (isProjectListHaveData) {
        final project = _projectList[i];
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
      } else {
        return {
          "id": guid,
          "projectId": card.projectId,
          "projectModuleId": card.moduleId,
          "projectTaskId": card.taskId,
          "projectActivityId": card.activityId,
          "hours": hours,
          "description": description,
          "deleted": false,
          "isMyTaskActivity": false,
          "rowCounter": 1,
          "projectName": "",
          "moduleName": "",
          "taskName": "",
          "projectActivityName": "",
        };
      }
    }).toList();

    _submitActivityPayload = {
      "timesheetDate": timesheetDateStr,
      "timesheetLineModel": timesheetLineModel,
    };
  }

  /// Loads project names for the first dropdown (id + label shaping).
  Future<void> _loadProjectOptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await MyTaskAndActivityService.instance.fetchProjectNameDropdownIds();
      final List<dynamic> dataList = response.data;

      final fetchedProjectNames =
          dataList.map((json) => ProjectNamesModel.fromJson(json)).toList();

      setState(() {
        _projectDropdownList = fetchedProjectNames.map((project) {
          return TimesheetDropdownValuesModel(
            id: project.id,
            name: "${project.name} (${project.totalModuleCount})",
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('fetchProjectNameIds error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Loads modules for the selected project and maps them into dropdown items.
  Future<void> _loadModuleOptionsForProject(int index) async {
    final card = _timesheetCardsList[index];
    setState(() => card.isLoadingModules = true);

    try {
      final projectId = _timesheetCardsList[index].projectId;
      if (projectId.isEmpty) {
        _timesheetCardsList[index].projectModulesDropdown = [];
        return;
      }
      final response =
          await MyTaskAndActivityService.instance.fetchModuleNameIds(
        projectId,
      );

      final List<dynamic> dataList = response.data;
      final fetchedModules =
          dataList.map((json) => ModuleNamesModel.fromJson(json)).toList();

      setState(() {
        _timesheetCardsList[index].projectModulesDropdown = fetchedModules.map((
          project,
        ) {
          return TimesheetDropdownValuesModel(
            id: project.id,
            name: "${project.name} (${project.totalTaskCount})",
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('fetchModuleNameIds error: $e');
    } finally {
      setState(() => card.isLoadingModules = false);
    }
  }

  /// Loads tasks for the selected project+module and maps them into dropdown items.
  Future<void> _loadTaskOptionsForModule(int index) async {
    final card = _timesheetCardsList[index];
    setState(() => card.isLoadingTasks = true);

    try {
      final projectId = _timesheetCardsList[index].projectId;
      final moduleId = _timesheetCardsList[index].moduleId;
      if (projectId.isEmpty || moduleId.isEmpty) {
        _timesheetCardsList[index].projectTaskDropdown = [];
        return;
      }

      final employeeId = await LocalStorage.getEmployeeId();

      final response = await MyTaskAndActivityService.instance.fetchTaskNameIds(
        projectId,
        moduleId,
        employeeId,
      );

      final List<dynamic> dataList = response.data;
      final fetchedTasks =
          dataList.map((json) => TaskNamesModel.fromJson(json)).toList();

      setState(() {
        _timesheetCardsList[index].projectTaskDropdown =
            fetchedTasks.map((project) {
          return TimesheetDropdownValuesModel(
            id: project.id,
            name: "${project.name} (${project.activitiesCount})",
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('fetchTaskNameIds error: $e');
    } finally {
      setState(() => card.isLoadingTasks = false);
    }
  }

  /// Loads activities for the selected project+module+task and maps them into dropdown items.
  Future<void> _loadActivityOptionsForTask(int index) async {
    final card = _timesheetCardsList[index];
    setState(() => card.isLoadingActivities = true);

    try {
      final projectId = _timesheetCardsList[index].projectId;
      final moduleId = _timesheetCardsList[index].moduleId;
      final taskId = _timesheetCardsList[index].taskId;
      if (projectId.isEmpty || moduleId.isEmpty || taskId.isEmpty) {
        _timesheetCardsList[index].projectActivityDropdown = [];
        return;
      }
      final date =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final response =
          await MyTaskAndActivityService.instance.fetchActivityNameIds(
        projectId,
        moduleId,
        taskId,
        date,
      );

      final List<dynamic> dataList = response.data;
      final fetchedActivities =
          dataList.map((json) => ActivityNamesModel.fromJson(json)).toList();

      setState(() {
        _timesheetCardsList[index].projectActivityDropdown =
            fetchedActivities.map((
          project,
        ) {
          return TimesheetDropdownValuesModel(
              id: project.id,
              name: "${project.name} (${project.estimateHours})",
              description: project.description);
        }).toList();
      });
    } catch (e) {
      debugPrint('fetchActivityNameIds error: $e');
    } finally {
      setState(() => card.isLoadingActivities = false);
    }
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
        body: Column(
          children: [
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
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
                          onPressed: _onPickDatePressed,
                        ),
                      ),
                      onChanged: _onDateChanged,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(color: AppColors.PRIMARY))
                  : ListView.builder(
                      itemCount: _timesheetCardsList.length,
                      itemBuilder: (context, index) {
                        var card = _timesheetCardsList[index];
                        var cardInputFieldController =
                            _timesheetCardsList[index].inputFieldsController;
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Timesheet Liner',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Spacer(),
                                    IconButton(
                                      onPressed: () =>
                                          _onRemoveLinePressed(index, card.id),
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.ERROR,
                                      ),
                                    ),
                                  ],
                                ),
                                // ===================== PROJECT FIELD =====================
                                CustomTypeAheadField(
                                  items: toItems(_projectDropdownList),
                                  enabled: card.isDropdownEnabled,
                                  selectedId: (card.projectId.isEmpty)
                                      ? null
                                      : card.projectId,
                                  selectedValue: card.inputFieldsController
                                      ?.projectDropdownController?.text,
                                  label: 'Project',
                                  errorText: card.projectError,
                                  suggestionsController: card.typeahead.project,
                                  isLoading: false,
                                  onSelectedItem: (item) {
                                    card
                                        .inputFieldsController
                                        ?.projectDropdownController
                                        ?.text = item?['name'] ?? '';
                                  },
                                  onChanged: (id) async {
                                    setState(() {
                                      card.projectId = id ?? '';
                                      card.moduleId = '';
                                      card.taskId = '';
                                      card.activityId = '';
                                      card.projectModulesDropdown = [];
                                      card.projectTaskDropdown = [];
                                      card.projectActivityDropdown = [];
                                      card.moduleError = null;
                                      card.taskError = null;
                                      card.activityError = null;
                                      card.inputFieldsController
                                          ?.moduleDropdownController?.text = '';
                                      card.inputFieldsController
                                          ?.TaskDropdownController?.text = '';
                                      card
                                          .inputFieldsController
                                          ?.activityDropdownController
                                          ?.text = '';
                                      card.isLoadingModules = true;
                                    });
                                    await _loadModuleOptionsForProject(index);
                                    setState(
                                        () => card.isLoadingModules = false);
                                    card.typeahead.module.refresh();
                                  },
                                  onCleared: () {
                                    setState(() {
                                      card.projectId = '';
                                      card.moduleId = '';
                                      card.taskId = '';
                                      card.activityId = '';
                                      card.projectModulesDropdown = [];
                                      card.projectTaskDropdown = [];
                                      card.projectActivityDropdown = [];
                                      card
                                          .inputFieldsController
                                          ?.projectDropdownController
                                          ?.text = '';
                                      card.inputFieldsController
                                          ?.moduleDropdownController?.text = '';
                                      card.inputFieldsController
                                          ?.TaskDropdownController?.text = '';
                                      card
                                          .inputFieldsController
                                          ?.activityDropdownController
                                          ?.text = '';
                                    });
                                    card.typeahead.module.refresh();
                                    card.typeahead.activity.refresh();
                                    card.typeahead.task.refresh();
                                  },
                                ),
                                const SizedBox(height: 10),
                                // ===================== MODULE FIELD =====================
                                CustomTypeAheadField(
                                  items: toItems(card.projectModulesDropdown),
                                  enabled: card.isDropdownEnabled,
                                  selectedId: (card.moduleId.isEmpty)
                                      ? null
                                      : card.moduleId,
                                  selectedValue: card.inputFieldsController
                                      ?.moduleDropdownController?.text,
                                  label: 'Module',
                                  errorText: card.moduleError,
                                  suggestionsController: card.typeahead.module,
                                  isLoading: card.isLoadingModules,
                                  onOpen: () async {
                                    if (card.projectModulesDropdown.isEmpty &&
                                        card.projectId.isNotEmpty) {
                                      setState(
                                          () => card.isLoadingModules = true);
                                      await _loadModuleOptionsForProject(index);
                                      setState(
                                          () => card.isLoadingModules = false);
                                    }
                                  },
                                  onSelectedItem: (item) {
                                    card
                                        .inputFieldsController
                                        ?.moduleDropdownController
                                        ?.text = item?['name'] ?? '';
                                  },
                                  onChanged: (id) async {
                                    setState(() {
                                      card.moduleId = id ?? '';
                                      card.taskId = '';
                                      card.activityId = '';
                                      card.projectTaskDropdown = [];
                                      card.projectActivityDropdown = [];
                                      card.taskError = null;
                                      card.activityError = null;
                                      card.inputFieldsController
                                          ?.TaskDropdownController?.text = '';
                                      card
                                          .inputFieldsController
                                          ?.activityDropdownController
                                          ?.text = '';
                                      card.isLoadingTasks =
                                          (id ?? '').isNotEmpty;
                                    });
                                    if ((id ?? '').isNotEmpty) {
                                      await _loadTaskOptionsForModule(index);
                                    }
                                    setState(() => card.isLoadingTasks = false);
                                    card.typeahead.task.refresh();
                                    card.typeahead.activity.refresh();
                                  },
                                  onCleared: () {
                                    setState(() {
                                      card.moduleId = '';
                                    });
                                    card.typeahead.task.refresh();
                                    card.typeahead.activity.refresh();
                                  },
                                ),
                                const SizedBox(height: 10),
                                // ===================== TASK FIELD =====================
                                Row(
                                  children: [
                                    Expanded(
                                        child: CustomTypeAheadField(
                                      items: toItems(card.projectTaskDropdown),
                                      enabled: card.isDropdownEnabled,
                                      selectedId: (card.taskId.isEmpty)
                                          ? null
                                          : card.taskId,
                                      selectedValue: card.inputFieldsController
                                          ?.TaskDropdownController?.text,
                                      label: 'Task',
                                      errorText: card.taskError,
                                      suggestionsController:
                                          card.typeahead.task,
                                      isLoading: card.isLoadingTasks,
                                      onOpen: () async {
                                        if (card.projectTaskDropdown.isEmpty &&
                                            card.moduleId.isNotEmpty) {
                                          setState(
                                              () => card.isLoadingTasks = true);
                                          await _loadTaskOptionsForModule(
                                              index);
                                          setState(() =>
                                              card.isLoadingTasks = false);
                                        }
                                      },
                                      onSelectedItem: (item) {
                                        card
                                            .inputFieldsController
                                            ?.TaskDropdownController
                                            ?.text = item?['name'] ?? '';
                                      },
                                      onChanged: (id) async {
                                        setState(() {
                                          card.taskId = id ?? '';
                                          card.activityId = '';
                                          card.projectActivityDropdown = [];
                                          card.activityError = null;
                                          card
                                              .inputFieldsController
                                              ?.activityDropdownController
                                              ?.text = '';
                                          card.isLoadingActivities =
                                              (id ?? '').isNotEmpty;
                                        });
                                        if ((id ?? '').isNotEmpty) {
                                          await _loadActivityOptionsForTask(
                                              index);
                                        }
                                        setState(() =>
                                            card.isLoadingActivities = false);
                                        card.typeahead.activity.refresh();
                                      },
                                      onCleared: () {
                                        setState(() {
                                          card.taskId = '';
                                          card.activityId = '';
                                          card.projectActivityDropdown = [];
                                          card
                                              .inputFieldsController
                                              ?.TaskDropdownController
                                              ?.text = '';
                                          card
                                              .inputFieldsController
                                              ?.activityDropdownController
                                              ?.text = '';
                                        });
                                        card.typeahead.activity.refresh();
                                      },
                                    )),
                                    if (card.taskId != null &&
                                        card.taskId.isNotEmpty)
                                      IconButton(
                                          onPressed: () =>
                                              showTaskDetailBottomSheet(context,
                                                  id: card.taskId),
                                          icon: Icon(Icons.copy))
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // ===================== ACTIVITY FIELD =====================
                                CustomTypeAheadField(
                                  items: toItems(card.projectActivityDropdown),
                                  moreInfoDesc:
                                      card.projectActivityDropdown.length >
                                              index
                                          ? card.projectActivityDropdown[index]
                                              .description
                                          : null,
                                  enabled: card.isDropdownEnabled,
                                  selectedId: (card.activityId.isEmpty)
                                      ? null
                                      : card.activityId,
                                  selectedValue: card.inputFieldsController
                                      ?.activityDropdownController?.text,
                                  label: 'Activity (Est. Hrs)',
                                  errorText: card.activityError,
                                  suggestionsController:
                                      card.typeahead.activity,
                                  isLoading: card.isLoadingActivities,
                                  onOpen: () async {
                                    if (card.projectActivityDropdown.isEmpty &&
                                        card.taskId.isNotEmpty) {
                                      setState(() =>
                                          card.isLoadingActivities = true);
                                      await _loadActivityOptionsForTask(index);
                                      setState(() =>
                                          card.isLoadingActivities = false);
                                    }
                                  },
                                  onSelectedItem: (item) {
                                    card
                                        .inputFieldsController
                                        ?.activityDropdownController
                                        ?.text = item?['name'] ?? '';
                                  },
                                  onChanged: (id) {
                                    setState(() => card.activityId = id ?? '');
                                  },
                                  onCleared: () {
                                    setState(() {
                                      card.activityId = '';
                                      card
                                          .inputFieldsController
                                          ?.activityDropdownController
                                          ?.text = '';
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InputDecorator(
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        labelText: "Activity Details",
                                        hintText: "Enter activity details here",
                                        errorText: card.detailsError,
                                        contentPadding: const EdgeInsets.all(8),
                                      ),
                                      child: HtmlEditorInputField(
                                        showLessOptions: true,
                                        initialHtml: card.activityDetails,
                                        editorHeight: 140,
                                        onChanged: (html) {
                                          cardInputFieldController
                                              ?.activityDetailsFieldController
                                              ?.text = html;
                                          setState(() {
                                            card.detailsError =
                                                Validators.validateDescription(
                                              html.trim(),
                                              fieldName: "Activity details",
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: cardInputFieldController
                                          ?.hoursFieldController,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: "Hours",
                                        hintText: "Enter Hours here",
                                        errorText: card.hoursError,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          card.hoursError =
                                              Validators.validateHours(
                                            value.trim(),
                                            fieldName: "Hours",
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Opacity(
              opacity: _isInitialLoading || _isSubmitting ? 0.5 : 1.0,
              child: FloatingActionButton(
                onPressed: _isInitialLoading || _isSubmitting
                    ? null
                    : _onAddLinePressed,
                heroTag: "addCard",
                backgroundColor: AppColors.PRIMARY,
                child: Icon(Icons.add, color: Colors.white),
                tooltip: "Add Card",
              ),
            ),
            SizedBox(height: 12),
            Opacity(
              opacity: _isInitialLoading || _isSubmitting ? 0.6 : 1.0,
              child: FloatingActionButton(
                heroTag: "saveTimesheet",
                onPressed: _isInitialLoading || _isSubmitting
                    ? null
                    : () async {
                        bool response = await _validateTimesheetForm(context);
                        if (response) {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Text("Submit Timesheet"),
                                content: Text(
                                  "Are you sure you want to submit your timesheet?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => dialogContext.pop(),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _isLoading || _isSubmitting
                                        ? null
                                        : () async {
                                            dialogContext.pop();
                                            _onSaveAndClosePressed(context);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.PRIMARY,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.black,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            "Submit",
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                backgroundColor: AppColors.PRIMARY,
                child: _isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.save, color: Colors.white),
              ),
            ),
            SizedBox(height: 12),
            Opacity(
              opacity: 1.0,
              child: FloatingActionButton(
                onPressed: () async {
                  bool shouldNavigate = await _shouldGoBack(context);
                  shouldNavigate ? context.pop() : null;
                },
                heroTag: "back",
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

/// -----------------------------------------------------------------------------
/// Model
/// -----------------------------------------------------------------------------

class TimesheetCardsModel {
  FieldControllerModel? inputFieldsController;
  List<TimesheetDropdownValuesModel> projectModulesDropdown;
  List<TimesheetDropdownValuesModel> projectTaskDropdown;
  List<TimesheetDropdownValuesModel> projectActivityDropdown;
  String projectId;
  String moduleId;
  String taskId;
  String activityId;
  String activityDetails;
  String activityHours;
  String? projectError;
  String? moduleError;
  String? taskError;
  String? activityError;
  String? detailsError;
  String? hoursError;
  String? id;
  bool isDropdownEnabled;

  final TypeaheadControllerGroup typeahead;

  bool isLoadingModules;
  bool isLoadingTasks;
  bool isLoadingActivities;

  TimesheetCardsModel({
    this.inputFieldsController,
    this.projectModulesDropdown = const [],
    this.projectTaskDropdown = const [],
    this.projectActivityDropdown = const [],
    this.projectId = '',
    this.moduleId = '',
    this.taskId = '',
    this.activityId = '',
    this.activityDetails = '',
    this.activityHours = '',
    this.id,
    this.isDropdownEnabled = true,
    TypeaheadControllerGroup? typeahead,
    this.isLoadingModules = false,
    this.isLoadingTasks = false,
    this.isLoadingActivities = false,
  }) : typeahead = typeahead ?? TypeaheadControllerGroup();

  factory TimesheetCardsModel.fromTimesheetLine(projectDetailsByIdModel json) {
    final controllers = FieldControllerModel(
      projectDropdownController: TextEditingController(text: json.project.name),
      moduleDropdownController:
          TextEditingController(text: json.projectModule.name),
      TaskDropdownController: TextEditingController(text: json.task.name),
      activityDropdownController: TextEditingController(text: json.name),
      activityDetailsFieldController: TextEditingController(
        text: json.description,
      ),
      hoursFieldController: TextEditingController(
        text: "",
      ),
    );

    return TimesheetCardsModel(
        inputFieldsController: controllers,
        projectModulesDropdown: [],
        projectTaskDropdown: [],
        projectActivityDropdown: [],
        projectId: json.project.id,
        moduleId: json.projectModule.id,
        taskId: json.task.id,
        activityId: json.id,
        activityDetails: json.description,
        activityHours: '',
        id: json.id,
        isDropdownEnabled: false);
  }
}

class TimesheetDropdownValuesModel {
  String? id;
  String? name;
  String? description;

  TimesheetDropdownValuesModel({this.id, this.name, this.description});
}

class FieldControllerModel {
  TextEditingController? projectDropdownController;
  TextEditingController? moduleDropdownController;
  TextEditingController? TaskDropdownController;
  TextEditingController? activityDropdownController;
  TextEditingController? activityDetailsFieldController;
  TextEditingController? hoursFieldController;

  FieldControllerModel({
    TextEditingController? projectDropdownController,
    TextEditingController? moduleDropdownController,
    TextEditingController? TaskDropdownController,
    TextEditingController? activityDropdownController,
    TextEditingController? activityDetailsFieldController,
    TextEditingController? hoursFieldController,
  })  : projectDropdownController =
            projectDropdownController ?? TextEditingController(),
        moduleDropdownController =
            moduleDropdownController ?? TextEditingController(),
        TaskDropdownController =
            TaskDropdownController ?? TextEditingController(),
        activityDropdownController =
            activityDropdownController ?? TextEditingController(),
        activityDetailsFieldController =
            activityDetailsFieldController ?? TextEditingController(),
        hoursFieldController = hoursFieldController ?? TextEditingController();
}

class TypeaheadControllerGroup {
  final SuggestionsController<Map<String, String>> project =
      SuggestionsController<Map<String, String>>();
  final SuggestionsController<Map<String, String>> module =
      SuggestionsController<Map<String, String>>();
  final SuggestionsController<Map<String, String>> task =
      SuggestionsController<Map<String, String>>();
  final SuggestionsController<Map<String, String>> activity =
      SuggestionsController<Map<String, String>>();

  void dispose() {
    project.dispose();
    module.dispose();
    task.dispose();
    activity.dispose();
  }
}

class ProjectNamesModel {
  final String id;
  final String name;
  final int totalModuleCount;

  ProjectNamesModel({
    required this.id,
    required this.name,
    this.totalModuleCount = 0,
  });

  factory ProjectNamesModel.fromJson(Map<String, dynamic> json) {
    return ProjectNamesModel(
      id: json['id'] as String,
      name: json['name'] as String,
      totalModuleCount: json['totalModuleCount'] != null
          ? json['totalModuleCount'] as int
          : 0,
    );
  }
}

class ModuleNamesModel {
  final String id;
  final String name;
  final int totalTaskCount;

  ModuleNamesModel({
    required this.id,
    required this.name,
    this.totalTaskCount = 0,
  });

  factory ModuleNamesModel.fromJson(Map<String, dynamic> json) {
    return ModuleNamesModel(
      id: json['id'] as String,
      name: json['name'] as String,
      totalTaskCount: json['projectTasksCount'] as int,
    );
  }
}

class TaskNamesModel {
  final String id;
  final String name;
  final int activitiesCount;

  TaskNamesModel({
    required this.id,
    required this.name,
    required this.activitiesCount,
  });

  factory TaskNamesModel.fromJson(Map<String, dynamic> json) {
    return TaskNamesModel(
      id: json['id'] as String,
      name: json['name'] as String,
      activitiesCount: json['activitiesCount'] as int,
    );
  }
}

class ActivityNamesModel {
  final String id;
  final String name;
  final String description;
  final double estimateHours;

  ActivityNamesModel({
    required this.id,
    required this.name,
    required this.description,
    required this.estimateHours,
  });

  factory ActivityNamesModel.fromJson(Map<String, dynamic> json) {
    return ActivityNamesModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['activityNameDescription'] ?? '',
      estimateHours: (json['estimateHours'] as num).toDouble(),
    );
  }
}
