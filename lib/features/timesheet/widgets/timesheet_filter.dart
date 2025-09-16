import 'package:flutter/material.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/widgets/buttons/custom_outlined_button.dart';
import 'package:test_project/core/widgets/date_picker/date_input_field.dart';
import 'package:test_project/core/widgets/input_field/custom_type_ahead_field.dart';
import 'package:test_project/features/timesheet/timesheet_service.dart';

class TimesheetFilterPopup extends StatefulWidget {
  // Initial filter values (incoming)
  final String? initialCreatedBy;     // searchCreatedBy
  final String? initialEmployeeId;    // searchEmployeeId
  final String? initialProjectId;     // searchProjectId
  final String? initialModuleId;      // searchModuleId
  final String? initialTaskId;        // searchTaskId
  final DateTime? initialActivityDate; // searchActivityDate
  final String? initialWeekFilter;    // searchWeekFilter
  final DateTime? initialFromMonth;   // searchFromMonth
  final DateTime? initialToMonth;     // searchToMonth

  // Callback shape retained (caller-managed order)
  final Function(
    String?,    // createdBy
    String?,    // employeeId
    String?,    // projectId
    String?,    // moduleId
    String?,    // taskId
    DateTime?,  // activityDate
    String?,    // weekFilter
    DateTime?,  // fromMonth
    DateTime?,  // toMonth
  ) onApplyFilter;

  final Future<void> Function() onFetchTimesheets;

  const TimesheetFilterPopup({
    Key? key,
    required this.initialCreatedBy,
    required this.initialEmployeeId,
    required this.initialProjectId,
    required this.initialModuleId,
    required this.initialTaskId,
    required this.initialActivityDate,
    required this.initialWeekFilter,
    required this.initialFromMonth,
    required this.initialToMonth,
    required this.onApplyFilter,
    required this.onFetchTimesheets,
  }) : super(key: key);

  @override
  State<TimesheetFilterPopup> createState() => _TimesheetFilterPopupState();
}

class _TimesheetFilterPopupState extends State<TimesheetFilterPopup> {
  // Selected (local) values inside the popup
  late String? _selectedCreatedBy;
  late String? _selectedEmployeeId;
  late String? _selectedProjectId;
  late String? _selectedModuleId;
  late String? _selectedTaskId;
  late DateTime? _selectedActivityDate;
  late String? _selectedWeekFilter;
  late DateTime? _selectedFromMonth;
  late DateTime? _selectedToMonth;

  // Dropdown data
  List<Map<String, String>> employeeNamesDropdown = [];
  List<Map<String, String>> projectNamesDropdown = [];
  List<Map<String, String>> projectModulesDropdown = [];
  List<Map<String, String>> projectTasksDropdown = [];

  // Date inputs (errors for three date fields)
  final TextEditingController _activityDateController = TextEditingController();
  String? _activityDateError;
  String? _fromMonthError;
  String? _toMonthError;
  // Loading flags
  bool _isLoading = true;

