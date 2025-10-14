import 'package:flutter/material.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/buttons/custom_outlined_button.dart';
import 'package:test_project/core/widgets/input_field/custom_type_ahead_field.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_service.dart';

class TaskFilterPopup extends StatefulWidget {
  // Initial filter values (incoming)
  final String? initialProjectId;
  final String? initialProjectModuleId;
  final String? initialAssignedToId;
  final String? initialActivityNameId;
  final String? initialActivityStatusId;
  final String? initialTaskStatusId;
  final String? initialActiveStatus;
  final DateTime? initialTargetMonth;

  // Callback shape retained (caller-managed)
  final Function(
    String?, // projectId
    String?, // projectModuleId
    String?, // assignedToId
    String?, // activityNameId
    String?, // activityStatusId
    String?, // taskStatusId
    String?, // activeStatus
    DateTime?, // targetMonth
  ) onApplyFilter;

  final Future<void> Function() onFetchTasks;

  const TaskFilterPopup({
    Key? key,
    required this.initialProjectId,
    required this.initialProjectModuleId,
    required this.initialAssignedToId,
    required this.initialActivityNameId,
    required this.initialActivityStatusId,
    required this.initialTaskStatusId,
    required this.initialActiveStatus,
    required this.initialTargetMonth,
    required this.onApplyFilter,
    required this.onFetchTasks,
  }) : super(key: key);

  @override
  State<TaskFilterPopup> createState() => _TaskFilterPopupState();
}

class _TaskFilterPopupState extends State<TaskFilterPopup> {
  // Local (temp) values inside the popup
  late String? _tempProjectId;
  late String? _tempProjectModuleId;
  late String? _tempAssignedToId;
  late String? _tempActivityNameId;
  late String? _tempActivityStatusId;
  late String? _tempTaskStatusId;
  late String? _tempActiveStatus;
  late DateTime? _tempTargetMonth;

  // Utility
  late String? _employeeId;

  // Dropdowns
  List<Map<String, String>> projectNamesDropdown = [];
  List<Map<String, String>> projectModulesDropdown = [];
  List<Map<String, String>> employeeNamesDropdown = [];
  List<Map<String, String>> activityNamesDropdown = [];
  List<Map<String, String>> activityStatusDropdown = [];
  List<Map<String, String>> taskStatusDropdown = [];
  List<Map<String, String>> activeStatusDropdownValues = const [
    {"id": "Active", "name": "Active"},
    {"id": "Inactive", "name": "Inactive"},
  ];

