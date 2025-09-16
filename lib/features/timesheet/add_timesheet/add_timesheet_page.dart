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

class _AddTimesheetScreenState extends State<AddTimesheetScreen> {
  /// -----------------------------------------------------------------------------
  /// Variable Declarations
  /// -----------------------------------------------------------------------------

  /// Loading flags
  bool _isLoading = false;
  bool _isInitialLoading = false;
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
      c?.field1?.dispose();
      c?.field2?.dispose();
      c?.field3?.dispose();
      c?.field4?.dispose();
      c?.field5?.dispose();
      c?.field6?.dispose();
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
    setState(() => _isLoading = true);

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
      setState(() => _isLoading = false);
    }
  }

  /// Loads tasks for the selected project+module and maps them into dropdown items.
  Future<void> _loadTaskOptionsForModule(int index) async {
    setState(() => _isLoading = true);

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
      setState(() => _isLoading = false);
    }
  }

  /// Loads activities for the selected project+module+task and maps them into dropdown items.
  Future<void> _loadActivityOptionsForTaskAndDate(int index) async {
    setState(() => _isLoading = true);

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
        _timesheetCardsList[index].projectActivityDropdown = fetchedActivities.map((
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
      setState(() => _isLoading = false);
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
      final description = card.inputFieldsController?.field5?.text ?? "";
      final hoursStr = card.inputFieldsController?.field6?.text ?? "0";
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
              ? (card.inputFieldsController?.field5?.text ?? '')
              : (original?.description ?? ''),
          "hours": card != null
              ? (double.tryParse(
                    card.inputFieldsController?.field6?.text ?? '',
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
              ? (card.inputFieldsController?.field2?.text ?? '')
              : (original?.projectModule?.name ?? ''),
          "taskName": card != null
              ? (card.inputFieldsController?.field3?.text ?? '')
              : (original?.task?.name ?? ''),
          "projectName": card != null
              ? (card.inputFieldsController?.field1?.text ?? '')
              : (original?.project?.name ?? ''),
          "rowCounter": index + 1,
          "timesheetId": widget.timesheetId,
          "isMyTaskActivity": false,
          "flag": "Edit",
          "projectActivityName": card != null
              ? (card.inputFieldsController?.field4?.text ?? '')
              : (original?.projectActivity?.name ?? ''),
        };
      }),
    };
  }

  /// Builds a PUT payload line for a newly added (unsaved) card.
  Map<String, dynamic> _buildUpdatePayloadForNewLine(
    TimesheetCardsModel card,
  ) {
    final description = card.inputFieldsController?.field5?.text ?? "";
    final hoursStr = card.inputFieldsController?.field6?.text ?? "0";
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
      final desc = t.inputFieldsController?.field5?.text.trim() ?? '';
      final hrs = t.inputFieldsController?.field6?.text.trim() ?? '';

      // t.detailsError = Validators.validateDescription(
      //   desc,
      //   fieldName: "Activity details",
      // );
      t.hoursError = Validators.validateHours(hrs, fieldName: "Hours");

      t.projectError = Validators.validateText(
        t.inputFieldsController?.field1?.text,
        fieldName: "Project name",
      );
      t.moduleError = Validators.validateText(
        t.inputFieldsController?.field2?.text,
        fieldName: "Module name",
      );
      t.taskError = Validators.validateText(
        t.inputFieldsController?.field3?.text,
        fieldName: "Task name",
      );
      // t.activityError = Validators.validateText(
      //   t.inputFieldsController?.field4?.text,
      //   fieldName: "Activity name",
      // );

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
        field1: TextEditingController(text: ''),
        field2: TextEditingController(text: ''),
        field3: TextEditingController(text: ''),
        field4: TextEditingController(text: ''),
        field5: TextEditingController(text: ''),
        field6: TextEditingController(text: ''),
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
      for (int i = 0; i < _originalTimesheetList[0].timesheetLines!.length; i++) {
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
                                TypeAheadField(
                                  suggestionsCallback: (pattern) async {
                                    if (pattern.isEmpty) {
                                      return _projectDropdownList;
                                    }
                                    return _projectDropdownList
                                        .where(
                                          (r) => r.name!.toLowerCase().contains(
                                                pattern.toLowerCase(),
                                              ),
                                        )
                                        .toList();
                                  },
                                  itemBuilder: (
                                    context,
                                    TimesheetDropdownValuesModel suggestion,
                                  ) {
                                    return ListTile(
                                      title: Text(
                                        suggestion.name.toString(),
                                      ),
                                    );
                                  },
                                  onSelected: (
                                    TimesheetDropdownValuesModel suggestion,
                                  ) {
                                    card.projectId = suggestion.id.toString();
                                    _loadModuleOptionsForProject(index);
                                    cardInputFieldController?.field1?.text =
                                        suggestion.name.toString();
                                    setState(() {
                                      card.projectError = null;

                                      // Clear dependent fields
                                      cardInputFieldController?.field2 =
                                          TextEditingController();
                                      card.projectModulesDropdown = [];
                                      card.moduleId = '';

                                      cardInputFieldController?.field3 =
                                          TextEditingController();
                                      card.projectTaskDropdown = [];
                                      card.taskId = '';

                                      cardInputFieldController?.field4 =
                                          TextEditingController();
                                      card.projectActivityDropdown = [];
                                      card.activityId = '';
                                    });
                                  },
                                  loadingBuilder: (context) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.PRIMARY,
                                      ),
                                    ),
                                  ),
                                  emptyBuilder: (context) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('No project found'),
                                  ),
                                  builder:
                                      (context, fieldController, focusNode) {
                                    final showClear =
                                        fieldController.text.isNotEmpty;
                                    return TextField(
                                      controller: fieldController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Project',
                                        errorText: card.projectError,
                                        border: const OutlineInputBorder(),
                                        isDense: false,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (showClear)
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  fieldController.clear();
                                                  setState(() {
                                                    card.projectId = '';
                                                    // Clear dependent fields
                                                    cardInputFieldController
                                                            ?.field2 =
                                                        TextEditingController();
                                                    card.projectModulesDropdown =
                                                        [];
                                                    card.moduleId = '';

                                                    cardInputFieldController
                                                            ?.field3 =
                                                        TextEditingController();
                                                    card.projectTaskDropdown =
                                                        [];
                                                    card.taskId = '';

                                                    cardInputFieldController
                                                            ?.field4 =
                                                        TextEditingController();
                                                    card.projectActivityDropdown =
                                                        [];
                                                    card.activityId = '';
                                                  });
                                                },
                                              ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () {
                                                focusNode.hasFocus
                                                    ? focusNode.unfocus()
                                                    : focusNode.requestFocus();
                                              },
                                              icon: Icon(
                                                focusNode.hasFocus
                                                    ? Icons.arrow_drop_up
                                                    : Icons.arrow_drop_down,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          card.projectId = '';
                                        });
                                      },
                                    );
                                  },
                                  controller: cardInputFieldController?.field1,
                                ),
                                SizedBox(height: 10),

                                /// ===================== MODULE FIELD =====================
                                TypeAheadField(
                                  suggestionsCallback: (pattern) async {
                                    await _loadModuleOptionsForProject(index);
                                    if (pattern.isEmpty) {
                                      return card.projectModulesDropdown;
                                    }
                                    return card.projectModulesDropdown
                                        .where(
                                          (r) => r.name!.toLowerCase().contains(
                                                pattern.toLowerCase(),
                                              ),
                                        )
                                        .toList();
                                  },
                                  itemBuilder: (
                                    context,
                                    TimesheetDropdownValuesModel suggestion,
                                  ) {
                                    return ListTile(
                                      title: Text(
                                        suggestion.name.toString(),
                                      ),
                                    );
                                  },
                                  onSelected: (
                                    TimesheetDropdownValuesModel suggestion,
                                  ) {
                                    card.moduleId = suggestion.id.toString();
                                    _loadTaskOptionsForModule(index);
                                    cardInputFieldController?.field2?.text =
                                        suggestion.name.toString();
                                    setState(() {
                                      card.moduleError = null;

                                      cardInputFieldController?.field3 =
                                          TextEditingController();
                                      card.projectTaskDropdown = [];
                                      card.taskId = '';

                                      cardInputFieldController?.field4 =
                                          TextEditingController();
                                      card.projectActivityDropdown = [];
                                      card.activityId = '';
                                    });
                                  },
                                  loadingBuilder: (context) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.PRIMARY,
                                      ),
                                    ),
                                  ),
                                  emptyBuilder: (context) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('No module found'),
                                  ),
                                  builder:
                                      (context, fieldController, focusNode) {
                                    final showClear =
                                        fieldController.text.isNotEmpty;
                                    return TextField(
                                      controller: fieldController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Module',
                                        errorText: card.moduleError,
                                        border: const OutlineInputBorder(),
                                        isDense: false,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (showClear)
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  fieldController.clear();
                                                  setState(() {
                                                    card.moduleId = '';

                                                    cardInputFieldController
                                                            ?.field3 =
                                                        TextEditingController();
                                                    card.projectTaskDropdown =
                                                        [];
                                                    card.taskId = '';

                                                    cardInputFieldController
                                                            ?.field4 =
                                                        TextEditingController();
                                                    card.projectActivityDropdown =
                                                        [];
                                                    card.activityId = '';
                                                  });
                                                },
                                              ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () {
                                                focusNode.hasFocus
                                                    ? focusNode.unfocus()
                                                    : focusNode.requestFocus();
                                              },
                                              icon: Icon(
                                                focusNode.hasFocus
                                                    ? Icons.arrow_drop_up
                                                    : Icons.arrow_drop_down,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          card.moduleId = '';
                                        });
                                      },
                                    );
                                  },
                                  controller: cardInputFieldController?.field2,
                                ),
                                SizedBox(height: 10),

                                /// ===================== TASK FIELD =====================
                                TypeAheadField(
                                  suggestionsCallback: (pattern) async {
                                    await _loadTaskOptionsForModule(index);
                                    if (pattern.isEmpty) {
                                      return card.projectTaskDropdown;
                                    }
                                    return card.projectTaskDropdown
                                        .where(
                                          (r) => r.name!.toLowerCase().contains(
                                                pattern.toLowerCase(),
                                              ),
                                        )
                                        .toList();
                                  },
                                  itemBuilder: (
                                    context,
                                    TimesheetDropdownValuesModel suggestion,
                                  ) {
                                    return ListTile(
                                      title: Text(
                                        suggestion.name.toString(),
                                      ),
                                    );
                                  },
                                  onSelected: (
                                    TimesheetDropdownValuesModel suggestion,
                                  ) {
                                    card.taskId = suggestion.id.toString();
                                    _loadActivityOptionsForTaskAndDate(index);
                                    cardInputFieldController?.field3?.text =
                                        suggestion.name.toString();
                                    setState(() {
                                      card.taskError = null;

                                      cardInputFieldController?.field4 =
                                          TextEditingController();
                                      card.projectActivityDropdown = [];
                                      card.activityId = '';
                                    });
                                  },
                                  loadingBuilder: (context) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.PRIMARY,
                                      ),
                                    ),
                                  ),
                                  emptyBuilder: (context) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('No task found'),
                                  ),
                                  builder:
                                      (context, fieldController, focusNode) {
                                    final showClear =
                                        fieldController.text.isNotEmpty;
                                    return TextField(
                                      controller: fieldController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Task',
                                        errorText: card.taskError,
                                        border: const OutlineInputBorder(),
                                        isDense: false,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (showClear)
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  fieldController.clear();
                                                  setState(() {
                                                    card.taskId = '';

                                                    cardInputFieldController
                                                            ?.field4 =
                                                        TextEditingController();
                                                    card.projectActivityDropdown =
                                                        [];
                                                    card.activityId = '';
                                                  });
                                                },
                                              ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () {
                                                focusNode.hasFocus
                                                    ? focusNode.unfocus()
                                                    : focusNode.requestFocus();
                                              },
                                              icon: Icon(
                                                focusNode.hasFocus
                                                    ? Icons.arrow_drop_up
                                                    : Icons.arrow_drop_down,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          card.taskId = '';
                                        });
                                      },
                                    );
                                  },
                                  controller: cardInputFieldController?.field3,
                                ),
                                SizedBox(height: 10),

                                /// ===================== ACTIVITY FIELD =====================
                                TypeAheadField(
                                  suggestionsCallback: (pattern) async {
                                    await _loadActivityOptionsForTaskAndDate(index);
                                    if (pattern.isEmpty) {
                                      return card.projectActivityDropdown;
                                    }
                                    return card.projectActivityDropdown
                                        .where(
                                          (r) => r.name!.toLowerCase().contains(
                                                pattern.toLowerCase(),
                                              ),
                                        )
                                        .toList();
                                  },
                                  itemBuilder: (
                                    context,
                                    TimesheetDropdownValuesModel suggestion,
                                  ) {
                                    return ListTile(
                                      title: Text(
                                        suggestion.name.toString(),
                                      ),
                                    );
                                  },
                                  onSelected: (
                                    TimesheetDropdownValuesModel suggestion,
                                  ) {
                                    card.activityId = suggestion.id.toString();
                                    cardInputFieldController?.field4?.text =
                                        suggestion.name.toString();
                                    setState(() {
                                      card.activityError = null;
                                    });
                                  },
                                  loadingBuilder: (context) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.PRIMARY,
                                      ),
                                    ),
                                  ),
                                  emptyBuilder: (context) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('No activity found'),
                                  ),
                                  builder:
                                      (context, fieldController, focusNode) {
                                    final showClear =
                                        fieldController.text.isNotEmpty;
                                    return TextField(
                                      controller: fieldController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Activity (Est. Hrs)',
                                        errorText: card.activityError,
                                        border: const OutlineInputBorder(),
                                        isDense: false,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (showClear)
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                icon: const Icon(
                                                  Icons.clear,
                                                ),
                                                onPressed: () {
                                                  fieldController.clear();
                                                  setState(() {
                                                    card.activityId = '';
                                                  });
                                                },
                                              ),
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () {
                                                focusNode.hasFocus
                                                    ? focusNode.unfocus()
                                                    : focusNode.requestFocus();
                                              },
                                              icon: Icon(
                                                focusNode.hasFocus
                                                    ? Icons.arrow_drop_up
                                                    : Icons.arrow_drop_down,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          card.activityId = '';
                                        });
                                      },
                                    );
                                  },
                                  controller: cardInputFieldController?.field4,
                                ),
                                SizedBox(height: 10),
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
                                      child: HtmlEmailEditor(
                                        initialHtml: cardInputFieldController
                                            ?.field5?.text,
                                        editorHeight: 140,
                                        onChanged: (html) {
                                          cardInputFieldController
                                              ?.field5?.text = html;
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
                                      controller:
                                          cardInputFieldController?.field6,
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
                onPressed: _isInitialLoading || _isSubmitting ? null : _onAddLinePressed,
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
                                                ? _onSubmitUpdatePressed(context)
                                                : await _onSubmitCreatePressed(context);
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
  String? projectError;
  String? moduleError;
  String? taskError;
  String? activityError;
  String? detailsError;
  String? hoursError;
  String? id;

  TimesheetCardsModel({
    this.inputFieldsController,
    this.projectModulesDropdown = const [],
    this.projectTaskDropdown = const [],
    this.projectActivityDropdown = const [],
    this.projectId = '',
    this.moduleId = '',
    this.taskId = '',
    this.activityId = '',
    this.id,
  });

  factory TimesheetCardsModel.fromTimesheetLine(Map<String, dynamic> json) {
    final project = (json['project'] ?? {}) as Map<String, dynamic>;
    final projectModule = (json['projectModule'] ?? {}) as Map<String, dynamic>;
    final task = (json['task'] ?? {}) as Map<String, dynamic>;
    final activity = (json['projectActivity'] ?? {}) as Map<String, dynamic>;

    final controllers = FieldControllerModel(
      field1: TextEditingController(text: project['name']?.toString() ?? ''),
      field2: TextEditingController(
        text: projectModule['name']?.toString() ?? '',
      ),
      field3: TextEditingController(text: task['name']?.toString() ?? ''),
      field4: TextEditingController(text: activity['name']?.toString() ?? ''),
      field5: TextEditingController(
        text: json['description']?.toString() ?? '',
      ),
      field6: TextEditingController(
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
  TextEditingController? field1;
  TextEditingController? field2;
  TextEditingController? field3;
  TextEditingController? field4;
  TextEditingController? field5;
  TextEditingController? field6;

  FieldControllerModel({
    TextEditingController? field1,
    TextEditingController? field2,
    TextEditingController? field3,
    TextEditingController? field4,
    TextEditingController? field5,
    TextEditingController? field6,
  })  : field1 = field1 ?? TextEditingController(),
        field2 = field2 ?? TextEditingController(),
        field3 = field3 ?? TextEditingController(),
        field4 = field4 ?? TextEditingController(),
        field5 = field5 ?? TextEditingController(),
        field6 = field6 ?? TextEditingController();
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
