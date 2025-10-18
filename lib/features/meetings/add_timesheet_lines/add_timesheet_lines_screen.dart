import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as parser;

import 'package:test_project/core/constants/formats.dart';
import 'package:test_project/core/dialogs/confirmation_dialog.dart';
import 'package:test_project/core/dialogs/delete_confirmation_dialog.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/utils/validators.dart';
import 'package:test_project/core/widgets/draggable_scrollable_sheet/show_task_detail_bottom_sheet.dart';
import 'package:test_project/core/widgets/input_field/custom_rich_quill_value.dart';
import 'package:test_project/core/widgets/input_field/custom_type_ahead_field.dart';
import 'package:test_project/core/widgets/snackbar/custom_snackbar.dart';
import 'package:test_project/features/meetings/meetings_service.dart';
import 'package:test_project/features/timesheet/timesheet_service.dart';
import 'package:uuid/uuid.dart';

class AddTimesheetLinesScreen extends StatefulWidget {
  final String? meetingUId;
  final String? meetingSubject;
  final String? meetingStrDateTime;
  final String? meetingEndDateTime;
  final String? meetingDuration;

  const AddTimesheetLinesScreen(
      {Key? key,
      this.meetingUId = null,
      this.meetingSubject = null,
      this.meetingStrDateTime = null,
      this.meetingEndDateTime = null,
      this.meetingDuration = null})
      : super(key: key);

  @override
  _AddTimesheetLinesScreenState createState() =>
      _AddTimesheetLinesScreenState();
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

class _AddTimesheetLinesScreenState extends State<AddTimesheetLinesScreen> {
  /// -----------------------------------------------------------------------------
  /// Variable Declarations
  /// -----------------------------------------------------------------------------

  /// Loading flags
  bool _isLoading = false;
  bool _isInitialLoading = false;
  bool _isSubmitting = false;
  bool _isDeletingTimesheetLine = false;

  bool _isTimesheetLinesField = true;

  // Timesheet line cards
  List<TimesheetCardsModel> _timesheetCardsList = <TimesheetCardsModel>[];
  List<TimesheetLineByMeetingUidModel> _timesheetLines = [];
  // Dropdown sources
  List<TimesheetDropdownValuesModel> _projectDropdownList =
      <TimesheetDropdownValuesModel>[];

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
    _init(); // do not await
  }