  // Flags
  bool _isLoading = true;
  bool _isProjectModulesLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _loadInitialData();
    _setEmployeeId();
  }

  void _setEmployeeId() async {
    _employeeId = await LocalStorage.getEmployeeId();
  }

  // Map incoming initial values to local temp state
  void _initializeValues() {
    _tempProjectId = widget.initialProjectId;
    _tempProjectModuleId = widget.initialProjectModuleId;
    _tempAssignedToId = widget.initialAssignedToId;
    _tempActivityNameId = widget.initialActivityNameId;
    _tempActivityStatusId = widget.initialActivityStatusId;
    _tempTaskStatusId = widget.initialTaskStatusId;
    _tempActiveStatus = widget.initialActiveStatus ?? 'Active';
    _tempTargetMonth = widget.initialTargetMonth;
  }

  void _loadInitialData() async {
    try {
      setState(() => _isLoading = true);

      await Future.wait([
        _fetchProjectNameIds(),
        _fetchActivityName(),
        _fetchActivityStatus(),
        _fetchEmployeeNameIds(null),
        _fetchTaskStatus(),
      ]);

      // If project is already temp, load its modules
      if (_tempProjectId != null) {
        await _fetchProjectModuleNameIds(_tempProjectId);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProjectNameIds() async {
    try {
      final response =
          await MyTaskAndActivityService.instance.fetchProjectNameIds();
      final List<dynamic> dataList = response.data;

      final fetchedProjectNames =
          dataList.map((json) => ProjectNamesModel.fromJson(json)).toList();

      setState(() {
        projectNamesDropdown = fetchedProjectNames
            .map((module) => {"id": module.id, "name": module.name})
            .toList()
          ..sort((a, b) => a["name"]
              .toString()
              .toLowerCase()
              .compareTo(b["name"].toString().toLowerCase()));
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _fetchProjectModuleNameIds(String? projectId) async {
    if (projectId == null) {
      setState(() => projectModulesDropdown = []);
      return;
    }

    try {
      setState(() => _isProjectModulesLoading = true);
      final response = await MyTaskAndActivityService.instance
          .fetchProjectModuleNameIds(projectId);
      final List<dynamic> dataList = response.data;

      final fetchedProjectModels =
          dataList.map((json) => ProjectNamesModel.fromJson(json)).toList();

      setState(() {
        projectModulesDropdown = fetchedProjectModels
            .map((module) => {"id": module.id, "name": module.name})
            .toList();
        _isProjectModulesLoading = false;
      });
    } catch (e) {
      setState(() {
        projectModulesDropdown = [];
        _isProjectModulesLoading = false;
      });
    }
  }

  Future<void> _fetchEmployeeNameIds(String? siteId) async {
    try {
      final response =
          await MyTaskAndActivityService.instance.fetchEmployeeNameIds(siteId);
      final List<dynamic> dataList = response.data;

      final fetchedEmployeeNames =
          dataList.map((json) => EmployeeNamesModel.fromJson(json)).toList();

      setState(() {
        employeeNamesDropdown = fetchedEmployeeNames
            .map((module) => {"id": module.id, "name": module.name})
            .toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _fetchActivityName() async {
    try {
      final response =
          await MyTaskAndActivityService.instance.fetchActivityName();
      final List<dynamic> dataList = response.data;

      final fetchedActivityNames =
          dataList.map((json) => ActivityNamesModel.fromJson(json)).toList();

      setState(() {
        activityNamesDropdown = fetchedActivityNames
            .map((module) =>
                {"id": module.id, "name": module.name, "description": module.description})
            .toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _fetchTaskStatus() async {
    try {
      final response =
          await MyTaskAndActivityService.instance.fetchTaskStatus();
      final List<dynamic> dataList = response.data;

      final fetchedActivityStatus =
          dataList.map((json) => ActivityStatusModel.fromJson(json)).toList();

      setState(() {
        taskStatusDropdown = fetchedActivityStatus
            .map((module) => {"id": module.id, "name": module.name})
            .toList();
      });
    } catch (e) {
      // Handle error
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
              // Project Name
              CustomTypeAheadField(
                  items: projectNamesDropdown,
                  selectedId: _tempProjectId,
                  label: "Project Name",
                  enabled: !_isLoading,
                  isLoading: _isLoading,
                  onChanged: (value) {
                    setState(() => _tempProjectId = value);
                    _fetchProjectModuleNameIds(value);
                  },
                  onCleared: () {
                    setState(() {
                      _tempProjectId = null;
                      _tempProjectModuleId = null;
                      projectModulesDropdown = [];
                    });
                  }),
              SizedBox(height: 14),

              // Project Module
              CustomTypeAheadField(
                items: projectModulesDropdown,
                selectedId: _tempProjectModuleId,
                label: "Project Module",
                enabled: projectModulesDropdown.isNotEmpty,
                isLoading: _isProjectModulesLoading,
                onChanged: (value) {
                  setState(() => _tempProjectModuleId = value);
                },
              ),
              SizedBox(height: 14),

              // Activity Owner
              CustomTypeAheadField(
                items: employeeNamesDropdown,
                selectedId: _tempAssignedToId,
                label: "Activity Owner",
                enabled: !_isLoading,
                isLoading: _isLoading,
                onChanged: (value) {
                  setState(() => _tempAssignedToId = value);
                },
              ),
              SizedBox(height: 14),

              // Activity Name
              CustomTypeAheadField(
                items: activityNamesDropdown,
                selectedId: _tempActivityNameId,
                label: "Activity Name",
                enabled: !_isLoading,
                isLoading: _isLoading,
                onChanged: (value) {
                  setState(() => _tempActivityNameId = value);
                },
              ),
              SizedBox(height: 14),

              // Activity Status
              CustomTypeAheadField(
                items: activityStatusDropdown,
                selectedId: _tempActivityStatusId,
                label: "Activity Status",
                enabled: !_isLoading,
                isLoading: _isLoading,
                onChanged: (value) {
                  setState(() => _tempActivityStatusId = value);
                },
              ),
              SizedBox(height: 14),

              CustomTypeAheadField(
                items: taskStatusDropdown,
                selectedId: _tempTaskStatusId,
                label: "Task Status",
                enabled: !_isLoading,
                isLoading: _isLoading,
                onChanged: (value) {
                  setState(() => _tempTaskStatusId = value);
                },
              ),
              SizedBox(height: 14),

              // Status
              CustomTypeAheadField(
                items: activeStatusDropdownValues,
                selectedId: _tempActiveStatus,
                label: "Status",
                enabled: !_isLoading,
                isLoading: _isLoading,
                onChanged: (value) {
                  setState(() => _tempActiveStatus = value);
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
                  null,
                  null,
                  _employeeId,
                  null,
                  null,
                  null,
                  null,
                  null,
                );
                setState(() {
                  _tempProjectId = null;
                  _tempProjectModuleId = null;
                  _tempAssignedToId = _employeeId;
                  _tempActivityNameId = null;
                  _tempActivityStatusId = null;
                  _tempTaskStatusId = null;
                  _tempActiveStatus = null;
                  _tempTargetMonth = null;
                });
                widget.onFetchTasks();
              },
              text: 'Clear',
              color: Colors.black,
            ),
            const SizedBox(width: 8),
            CustomOutlinedButton(
              onPressed: () {
                widget.onApplyFilter(
                  _tempProjectId,
                  _tempProjectModuleId,
                  _tempAssignedToId,
                  _tempActivityNameId,
                  _tempActivityStatusId,
                  _tempTaskStatusId,
                  _tempActiveStatus,
                  _tempTargetMonth,
                );
                Navigator.pop(context);
                widget.onFetchTasks();
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

class ProjectNamesModel {
  final String id;
  final String name;

  ProjectNamesModel({required this.id, required this.name});

  factory ProjectNamesModel.fromJson(Map<String, dynamic> json) {
    return ProjectNamesModel(id: json['id'] ?? '', name: json['name'] ?? '');
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

class ActivityNamesModel {
  final String id;
  final String name;
  final String description;

  ActivityNamesModel(
      {required this.id, required this.name, required this.description});

  factory ActivityNamesModel.fromJson(Map<String, dynamic> json) {
    return ActivityNamesModel(
      id: json['dropdownValue'] ?? '',
      name: json['dropdownValue'] ?? '',
      description: json['description'] ?? '',
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
