import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:test_project/core/constants/formats.dart';
import 'package:test_project/core/dialogs/confirmation_dialog.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/utils/validators.dart';
import 'package:test_project/core/widgets/input_field/custom_rich_quill_value.dart';
import 'package:test_project/core/widgets/input_field/custom_type_ahead_field.dart';
import 'package:test_project/core/widgets/snackbar/custom_snackbar.dart';
import 'package:test_project/features/timesheet/add_timesheet/modle/timesheet_details_by_id_responce_model.dart';
import 'package:test_project/features/timesheet/timesheet_service.dart';
import 'package:uuid/uuid.dart';

class AddTimesheetScreen extends StatefulWidget {
  final String? timesheetId;

  const AddTimesheetScreen({Key? key, this.timesheetId = null})
      : super(key: key);

  @override
  _AddTimesheetScreenState createState() => _AddTimesheetScreenState();
}

List<Map<String, String>> toItems(List<TimesheetDropdownValuesModel> src) {
  return src
      .map((r) => {
            'id': (r.id ?? '').toString(),
            'name': (r.name ?? '').toString(),
          })
      .toList();
}

class _AddTimesheetScreenState extends State<AddTimesheetScreen> {
  /// -----------------------------------------------------------------------------
  /// Variable Declarations
  /// -----------------------------------------------------------------------------

  /// Loading flags
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _isSubmitting = false;

  bool _isHasTimesheetId = false;

  // Timesheet line cards
  List<TimesheetCardsModel> _timesheetCardsList = <TimesheetCardsModel>[];

  // Dropdown sources
  List<TimesheetDropdownValuesModel> _projectDropdownList =
      <TimesheetDropdownValuesModel>[];
  List<TimeInTimeOutDetailByIdResponseModel> _originalTimesheetList =
      <TimeInTimeOutDetailByIdResponseModel>[];

  // Date input
  final TextEditingController _dateController = TextEditingController();
  String? _dateError;
  DateTime _selectedDate = DateTime.now();

  /// -----------------------------------------------------------------------------
  /// Lifecycle
  /// -----------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadProjectOptions();
    final formattedToday = _selectedDate.format();
    _dateController.text = formattedToday;