  Future<void> _init() async {
    await _loadTimesheetDetailByMeetUid(widget.meetingUId ?? '');
    if (!mounted) return;

    if (!_isTimesheetLinesField) {
      await _loadProjectOptions();
      if (!mounted) return;

      final formattedToday = _selectedDate.format();
      final dateText = (widget.meetingStrDateTime?.isNotEmpty ?? false)
          ? Uri.decodeComponent(widget.meetingStrDateTime!).split(' ')[0]
          : formattedToday;

      setState(() {
        _dateController.text = dateText;
      });
    }

    if (!mounted) return;
    _onAddLinePressed();
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
  Future<void> _loadTimesheetDetailByMeetUid(String meetingUid) async {
    setState(() {
      _isLoading = true;
      _isInitialLoading = true;
    });

    try {
      final response = await TimeBuddyService.instance
          .fetchTimesheetLineByMeetingUid(meetingUid);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Update date from nested timesheet.timesheetDate
        final apiDateStr =
            (data['timesheet'] as Map?)?['timesheetDate'] as String?;
        if (apiDateStr != null && apiDateStr.isNotEmpty) {
          _dateController.text = apiDateStr;
        }

        // Map to flattened model and store as list
        final line = TimesheetLineByMeetingUidModel.fromJson(data);
        setState(() {
          _isTimesheetLinesField = true;
          _timesheetLines = [line];
        });
      } else if (response.statusCode == 204) {
        // No content
        setState(() {
          _isTimesheetLinesField = false;
          _timesheetLines = [];
        });
      } else {
        debugPrint(
            'fetchTimesheetLineByMeetingUid unexpected: ${response.statusCode}');
        setState(() {
          _isTimesheetLinesField = false;
          _timesheetLines = [];
        });
      }
    } catch (e) {
      debugPrint('fetchTimesheetLineByMeetingUid error: $e');
      setState(() {
        _isTimesheetLinesField = false;
        _timesheetLines = [];
      });
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
              description: project.description);
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
        "meetingUId": widget.meetingUId,
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

  /// Deletes a timesheet by id and refreshes the list on success.
  Future<void> _deleteTimesheetLine(BuildContext context, String id) async {
    Fluttertoast.showToast(
      msg: "Deleting... please wait",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );

    setState(() {
      _isDeletingTimesheetLine = true;
    });

    try {
      final response = await TimeBuddyService.instance.deleteTimesheetLine(id);
      if (response.statusCode == 204) {
        showCustomSnackBar(
          context,
          message: 'Timesheet line deleted successfully!',
          durationSeconds: 2,
        );
        context.pop();
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        message: 'Error: $e',
        backgroundColor: AppColors.ERROR,
      );
    }

    setState(() {
      _isDeletingTimesheetLine = false;
    });
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

  /// Adds a new empty line card with fresh controllers.
  void _onAddLinePressed() {
    setState(() {
      final newControllers = FieldControllerModel(
        projectDropdownController: TextEditingController(text: ''),
        moduleDropdownController: TextEditingController(text: ''),
        TaskDropdownController: TextEditingController(text: ''),
        activityDropdownController: TextEditingController(text: ''),
        activityDetailsFieldController: TextEditingController(text: ''),
        hoursFieldController: TextEditingController(
            text: Uri.decodeComponent(widget.meetingDuration ?? '0')),
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
    if (_isTimesheetLinesField) return true;
    final shouldNavigate = await showNavigationConfirmationDialog(context);
    return shouldNavigate ?? false;
  }

  /// Returns a plain-text preview extracted from HTML, with list awareness and truncation.
  String _parseHtmlPreview(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return 'No details available';
    }
    try {
      if (!htmlString.contains('<') || !htmlString.contains('>')) {
        return _truncateText(htmlString, maxLength: 100);
      }
      final document = parser.parse(htmlString);
      final liElements = document.querySelectorAll('li');
      if (liElements.isEmpty) {
        return _truncateText(document.body?.text ?? htmlString, maxLength: 100);
      }
      final firstItemText = _cleanText(liElements.first.text);
      final additionalItems = liElements.length - 1;
      return additionalItems > 0
          ? '$firstItemText (+$additionalItems more)'
          : firstItemText;
    } catch (_) {
      return _truncateText(htmlString, maxLength: 100);
    }
  }

  /// Removes extra whitespace and newlines in a string.
  String _cleanText(String text) {
    return text.trim().replaceAll('\n', ' ').replaceAll(RegExp(r'\s{2,}'), ' ');
  }

  /// Truncates a string to maxLength and appends ellipsis.
  String _truncateText(String text, {required int maxLength}) {
    final cleaned = _cleanText(text);
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength).trim()}...';
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
            'Add Timesheet Lines',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.PRIMARY,
        ),
        body: Column(
          children: [
            SizedBox(height: 10),
            if (!_isTimesheetLinesField)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

                        String _decode(String? v) {
                          if (v == null) return '';
                          try {
                            return Uri.decodeComponent(v);
                          } catch (_) {
                            return v;
                          }
                        }

                        final subject = _decode(widget.meetingSubject);
                        final start = _decode(widget.meetingStrDateTime);
                        final end = _decode(widget.meetingEndDateTime);

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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            subject,
                                            softWrap: true,
                                            style: const TextStyle(
                                              color: AppColors.PRIMARY,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (_isTimesheetLinesField) ...[
                                          const SizedBox(width: 8),
                                          Material(
                                            color: Colors.transparent,
                                            child: _isDeletingTimesheetLine
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    child: SizedBox(
                                                      height: 18,
                                                      width: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  )
                                                : InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    onTap: () {
                                                      showDeleteConfirmationDialog(
                                                        context,
                                                        title:
                                                            "Delete Confirmation",
                                                        description:
                                                            "Are you sure you want to remove this entry permanently?",
                                                        onDelete: () =>
                                                            _deleteTimesheetLine(
                                                          context,
                                                          _timesheetLines[0].id,
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      height: 25,
                                                      width: 25,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.delete_outline,
                                                          size: 18,
                                                          color:
                                                              AppColors.ERROR,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'Start date: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                          TextSpan(text: start),
                                        ],
                                      ),
                                      softWrap: true,
                                      style: const TextStyle(
                                        color: AppColors.PRIMARY,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'End date: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                          TextSpan(text: end),
                                        ],
                                      ),
                                      softWrap: true,
                                      style: const TextStyle(
                                        color: AppColors.PRIMARY,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                                const Divider(height: 1, thickness: 1),
                                SizedBox(height: 12),
                                if (_isTimesheetLinesField) ...[
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _timesheetLines.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, idx) {
                                      final line = _timesheetLines[idx];
                                      final activityName =
                                          line.projectActivityName;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 0, vertical: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  line.projectName,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Icon(Icons.double_arrow,
                                                    color: Colors.grey[600],
                                                    size: 18),
                                                Text(line.projectModuleName),
                                                Icon(Icons.double_arrow,
                                                    color: Colors.grey[600],
                                                    size: 18),
                                                Text(line.taskName),
                                                if (activityName.isNotEmpty)
                                                  Text(
                                                    '($activityName)',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            // Inside your itemBuilder where `line` is available
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Hours: ${line.hours}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Details:',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Html(
                                                      data: line.description
                                                              .isNotEmpty
                                                          ? line.description
                                                          : '<p>${_parseHtmlPreview(line.description)}</p>',
                                                      style: {
                                                        'body': Style(
                                                            margin:
                                                                Margins.zero,
                                                            padding:
                                                                HtmlPaddings
                                                                    .zero),
                                                        'ul': Style(
                                                            margin:
                                                                Margins.zero),
                                                        'li': Style(
                                                          margin: Margins.only(
                                                              bottom: 8),
                                                          listStylePosition:
                                                              ListStylePosition
                                                                  .outside,
                                                        ),
                                                        'p': Style(
                                                            margin:
                                                                Margins.zero),
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                if (!_isTimesheetLinesField) ...[
                                  Row(
                                    children: [
                                      Text(
                                        'Timesheet Liner',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),

                                  // ===================== PROJECT FIELD =====================
                                  CustomTypeAheadField(
                                    items: toItems(_projectDropdownList),
                                    selectedId: (card.projectId.isEmpty)
                                        ? null
                                        : card.projectId,
                                    label: 'Project',
                                    errorText: card.projectError,
                                    suggestionsController:
                                        card.typeahead.project,
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
                                        card
                                            .inputFieldsController
                                            ?.moduleDropdownController
                                            ?.text = '';
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
                                        card
                                            .inputFieldsController
                                            ?.moduleDropdownController
                                            ?.text = '';
                                        card.inputFieldsController
                                            ?.TaskDropdownController?.text = '';
                                        card
                                            .inputFieldsController
                                            ?.activityDropdownController
                                            ?.text = '';
                                      });
                                      card.typeahead.module.refresh();
                                      card.typeahead.task.refresh();
                                      card.typeahead.activity.refresh();
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
                                    suggestionsController:
                                        card.typeahead.module,
                                    isLoading: card.isLoadingModules,
                                    onOpen: () async {
                                      if (card.projectModulesDropdown.isEmpty &&
                                          card.projectId.isNotEmpty) {
                                        setState(
                                            () => card.isLoadingModules = true);
                                        await _loadModuleOptionsForProject(
                                            index);
                                        setState(() =>
                                            card.isLoadingModules = false);
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
                                      setState(
                                          () => card.isLoadingTasks = false);
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
                                          items:
                                              toItems(card.projectTaskDropdown),
                                          selectedId: (card.taskId.isEmpty)
                                              ? null
                                              : card.taskId,
                                          label: 'Task',
                                          errorText: card.taskError,
                                          suggestionsController:
                                              card.typeahead.task,
                                          isLoading: card.isLoadingTasks,
                                          onOpen: () async {
                                            if (card.projectTaskDropdown
                                                    .isEmpty &&
                                                card.moduleId.isNotEmpty) {
                                              setState(() =>
                                                  card.isLoadingTasks = true);
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
                                            setState(() => card
                                                .isLoadingActivities = false);
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
                                        ),
                                      ),
                                      if (card.taskId.isNotEmpty)
                                        IconButton(
                                            onPressed: () =>
                                                showTaskDetailBottomSheet(
                                                    context,
                                                    id: card.taskId),
                                            icon: Icon(Icons.copy))
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // ===================== ACTIVITY FIELD =====================
                                  CustomTypeAheadField(
                                    items:
                                        toItems(card.projectActivityDropdown),
                                    selectedId: (card.activityId.isEmpty)
                                        ? null
                                        : card.activityId,
                                    label: 'Activity (Est. Hrs)',
                                    errorText: card.activityError,
                                    suggestionsController:
                                        card.typeahead.activity,
                                    isLoading: card.isLoadingActivities,
                                    onOpen: () async {
                                      if (card.projectActivityDropdown
                                              .isEmpty &&
                                          card.taskId.isNotEmpty) {
                                        setState(() =>
                                            card.isLoadingActivities = true);
                                        await _loadActivityOptionsForTask(
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
                                      setState(
                                          () => card.activityId = id ?? '');
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InputDecorator(
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                          labelText: "Activity Details",
                                          hintText:
                                              "Enter activity details here",
                                          errorText: card.detailsError,
                                          contentPadding:
                                              const EdgeInsets.all(8),
                                        ),
                                        child: HtmlEditorInputField(
                                          // initialHtml: cardInputFieldController?.activityDetailsFieldController?.text,
                                          showLessOptions: true,
                                          editorHeight: 140,
                                          onChanged: (html) {
                                            cardInputFieldController
                                                ?.activityDetailsFieldController
                                                ?.text = html;
                                            setState(() {
                                              card.detailsError = Validators
                                                  .validateDescription(
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
                                ]
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
            if (!_isTimesheetLinesField)
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
                                  title: Text("Submit Timesheet Line"),
                                  content: Text(
                                    "Are you sure you want to submit your timesheet line?",
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
                                              await _onSubmitCreatePressed(
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
                                                    AlwaysStoppedAnimation<
                                                        Color>(
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
      description: json['activityNameDescription'] as String,
      estimateHours: (json['estimateHours'] as num).toDouble(),
    );
  }
}

// timesheet_line_by_meeting_uid_model.dart
class TimesheetLineByMeetingUidModel {
  final String id;
  final String description;
  final double hours;
  final String timesheetDate;
  final String projectName;
  final String projectModuleName;
  final String taskName;
  final String projectActivityName;

  TimesheetLineByMeetingUidModel({
    required this.id,
    required this.description,
    required this.hours,
    required this.timesheetDate,
    required this.projectName,
    required this.projectModuleName,
    required this.taskName,
    required this.projectActivityName,
  });

  factory TimesheetLineByMeetingUidModel.fromJson(Map<String, dynamic> json) {
    final timesheet =
        (json['timesheet'] as Map?)?.cast<String, dynamic>() ?? const {};
    final project =
        (json['project'] as Map?)?.cast<String, dynamic>() ?? const {};
    final projectModule =
        (json['projectModule'] as Map?)?.cast<String, dynamic>() ?? const {};
    final task = (json['task'] as Map?)?.cast<String, dynamic>() ?? const {};
    final projectActivity =
        (json['projectActivity'] as Map?)?.cast<String, dynamic>() ?? const {};

    return TimesheetLineByMeetingUidModel(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      timesheetDate: timesheet['timesheetDate'] as String? ?? '',
      projectName: project['name'] as String? ?? '',
      projectModuleName: projectModule['name'] as String? ?? '',
      taskName: task['name'] as String? ?? '',
      projectActivityName: projectActivity['name'] as String? ?? '',
    );
  }
}