  // Static dropdowns
  static const createdByDropdown = [
    {'id': 'Created By Me', 'name': 'Created By Me'},
    {'id': 'View All', 'name': 'View All'},
  ];
  List<Map<String, String>> weekFilterDropdown = const [
    {'id': 'Last Week', 'name': 'Last Week'},
    {'id': 'This Week', 'name': 'This Week'},
    {'id': 'This Month', 'name': 'This Month'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _loadInitialData();
  }

  // Map incoming initial values to local selected state
  void _initializeValues() {
    _selectedCreatedBy = widget.initialCreatedBy ?? 'Created By Me';
    _selectedEmployeeId = widget.initialEmployeeId;
    _selectedProjectId = widget.initialProjectId;
    _selectedModuleId = widget.initialModuleId;
    _selectedTaskId = widget.initialTaskId;
    _selectedActivityDate = widget.initialActivityDate;
    _selectedWeekFilter = widget.initialWeekFilter;
    _selectedFromMonth = widget.initialFromMonth;
    _selectedToMonth = widget.initialToMonth;

    if (_selectedActivityDate != null) {
      _activityDateController.text = _selectedActivityDate!.format();
    }
  }

  void _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      await Future.wait([_fetchEmployeeNameIds(), _fetchProjectNameIds()]);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEmployeeNameIds() async {
    try {
      final response = await TimesheetService.instance.fetchEmployeeNameIds();
      final List<dynamic> dataList = response.data;

      final fetchedEmployeeNames = dataList
          .map((json) => EmployeeNamesModel.fromJson(json))
          .toList();

      setState(() {
        employeeNamesDropdown = fetchedEmployeeNames
            .map((m) => {"id": m.id, "name": m.name})
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _fetchProjectNameIds() async {
    try {
      final response = await TimesheetService.instance.fetchProjectNameIds();
      final List<dynamic> dataList = response.data;

      final fetchedProjects = dataList
          .map((json) => ProjectNamesModel.fromJson(json))
          .toList();

      setState(() {
        projectNamesDropdown = fetchedProjects
            .map((m) => {"id": m.id, "name": m.name})
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _fetchProjectModuleNameIds() async {
    try {
      final response = await TimesheetService.instance
          .fetchProjectModuleNameIds(_selectedProjectId ?? "");
      final List<dynamic> dataList = response.data;

      final fetchedModules = dataList
          .map((json) => ProjectNamesModel.fromJson(json))
          .toList();

      setState(() {
        projectModulesDropdown = fetchedModules
            .map((m) => {"id": m.id, "name": m.name})
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _fetchProjectTasksNameIds() async {
    try {
      final response = await TimesheetService.instance.fetchProjectTasksNameIds(
        _selectedProjectId ?? "",
        _selectedModuleId ?? "",
      );
      final List<dynamic> dataList = response.data;

      final fetchedTasks = dataList
          .map((json) => ProjectNamesModel.fromJson(json))
          .toList();

      setState(() {
        projectTasksDropdown = fetchedTasks
            .map((m) => {"id": m.id, "name": m.name})
            .toList();
      });
    } catch (_) {}
  }

  void applyWeekFilter(String selected) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (selected == "Last Week") {
      final int weekday = now.weekday;
      final DateTime thisWeekMonday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: weekday - 1));
      start = thisWeekMonday.subtract(Duration(days: 7));
      end = start.add(Duration(days: 5));
    } else if (selected == "This Week") {
      final int weekday = now.weekday;
      start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: weekday - 1));
      end = start.add(Duration(days: 5));
    } else if (selected == "This Month") {
      start = DateTime(now.year, now.month, 1);
      final DateTime firstOfNextMonth = DateTime(now.year, now.month + 1, 1);
      end = firstOfNextMonth.subtract(Duration(days: 1));
    } else {
      start = DateTime(now.year, now.month, now.day);
      end = start;
    }
    start = DateTime(start.year, start.month, start.day, 0, 0, 0);
    end = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    setState(() {
      _selectedWeekFilter = selected;
      _selectedFromMonth = start;
      _selectedToMonth = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter'),
      backgroundColor: Colors.white,
      content: SizedBox(
      width: MediaQuery.of(context).size.width * 0.95,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Created By
            CustomTypeAheadField(
              items: createdByDropdown,
              selectedId: _selectedCreatedBy,
              label: "Created By",
              enabled: !_isLoading,
              isLoading: _isLoading,
              onChanged: (value) => setState(() => _selectedCreatedBy = value),
            ),
            SizedBox(height: 14),

            // Employee Name
            CustomTypeAheadField(
              items: employeeNamesDropdown,
              selectedId: _selectedEmployeeId,
              label: "Employee Name",
              enabled: _selectedCreatedBy == "View All",
              isLoading: _isLoading,
              onChanged: (value) => setState(() => _selectedEmployeeId = value),
            ),
            SizedBox(height: 14),

            // Project
            CustomTypeAheadField(
              items: projectNamesDropdown,
              selectedId: _selectedProjectId,
              label: "Project",
              enabled: !_isLoading,
              isLoading: _isLoading,
              onChanged: (value) {
                setState(() {
                  _selectedProjectId = value;
                });
                _fetchProjectModuleNameIds();
              },
            ),
            SizedBox(height: 14),

            // Project Module
            CustomTypeAheadField(
              items: projectModulesDropdown,
              selectedId: _selectedModuleId,
              label: "Project Module",
              enabled: _selectedProjectId != null,
              isLoading: _isLoading,
              onChanged: (value) {
                setState(() {
                  _selectedModuleId = value;
                });
                _fetchProjectTasksNameIds();
              },
            ),
            SizedBox(height: 14),

            // Project Task
            CustomTypeAheadField(
              items: projectTasksDropdown,
              selectedId: _selectedTaskId,
              label: "Project Task",
              enabled: _selectedProjectId != null && _selectedModuleId != null,
              isLoading: _isLoading,
              onChanged: (value) => setState(() => _selectedTaskId = value),
            ),
            SizedBox(height: 14),

            // Activity Date
            DateInputField(
              labelText: 'Activity Date',
              initialDate: _selectedActivityDate,
              onDateSelected: (date) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedActivityDate = date;
                    });
                  }
                });
              },
              onDateError: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _activityDateError = value;
                    });
                  }
                });
              },
            ),
            SizedBox(height: 14),