    if (widget.timesheetId == null || widget.timesheetId == 'null') {
      _onAddLinePressed();
    } else {
      setState(() {
        _isHasTimesheetId = true;
      });
      _loadTimesheetDetailById(widget.timesheetId!);
    }
  }

  @override
  void dispose() {
    _disposeAllCardControllers();
    super.dispose();
  }

  void _disposeAllCardControllers() {
    for (final card in _timesheetCardsList) {
      final c = card.inputFieldsController;
      c?.projectDropdownController?.dispose();
      c?.moduleDropdownController?.dispose();
      c?.TaskDropdownController?.dispose();
      c?.activityDropdownController?.dispose();
      c?.activityDetailsFieldController?.dispose();
      c?.hoursFieldController?.dispose();
    }
  }

  /// -----------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// -----------------------------------------------------------------------------

  /// Fetches the full timesheet by id, initializes the date and line cards.
  Future<void> _loadTimesheetDetailById(String id) async {
    setState(() {
      _isLoading = true;
      _isInitialLoading = true;
    });

    try {
      final response = await TimesheetService.instance.fetchTimesheetById(id);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final apiDateStr = data['timesheetDate'] as String?;
        if (apiDateStr != null && apiDateStr.isNotEmpty) {
          _dateController.text = apiDateStr;

          final parsedDate = DateFormat(
            ConstFormats.DATE_MMDDYYYY,
          ).parse(apiDateStr);

          _selectedDate = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            _selectedDate.hour,
            _selectedDate.minute,
            _selectedDate.second,
            _selectedDate.millisecond,
            _selectedDate.microsecond,
          );
        }

        final lines = List<Map<String, dynamic>>.from(
          (data['timesheetLines'] as List?) ?? [],
        );

        _originalTimesheetList = lines
            .map((line) => TimeInTimeOutDetailByIdResponseModel.fromJson(data))
            .toList();

        _disposeAllCardControllers();

        final List<TimesheetCardsModel> fetchedCards = [];
        if (lines.isEmpty) {
          fetchedCards.add(TimesheetCardsModel());
        } else {
          for (final rawLine in lines) {
            fetchedCards.add(TimesheetCardsModel.fromTimesheetLine(rawLine));
          }
        }

        setState(() {
          _timesheetCardsList = fetchedCards;
        });
      } else {
        throw Exception(
          'Failed to fetch timesheet. Status: ${response.statusCode}',
        );
      }
    } catch (e, st) {
      debugPrint('fetchTimesheetById error: $e\n$st');
    } finally {
      setState(() {
        _isLoading = false;
        _isInitialLoading = false;
      });
    }
  }

  /// Loads project names for the first dropdown (id + label shaping).
  Future<void> _loadProjectOptions() async {
    setState(() {
      _isLoading = true;
      _isInitialLoading = true;
    });

    try {
      final response =
          await TimesheetService.instance.fetchProjectNameDropdownIds();
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
        _isInitialLoading = false;
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
      final response = await TimesheetService.instance.fetchModuleNameIds(
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

      final response = await TimesheetService.instance.fetchTaskNameIds(
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
  Future<void> _loadActivityOptionsForTaskAndDate(int index) async {
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

      final response = await TimesheetService.instance.fetchActivityNameIds(
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
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('fetchActivityNameIds error: $e');
    } finally {
      setState(() => card.isLoadingActivities = false);
    }
  }

  /// Generates a GUID for a new timesheet line.
  String _createGuid() {
    var uuid = Uuid();
    return uuid.v4();
  }

  /// Builds the POST payload from the current cards and selected date.
  Map<String, dynamic> _buildTimesheetCreatePayload() {
    final timesheetDateStr =
        "${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.year}";

    final timesheetLineModel = _timesheetCardsList.map((card) {
      final description =
          card.inputFieldsController?.activityDetailsFieldController?.text ??
              "";
      final hoursStr =
          card.inputFieldsController?.hoursFieldController?.text ?? "0";
      final hours = double.tryParse(hoursStr) ?? 0.0;
      final guid = _createGuid();

      print("Generated GUID for timesheet line: $guid");

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
    }).toList();

    final payload = {
      "timesheetDate": timesheetDateStr,
      "timesheetLineModel": timesheetLineModel,
    };

    print("Final post payload: $payload");

    return payload;
  }

  /// Builds the PUT payload merging edited lines with original server state.
  Map<String, dynamic> _buildTimesheetUpdatePayload() {
    // First, check if we have valid original timesheet data
    if (_originalTimesheetList.isEmpty ||
        _originalTimesheetList[0].timesheetLines == null) {
      return {
        "timesheetDate": "${_selectedDate.month.toString().padLeft(2, '0')}/"
            "${_selectedDate.day.toString().padLeft(2, '0')}/"
            "${_selectedDate.year}",
        "timesheetLineModel": [],
      };
    }

    final timesheetLines = _originalTimesheetList[0].timesheetLines!;

    return {
      "timesheetDate": "${_selectedDate.month.toString().padLeft(2, '0')}/"
          "${_selectedDate.day.toString().padLeft(2, '0')}/"
          "${_selectedDate.year}",
      "timesheetLineModel": List.generate(timesheetLines.length, (index) {
        final original = timesheetLines[index];

        // Safely find matching card with proper error handling
        TimesheetCardsModel? matchingCard;
        try {
          matchingCard = _timesheetCardsList.firstWhere(
            (card) => original != null && original.id == card.id,
          );
        } catch (e) {
          // No matching card found, which is acceptable for new entries
          matchingCard = null;
        }

        final card = matchingCard;

        return {
          "projectActivityId": card != null
              ? (card.activityId ?? '')
              : (original?.projectActivityId ?? ''),
          "description": card != null
              ? (card.inputFieldsController?.activityDetailsFieldController
                      ?.text ??
                  '')
              : (original?.description ?? ''),
          "hours": card != null
              ? (double.tryParse(
                    card.inputFieldsController?.hoursFieldController?.text ??
                        '',
                  ) ??
                  0.0)
              : (original?.hours ?? 0.0),
          "billableHours": original?.billableHours ?? 0.0,
          "deleted": original?.deleted ?? false,
          "taskId":
              card != null ? (card.taskId ?? '') : (original?.taskId ?? ''),
          "project": original?.project?.toJson() ?? {},
          "projectModule": original?.projectModule?.toJson() ?? {},
          "task": original?.task?.toJson() ?? {},
          "projectActivity": original?.projectActivity?.toJson() ?? {},
          "timesheetDataModel": [],
          "columns": [],
          "id": original?.id ?? '',
          "customProperties": {},
          "editing": false,
          "projectId": card != null
              ? (card.projectId ?? '')
              : (original?.project?.id ?? ''),
          "projectModuleId": card != null
              ? (card.moduleId ?? '')
              : (original?.projectModule?.id ?? ''),
          "projectTaskId":
              card != null ? (card.taskId ?? '') : (original?.task?.id ?? ''),
          "moduleName": card != null
              ? (card.inputFieldsController?.moduleDropdownController?.text ??
                  '')
              : (original?.projectModule?.name ?? ''),
          "taskName": card != null
              ? (card.inputFieldsController?.TaskDropdownController?.text ?? '')
              : (original?.task?.name ?? ''),
          "projectName": card != null
              ? (card.inputFieldsController?.projectDropdownController?.text ??
                  '')
              : (original?.project?.name ?? ''),
          "rowCounter": index + 1,
          "timesheetId": widget.timesheetId,
          "isMyTaskActivity": false,
          "flag": "Edit",
          "projectActivityName": card != null
              ? (card.inputFieldsController?.activityDropdownController?.text ??
                  '')
              : (original?.projectActivity?.name ?? ''),
        };
      }),
    };
  }

  /// Builds a PUT payload line for a newly added (unsaved) card.
  Map<String, dynamic> _buildUpdatePayloadForNewLine(
    TimesheetCardsModel card,
  ) {
    final description =
        card.inputFieldsController?.activityDetailsFieldController?.text ?? "";
    final hoursStr =
        card.inputFieldsController?.hoursFieldController?.text ?? "0";
    final hours = double.tryParse(hoursStr) ?? 0.0;
    final guid = _createGuid();

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

  /// -----------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// -----------------------------------------------------------------------------

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

  /// Submits a new timesheet and shows feedback on success or error.
  Future<void> _onSubmitCreatePressed(BuildContext context) async {
    setState(() {
      _isSubmitting = true;
      _isLoading = true;
    });

    Fluttertoast.showToast(
      msg: "Submitting… please wait",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );

    try {
      final payload = _buildTimesheetCreatePayload();
      final response = await TimesheetService.instance.saveTimesheet(payload);

      if (response.statusCode == 200) {
        showCustomSnackBar(
          context,
          message: 'Timesheet added successfully!',
          durationSeconds: 2,
        );
        context.pop();
      } else {
        showCustomSnackBar(
          context,
          message: 'Failed to add Timesheet',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        message: 'Error: $e',
        backgroundColor: AppColors.ERROR,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isSubmitting = false;
      });
    }
  }

  /// Updates an existing timesheet and shows feedback on success or error.
  Future<void> _onSubmitUpdatePressed(BuildContext context) async {
    setState(() {
      _isSubmitting = true;
      _isLoading = true;
    });

    Fluttertoast.showToast(
      msg: "Updating… please wait",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );

    try {
      final payload = _buildTimesheetUpdatePayload();

      _timesheetCardsList.where((card) => card.id == null).forEach((card) {
        payload["timesheetLineModel"].add(
          _buildUpdatePayloadForNewLine(card),
        );
      });

      // final prettyPayload = const JsonEncoder.withIndent('  ').convert(payload);
      // // print("payload is :\n$prettyPayload");
      // debugPrint("payload is :\n$prettyPayload", wrapWidth: 1024);

      if (widget.timesheetId == null) {
        showCustomSnackBar(
          context,
          message: "Timesheet ID is missing",
          backgroundColor: AppColors.ERROR,
        );
        return;
      }

      final response = await TimesheetService.instance.updateTimesheet(
        widget.timesheetId!,
        payload,
      );

      if (response.statusCode == 200) {
        showCustomSnackBar(
          context,
          message: 'Timesheet updated successfully!',
          durationSeconds: 2,
        );
        context.pop();
      } else {
        showCustomSnackBar(
          context,
          message: 'Failed to update Timesheet',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        message: 'Error: $e',
        backgroundColor: AppColors.ERROR,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isSubmitting = false;
      });
    }
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
    if (_originalTimesheetList.isNotEmpty &&
        _originalTimesheetList[0].timesheetLines != null &&
        linerId != null) {
      for (int i = 0;
          i < _originalTimesheetList[0].timesheetLines!.length;
          i++) {
        final timesheetLine = _originalTimesheetList[0].timesheetLines![i];
        if (timesheetLine.id == linerId) {
          timesheetLine.deleted = true;
          // print(
          //   _originalTimesheetList[0].timesheetLines
          //       .map((line) => line.toJson())
          //       .toList(),
          // );
          break;
        }
      }
    }

    setState(() {
      _timesheetCardsList.removeAt(index);
    });
  }

  /// Updates date error state on user edit and stores a parsed date on success.
  void _onDateChanged(String text) {
    setState(() {
      _dateError = Validators.validateDate(text, lastDate: DateTime.now());
    });
    if (_dateError == null) {
      final DateTime parsedDate = ConstFormats.DATE_FORMAT.parseStrict(text);
      _selectedDate = parsedDate;
    }
  }

  /// Opens a date picker and writes the chosen date back to the input.
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

  /// Confirms navigation before closing the screen.
  Future<bool> _confirmBackNavigation(BuildContext context) async {
    final shouldNavigate = await showNavigationConfirmationDialog(context);
    return shouldNavigate ?? false;
  }

  /// -----------------------------------------------------------------------------
  /// UI
  /// -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldNavigate = await _confirmBackNavigation(context);
        if (shouldNavigate) {
          return true;
        } else
          return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              bool shouldNavigate = await _confirmBackNavigation(context);
              shouldNavigate ? context.pop() : null;
            },
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            _isHasTimesheetId ? 'Edit Timesheet' : 'Add Timesheet',
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
              child: _isInitialLoading
                  ? Center(child: CircularProgressIndicator())
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
                                  selectedId: (card.projectId.isEmpty)
                                      ? null
                                      : card.projectId,
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
                                  selectedId: (card.moduleId.isEmpty)
                                      ? null
                                      : card.moduleId,
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
                                CustomTypeAheadField(
                                  items: toItems(card.projectTaskDropdown),
                                  selectedId: (card.taskId.isEmpty)
                                      ? null
                                      : card.taskId,
                                  label: 'Task',
                                  errorText: card.taskError,
                                  suggestionsController: card.typeahead.task,
                                  isLoading: card.isLoadingTasks,
                                  onOpen: () async {
                                    if (card.projectTaskDropdown.isEmpty &&
                                        card.moduleId.isNotEmpty) {
                                      setState(
                                          () => card.isLoadingTasks = true);
                                      await _loadTaskOptionsForModule(index);
                                      setState(
                                          () => card.isLoadingTasks = false);
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
                                      await _loadActivityOptionsForTaskAndDate(
                                          index);
                                    }
                                    setState(
                                        () => card.isLoadingActivities = false);
                                    card.typeahead.activity.refresh();
                                  },
                                  onCleared: () {
                                    setState(() {
                                      card.taskId = '';
                                      card.activityId = '';
                                      card.projectActivityDropdown = [];
                                      card.inputFieldsController
                                          ?.TaskDropdownController?.text = '';
                                      card
                                          .inputFieldsController
                                          ?.activityDropdownController
                                          ?.text = '';
                                    });
                                    card.typeahead.activity.refresh();
                                  },
                                ),
                                const SizedBox(height: 10),
                                // ===================== ACTIVITY FIELD =====================
                                CustomTypeAheadField(
                                  items: toItems(card.projectActivityDropdown),
                                  selectedId: (card.activityId.isEmpty)
                                      ? null
                                      : card.activityId,
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
                                      await _loadActivityOptionsForTaskAndDate(
                                          index);
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
            ),
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
                                  _isHasTimesheetId
                                      ? "Are you sure you want to submit your edited timesheet?"
                                      : "Are you sure you want to submit your timesheet?",
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
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            dialogContext.pop();
                                            _isHasTimesheetId
                                                ? _onSubmitUpdatePressed(
                                                    context)
                                                : await _onSubmitCreatePressed(
                                                    context);
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
                  bool shouldNavigate = await _confirmBackNavigation(context);
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
    TypeaheadControllerGroup? typeahead,
    this.isLoadingModules = false,
    this.isLoadingTasks = false,
    this.isLoadingActivities = false,
  }) : typeahead = typeahead ?? TypeaheadControllerGroup();

  factory TimesheetCardsModel.fromTimesheetLine(Map<String, dynamic> json) {
    final project = (json['project'] ?? {}) as Map<String, dynamic>;
    final projectModule = (json['projectModule'] ?? {}) as Map<String, dynamic>;
    final task = (json['task'] ?? {}) as Map<String, dynamic>;
    final activity = (json['projectActivity'] ?? {}) as Map<String, dynamic>;

    final controllers = FieldControllerModel(
      projectDropdownController:
          TextEditingController(text: project['name']?.toString() ?? ''),
      moduleDropdownController: TextEditingController(
        text: projectModule['name']?.toString() ?? '',
      ),
      TaskDropdownController:
          TextEditingController(text: task['name']?.toString() ?? ''),
      activityDropdownController:
          TextEditingController(text: activity['name']?.toString() ?? ''),
      activityDetailsFieldController: TextEditingController(
        text: json['description']?.toString() ?? '',
      ),
      hoursFieldController: TextEditingController(
        text: json['hours'] != null ? json['hours'].toString() : '',
      ),
    );

    return TimesheetCardsModel(
      inputFieldsController: controllers,
      projectModulesDropdown: [],
      projectTaskDropdown: [],
      projectActivityDropdown: [],
      projectId: project['id']?.toString() ?? '',
      moduleId: projectModule['id']?.toString() ?? '',
      taskId: task['id']?.toString() ?? '',
      activityId: activity['id']?.toString() ?? '',
      activityDetails: json['description']?.toString() ?? '',
      activityHours: json['hours'] != null ? json['hours'].toString() : '',
      id: json["id"] ?? '',
    );
  }
}

class TimesheetDropdownValuesModel {
  String? id;
  String? name;

  TimesheetDropdownValuesModel({this.id, this.name});
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
  final double estimateHours;

  ActivityNamesModel({
    required this.id,
    required this.name,
    required this.estimateHours,
  });

  factory ActivityNamesModel.fromJson(Map<String, dynamic> json) {
    return ActivityNamesModel(
      id: json['id'] as String,
      name: json['name'] as String,
      estimateHours: (json['estimateHours'] as num).toDouble(),
    );
  }
}