            // Week Filter
            CustomTypeAheadField(
              items: weekFilterDropdown,
              selectedId: _selectedWeekFilter,
              label: "Week Filter",
              enabled: !_isLoading,
              isLoading: _isLoading,
              onChanged: (value) => {applyWeekFilter(value ?? "")},
            ),
            SizedBox(height: 14),

            // From Date
            DateInputField(
              labelText: 'From Date',
              initialDate: _selectedFromMonth,
              onDateSelected: (date) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedFromMonth = date;
                    });
                  }
                });
              },
              onDateError: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _fromMonthError = value;
                    });
                  }
                });
              },
            ),
            SizedBox(height: 14),

            // To Date
            DateInputField(
              labelText: 'To Date',
              initialDate: _selectedToMonth,
              onDateSelected: (date) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedToMonth = date;
                    });
                  }
                });
              },
              onDateError: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _toMonthError = value;
                    });
                  }
                });
              },
            ),
          ],
        ),
      ),
      ),
      actions: [
        Row(
          children: [
            CustomOutlinedButton(
              onPressed: () => Navigator.pop(context),
              text: 'Close',
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            CustomOutlinedButton(
              onPressed: () {
                widget.onApplyFilter(
                  'Created By Me',
                  null,
                  null,
                  null,
                  null,
                  null,
                  null,
                  null,
                  null,
                );
                setState(() {
                  _selectedCreatedBy = 'Created By Me';
                  _selectedEmployeeId = "";
                  _selectedProjectId = "";
                  _selectedModuleId = "";
                  _selectedTaskId = "";
                  _selectedActivityDate = null;
                  _selectedWeekFilter = "";
                  _selectedFromMonth = null;
                  _selectedToMonth = null;
                });
                widget.onFetchTimesheets();
              },
              text: 'Clear',
              color: Colors.black,
            ),
            const SizedBox(width: 8),
            CustomOutlinedButton(
              onPressed: () {
                widget.onApplyFilter(
                  _selectedCreatedBy,
                  _selectedEmployeeId,
                  _selectedProjectId,
                  _selectedModuleId,
                  _selectedTaskId,
                  _selectedActivityDate,
                  _selectedWeekFilter,
                  _selectedFromMonth,
                  _selectedToMonth,
                );
                Navigator.pop(context);
                widget.onFetchTimesheets();
              },
              text: 'Search',
              color: AppColors.PRIMARY,
              isLoading: _isLoading,
            ),
          ],
        ),
      ],
    );
  }
}

class EmployeeNamesModel {
  final String id;
  final String name;

  EmployeeNamesModel({required this.id, required this.name});

  factory EmployeeNamesModel.fromJson(Map<String, dynamic> json) {
    return EmployeeNamesModel(
      id: json['id'] ?? '',
      name: json['person']?['fullName'] ?? '',
    );
  }
}

class ProjectNamesModel {
  final String id;
  final String name;

  ProjectNamesModel({required this.id, required this.name});

  factory ProjectNamesModel.fromJson(Map<String, dynamic> json) {
    return ProjectNamesModel(id: json['id'] ?? '', name: json['name'] ?? '');
  }
}
