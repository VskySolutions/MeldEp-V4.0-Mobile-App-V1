import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import 'package:test_project/core/dialogs/confirmation_dialog.dart';
import 'package:test_project/core/flavor/flavor.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/widgets/chip/filter_chip_widget%20.dart';
import 'package:test_project/core/widgets/custom_snackbar.dart';
import 'package:test_project/core/widgets/dropdown/activity_status_pill_dropdown.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';
import 'package:test_project/features/my_task_and_activity/model/task_and_activity_details_model.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_service.dart';
import 'package:test_project/features/my_task_and_activity/widgets/my_task_and_activity_filter.dart';
import 'package:test_project/navigation/timer_key.dart';

class MyTaskAndActivity extends StatelessWidget {
  const MyTaskAndActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Task And Activity Screen',
      home: TaskAndActivityScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TaskAndActivityScreen extends StatefulWidget {
  const TaskAndActivityScreen({super.key});

  @override
  _TaskAndActivityScreenState createState() => _TaskAndActivityScreenState();
}

class _TaskAndActivityScreenState extends State<TaskAndActivityScreen> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  // Data
  List<ProjectActivityListItem> _taskList = <ProjectActivityListItem>[];
  Set<String> _selectedIds = <String>{};
  List<Map<String, String>> _activityStatusDropdown = [];

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;

  // Loading
  bool _isLoading = false;
  bool _isTaskActivityLoading = false;
  bool _isTaskActivityInitialLoading = false;

  // Filters
  String? _searchProjectId;
  String? _searchProjectModuleId;
  String? _searchAssignedToId;
  String? _searchActivityNameId;
  String? _searchActivityStatusId;
  String? _searchTaskStatusId;
  String? _searchActiveStatus = 'Active';
  DateTime? _searchTargetMonth;

  // Static Search
  final TextEditingController _staticSearchFilterController =
      TextEditingController();
  bool _isShowStaticSearchField = false;
  Timer? _searchDepounceTimer;

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchTasks(isGetEmployeeId: true);
    _fetchActivityStatus();
  }

  @override
  void dispose() {
    _searchDepounceTimer?.cancel();
    _staticSearchFilterController.dispose();
    super.dispose();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Fetches paginated tasks with current filters; supports initial load and load-more.
  Future<void> _fetchTasks({
    bool isGetEmployeeId = false,
    bool isLoadMore = false,
    bool isSearchLoad = false,
    String searchText = "",
  }) async {
    if (_isLoading) return;

    if (!isLoadMore) {
      setState(() {
        _currentPage = 1;
        _isTaskActivityInitialLoading = true;
        _selectedIds.clear();
      });
    }

    if (isSearchLoad) {
      setState(() {
        _currentPage = 1;
        _selectedIds.clear();
      });
    }

    setState(() {
      _isLoading = true;
      _isTaskActivityLoading = true;
    });

    if (isGetEmployeeId) {
      _searchAssignedToId = await LocalStorage.getEmployeeId();
    }

    final payload = {
      "activeStatus": _searchActiveStatus,
      "activityNameIds":
          _searchActivityNameId != null ? [_searchActivityNameId] : [],
      "activityStatusIds":
          _searchActivityStatusId != null ? [_searchActivityStatusId] : [],
      "assignedToIds": _searchAssignedToId != null ? [_searchAssignedToId] : [],
      "descending": false,
      "page": _currentPage,
      "pageSize": 15,
      "projectIds": _searchProjectId != null ? [_searchProjectId] : [],
      "projectModuleIds":
          _searchProjectModuleId != null ? [_searchProjectModuleId] : [],
      "searchText": searchText,
      "sortBy": "project.name",
      "statusIds": _searchTaskStatusId != null ? [_searchTaskStatusId] : [],
    };

    try {
      final response =
          await MyTaskAndActivityService.instance.fetchTasks(payload);

      // `response.data` should be a Map<String, dynamic> matching your API wrapper
      final Map<String, dynamic> parsed =
          (response.data as Map<String, dynamic>);

      // Parse into the typed response object
      final TaskAndActivityDetailsModel listResp =
          TaskAndActivityDetailsModel.fromJson(parsed);

      // Get typed items
      final List<ProjectActivityListItem> fetchedTasks = listResp.data;

      setState(() {
        if (_currentPage == 1) {
          _taskList = fetchedTasks;
        } else {
          _taskList.addAll(fetchedTasks);
        }

        _currentPage++;
        // adapt page-size check to your backend page size (you used 15 earlier)
        _hasMore = fetchedTasks.length == 15;

        _isLoading = false;
        _isTaskActivityLoading = false;
        _isTaskActivityInitialLoading = false;
      });
    } catch (e, st) {
      // handle/paranoid logging
      debugPrint('fetchTasks error: $e\n$st');
      setState(() {
        _isLoading = false;
        _isTaskActivityLoading = false;
        _isTaskActivityInitialLoading = false;
      });
    }
  }

  /// Updates a task's active status after user confirmation and refreshes the list.
  Future<void> _updateTaskStatus(
    String id,
    bool status,
    BuildContext context,
  ) async {
    final userChoice = await showConfirmationDialog(
      context,
      title: "Confirmation",
      message: "Are you sure you want to deactivate this activity?",
      cancelText: "No",
      confirmText: "Yes",
      confirmColor: AppColors.ERROR,
    );
    if (userChoice == false || id.isEmpty) {
      return;
    }

    try {
      final response = await MyTaskAndActivityService.instance
          .makeTaskStatusActiveInactive(id, status);
      if (response.statusCode == 204) {
        showCustomSnackBar(
          context,
          message: 'Task status changed successfully',
        );
        _fetchTasks();
      } else {
        showCustomSnackBar(
          context,
          message: 'Failed to change task status',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e) {
      debugPrint('Change task status error: $e');
      showCustomSnackBar(
        context,
        message: 'Error changing task status',
        backgroundColor: AppColors.ERROR,
      );
    }
  }

  Future<void> _updateActivityStatus(
    String activityId,
    String statusId,
    BuildContext context,
  ) async {
    final Map<String, dynamic> payload = {
      "activityIds": [activityId],
      "activityStatusId": statusId,
    };

    try {
      final response =
          await MyTaskAndActivityService.instance.changeActivityStatus(payload);
      if (response.statusCode == 204) {
        showCustomSnackBar(
          context,
          message: 'Activity status changed successfully',
        );
        _fetchTasks();
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
        _activityStatusDropdown = fetchedActivityStatus
            .map((module) => {"id": module.id, "name": module.name})
            .toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Adds/removes a task from the selection when the checkbox is toggled.
  void _onTaskSelected(bool selected, ProjectActivityListItem task) {
    final id = task.id;
    if (id.isEmpty) return;
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  /// Navigates to Fill Timesheet with selected projectIds and clears selection on success.
  void _onFillTimesheetPressed(BuildContext context) async {
    final allIds = _selectedIds.join(',');
    final isSaveAndClose = await context.push('/fillTimesheet/$allIds/${null}');
    if (isSaveAndClose == true) setState(_selectedIds.clear);
  }

  /// Starts the floating timer for a task if no timer is currently active.
  void _onTimerPressed(
    String projectId,
    String taskName,
    String activityName,
  ) async {
    final isTimerAcitve = await LocalStorage.getActivityIdTimer() ?? "";
    if (isTimerAcitve.isEmpty) {
      draggableTimerKey.currentState?.startActiveTimer(
        projectId,
        taskName,
        activityName,
      );
    } else
      showCustomSnackBar(
        context,
        message: 'Timer is already running!',
        backgroundColor: Colors.red,
      );
  }

  String? _lookupNameById(List<Map<String, String>> items, String id) {
    if (id.isEmpty) return null;
    for (final m in items) {
      if ((m['id'] ?? '') == id) return m['name'];
    }
    return null;
  }

  void _onStaticSearchFilterChange(String value) {
    if (_searchDepounceTimer?.isActive ?? false) _searchDepounceTimer?.cancel();
    _searchDepounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchTasks(searchText: value, isSearchLoad: true, isLoadMore: true);
    });
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI Helpers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Opens the filter dialog and applies selected filters to the task list.
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return TaskFilterPopup(
          initialProjectId: _searchProjectId,
          initialProjectModuleId: _searchProjectModuleId,
          initialAssignedToId: _searchAssignedToId,
          initialActivityNameId: _searchActivityNameId,
          initialActivityStatusId: _searchActivityStatusId,
          initialTaskStatusId: _searchTaskStatusId,
          initialActiveStatus: _searchActiveStatus,
          initialTargetMonth: _searchTargetMonth,
          onApplyFilter: (
            newVal1,
            newVal2,
            newVal3,
            newVal4,
            newVal5,
            newVal6,
            newVal7,
            newVal8,
          ) {
            setState(() {
              _searchProjectId = newVal1;
              _searchProjectModuleId = newVal2;
              _searchAssignedToId = newVal3;
              _searchActivityNameId = newVal4;
              _searchActivityStatusId = newVal5;
              _searchTaskStatusId = newVal6;
              _searchActiveStatus = newVal7;
              _searchTargetMonth = newVal8;
              _currentPage = 1;
              _hasMore = true;
              _selectedIds.clear();
            });
          },
          onFetchTasks: _fetchTasks,
        );
      },
    );
  }

  /// Builds filter chips for all active filters with clear actions.
  List<Widget> _buildFilterChips() {
    final filters = [
      _FilterData('Project Name', _searchProjectId,
          () => setState(() => _searchProjectId = null)),
      _FilterData('Project Module', _searchProjectModuleId,
          () => setState(() => _searchProjectModuleId = null)),
      _FilterData('Activity Owner', _searchAssignedToId,
          () => setState(() => _searchAssignedToId = null)),
      _FilterData('Activity Name', _searchActivityNameId,
          () => setState(() => _searchActivityNameId = null)),
      _FilterData('Activity Status', _searchActivityStatusId,
          () => setState(() => _searchActivityStatusId = null)),
      _FilterData('Task Status', _searchTaskStatusId,
          () => setState(() => _searchTaskStatusId = null)),
      _FilterData('Status', _searchActiveStatus,
          () => setState(() => _searchActiveStatus = null)),
      _FilterData('Target Month', _searchTargetMonth,
          () => setState(() => _searchTargetMonth = null)),
    ];

    return filters
        .where((filter) => filter.value != null)
        .map(
          (filter) => FilterChipWidget(
            label: filter.label,
            value: filter.value,
            onClear: () {
              filter.onClear();
              _fetchTasks();
            },
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusableAppBar(title: "My Task And Activity"),
      body: _isTaskActivityInitialLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.PRIMARY))
          : Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: _buildFilterChips()),
                            ),
                          ),
                          Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      _isShowStaticSearchField
                                          ? _onStaticSearchFilterChange("")
                                          : null;
                                      setState(() {
                                        _staticSearchFilterController.clear();
                                        _isShowStaticSearchField =
                                            !_isShowStaticSearchField;
                                      });
                                    },
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(24),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Icon(
                                        _isShowStaticSearchField
                                            ? Icons.search_off_outlined
                                            : Icons.search,
                                        color: AppColors.PRIMARY,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Colors.grey.shade300,
                                  ),
                                  InkWell(
                                    onTap: _showFilterDialog,
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(24),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Icon(
                                        Icons.filter_alt_outlined,
                                        color: AppColors.PRIMARY,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isShowStaticSearchField)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, bottom: 8),
                        child: TextField(
                          controller: _staticSearchFilterController,
                          onChanged: (value) =>
                              _onStaticSearchFilterChange(value),
                          decoration: InputDecoration(
                            labelText: 'Search',
                            hintText: 'Search',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: _isTaskActivityLoading
                                ? Transform.scale(
                                    scale: 0.4,
                                    child: CircularProgressIndicator(
                                      color: AppColors.PRIMARY,
                                      strokeWidth: 4,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.cancel_outlined),
                                    onPressed: () {
                                      setState(() {
                                        _staticSearchFilterController.clear();
                                      });
                                      _onStaticSearchFilterChange("");
                                    },
                                  ),
                          ),
                        ),
                      ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_circle_down_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Pull down to refresh content",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.PRIMARY,
                        onRefresh: () async => _fetchTasks(),
                        // Always provide a scrollable child so pull-to-refresh works when empty/short
                        child: _taskList.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.3),
                                  Center(
                                    child: Text(
                                      'No Data Available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: _taskList.length + 1,
                                physics: const AlwaysScrollableScrollPhysics(),
                                // shrinkWrap removed to ensure this remains the primary scrollable
                                itemBuilder: (context, index) {
                                  if (index == _taskList.length) {
                                    // Footer
                                    return Column(
                                      children: [
                                        if (_hasMore)
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: _isTaskActivityLoading
                                                  ? null
                                                  : () => _fetchTasks(
                                                      isLoadMore: true),
                                              child: _isTaskActivityLoading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )
                                                  : const Text('Load More'),
                                            ),
                                          ),
                                        if (_taskList.isNotEmpty && !_hasMore)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              "All items loaded",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500),
                                            ),
                                          ),
                                        Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 14, top: 10),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                  Icons
                                                      .arrow_circle_down_outlined,
                                                  size: 14,
                                                  color: Colors.grey.shade500),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Pull down to refresh content",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  final ProjectActivityListItem task =
                                      _taskList[index];

                                  // Use stable unique id for selection
                                  final bool isSelected =
                                      _selectedIds.contains(task.id);

                                  // Local vars used > once (keep fallbacks as in current code)
                                  final String projectId = task.id;

                                  final String assignedToFullName = (task
                                              .assignedTo
                                              ?.person
                                              ?.fullName
                                              ?.isNotEmpty ==
                                          true)
                                      ? task.assignedTo!.person.fullName
                                      : '${task.assignedTo?.person?.firstName ?? ''} ${task.assignedTo?.person?.lastName ?? ''}'
                                          .trim();

                                  final String activityNameDescription = (task
                                              .activityNameDescription
                                              ?.isNotEmpty ==
                                          true)
                                      ? task.activityNameDescription!
                                      : (task.description?.isNotEmpty == true
                                          ? task.description!
                                          : '');

                                  final double? estimateHours =
                                      (task.estimateHours != 0.0)
                                          ? task.estimateHours
                                          : (task.task?.estimateTime != 0.0
                                              ? task.task?.estimateTime
                                              : null);

                                  final bool disableOpen =
                                      task.description.isEmpty;

                                  final String currentId =
                                      (task.activityStatus?.id?.isNotEmpty ==
                                              true)
                                          ? task.activityStatus!.id
                                          : '';

                                  final String currentName = _lookupNameById(
                                          _activityStatusDropdown, currentId) ??
                                      ((task.activityStatus?.dropDownValue
                                                  ?.isNotEmpty ==
                                              true)
                                          ? task.activityStatus!.dropDownValue
                                          : (task.task?.status?.dropDownValue ??
                                              '--'));

                                  return Card(
                                    elevation: 4,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header with actions
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.PRIMARY,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Checkbox(
                                                value: isSelected,
                                                onChanged: (value) {
                                                  if (!disableOpen &&
                                                      currentName
                                                              .toLowerCase() ==
                                                          'open') {
                                                    _onTaskSelected(
                                                        value!, task);
                                                  } else {
                                                    showCustomSnackBar(
                                                      context,
                                                      message:
                                                          'Please add activity details and open the task activity before filling the timesheet.',
                                                      backgroundColor:
                                                          AppColors.WARNING,
                                                      contentColor:
                                                          Colors.black,
                                                    );
                                                  }
                                                },
                                                activeColor: AppColors.PRIMARY,
                                                side: const BorderSide(
                                                  color: Color.fromARGB(
                                                      255, 240, 239, 239),
                                                  width: 2,
                                                ),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              Row(
                                                children: [
                                                  // View
                                                  InkWell(
                                                    onTap: () => context.push(
                                                        '/myTaskAndActivityDetail/$projectId'),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
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
                                                            Icons
                                                                .remove_red_eye_outlined,
                                                            size: 18,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Edit
                                                  InkWell(
                                                    onTap: () async {
                                                      final isSaveAndClose =
                                                          await context.push(
                                                              '/myTaskAndActivityEdit/$projectId');
                                                      if (isSaveAndClose ==
                                                          true) _fetchTasks();
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
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
                                                        child: Icon(Icons.edit,
                                                            size: 18,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  if (isDev)
                                                    const SizedBox(width: 8),
                                                  if (isDev)
                                                    InkWell(
                                                      onTap: () =>
                                                          _onTimerPressed(
                                                              projectId,
                                                              task.taskName,
                                                              task.projectName),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: Container(
                                                        height: 25,
                                                        width: 25,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                              Icons.timer,
                                                              size: 18,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                  const SizedBox(width: 8),
                                                  // Notes
                                                  InkWell(
                                                    onTap: () async {
                                                      final isSaveAndClose =
                                                          await context.push(
                                                              '/myTaskAndActivityNote/$projectId');
                                                      if (isSaveAndClose ==
                                                          true) _fetchTasks();
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
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
                                                            Icons.assignment,
                                                            size: 18,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Block / update status
                                                  InkWell(
                                                    onTap: () =>
                                                        _updateTaskStatus(
                                                            projectId,
                                                            false,
                                                            context),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
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
                                                        child: Icon(Icons.block,
                                                            size: 18,
                                                            color: AppColors
                                                                .ERROR),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        Container(
                                          color: disableOpen ||
                                                  currentName.toLowerCase() !=
                                                      'open'
                                              ? const Color.fromARGB(
                                                  255, 253, 236, 234)
                                              : null,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Wrap(
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: [
                                                      // if (disableOpen ||
                                                      //     currentName
                                                      //             .toLowerCase() !=
                                                      //         'open')
                                                      //   Icon(Icons.circle,
                                                      //       color:
                                                      //           AppColors.ERROR,
                                                      //       size: 18),
                                                      // projectName (inline fallback)
                                                      Text(
                                                        task.projectName
                                                                .isNotEmpty
                                                            ? task.projectName
                                                            : (task.project
                                                                    ?.name ??
                                                                ''),
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Icon(Icons.double_arrow,
                                                          color:
                                                              Colors.grey[600],
                                                          size: 18),
                                                      // projectModuleName (inline fallback)
                                                      if ((task.projectModuleName
                                                                  ?.isNotEmpty ??
                                                              false) ||
                                                          (task
                                                                  .projectModule
                                                                  ?.name
                                                                  ?.isNotEmpty ??
                                                              false))
                                                        Text(
                                                          (task.projectModuleName
                                                                      ?.isNotEmpty ==
                                                                  true)
                                                              ? task
                                                                  .projectModuleName!
                                                              : (task.projectModule
                                                                      ?.name ??
                                                                  ''),
                                                        ),
                                                      Icon(Icons.double_arrow,
                                                          color:
                                                              Colors.grey[600],
                                                          size: 18),
                                                      // taskName (inline fallback)
                                                      Text(task.taskName
                                                              .isNotEmpty
                                                          ? task.taskName
                                                          : (task.task?.name ??
                                                              '')),
                                                      // activity name (top-level 'name' field)
                                                      if (task.name.isNotEmpty)
                                                        Text('(${task.name})',
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                      Tooltip(
                                                        message: activityNameDescription
                                                                .isNotEmpty
                                                            ? activityNameDescription
                                                            : 'No description',
                                                        preferBelow: true,
                                                        child: GestureDetector(
                                                          onTap: () =>
                                                              Fluttertoast
                                                                  .showToast(
                                                            msg:
                                                                "Press and hold to view activity description",
                                                          ),
                                                          child: Icon(
                                                              Icons
                                                                  .info_outline,
                                                              size: 18,
                                                              color: Colors
                                                                  .grey[800]),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Colors.grey),

                                        // bottom row: assigned to, status pill, estimate hours
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Tooltip(
                                                message: assignedToFullName
                                                        .isNotEmpty
                                                    ? assignedToFullName
                                                    : 'Unassigned',
                                                preferBelow: true,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      Fluttertoast.showToast(
                                                    msg:
                                                        "Press and hold to view full name",
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.person,
                                                          size: 18,
                                                          color:
                                                              Colors.grey[700]),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        (assignedToFullName
                                                                .isNotEmpty
                                                            ? assignedToFullName
                                                                .toInitials()
                                                            : '--'),
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(Icons.info_outline,
                                                          size: 18,
                                                          color:
                                                              Colors.grey[800]),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              const Spacer(),

                                              // status pill (inline fallback to task.task.status if activity status empty)
                                              // Container(
                                              //   padding:
                                              //       const EdgeInsets.symmetric(
                                              //           horizontal: 8,
                                              //           vertical: 4),
                                              //   decoration: BoxDecoration(
                                              //     border: Border.all(
                                              //         color: AppColors.PRIMARY),
                                              //     borderRadius:
                                              //         BorderRadius.circular(4),
                                              //   ),
                                              //   child: Text(
                                              //     (task
                                              //                 .activityStatus
                                              //                 ?.dropDownValue
                                              //                 ?.isNotEmpty ==
                                              //             true)
                                              //         ? task.activityStatus!
                                              //             .dropDownValue
                                              //         : (task.task?.status
                                              //                 ?.dropDownValue ??
                                              //             '--'),
                                              //     style: const TextStyle(
                                              //         fontSize: 12),
                                              //   ),
                                              // ),
                                              BuildActivityStatusPillDropdown(
                                                context: context,
                                                currentId: currentId,
                                                currentName: currentName,
                                                disableOpen: disableOpen,
                                                items: _activityStatusDropdown,
                                                onChanged: (newId) {
                                                  _updateActivityStatus(
                                                      projectId,
                                                      newId,
                                                      context);
                                                },
                                              ),

                                              const SizedBox(width: 14),

                                              // estimate hours (uses declared local var)
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time,
                                                      size: 16,
                                                      color: Colors.grey[700]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    estimateHours != null
                                                        ? '${estimateHours.toStringAsFixed(2)} Hrs'
                                                        : '-- Hrs',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    )
                  ],
                ),
                if (_selectedIds.isNotEmpty)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FloatingActionButton(
                          onPressed: () {
                            _onFillTimesheetPressed(context);
                          },
                          backgroundColor: AppColors.PRIMARY,
                          child: Text(
                            'TS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_selectedIds.isNotEmpty)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.ERROR,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '${_selectedIds.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildActivityStatusDropdown({
    required ProjectActivityListItem task,
    required List<Map<String, String>> items,
    required ValueChanged<String> onChanged,
  }) {
    // Current selection from the task (may be absent from items)
    final String? selectedId = task.activityStatus?.id?.isNotEmpty == true
        ? task.activityStatus!.id
        : null;

    // Identify the "Open" option and whether it must be disabled
    final Map<String, String>? openOpt = items.firstWhere(
        (m) => (m['name'] ?? '').toLowerCase() == 'open',
        orElse: () => {});
    final String? openId = openOpt != null ? openOpt['id'] : null;
    final bool disableOpen = (task.description.isEmpty);

    // Only keep values that exist in the dropdown list
    final bool selectedExistsInList =
        selectedId != null && items.any((m) => m['id'] == selectedId);
    final String? effectiveValue = selectedExistsInList ? selectedId : null;

    // Basic pill styling
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.PRIMARY),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: effectiveValue,
          // Show name text even when value is null (no match) via hint
          hint: Text(
            (task.activityStatus?.dropDownValue?.isNotEmpty == true)
                ? task.activityStatus!.dropDownValue
                : (task.task?.status?.dropDownValue ?? '--'),
            style: const TextStyle(fontSize: 12),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items.map((m) {
            final String id = m['id'] ?? '';
            final String name = m['name'] ?? '';
            final bool isOpen = openId != null && id == openId;
            final bool isDisabled = isOpen && disableOpen;

            return DropdownMenuItem<String>(
              value: id,
              enabled: !isDisabled,
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDisabled ? Colors.grey.withOpacity(0.6) : Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (newId) {
            if (newId == null) return;
            // Guard: prevent selecting "Open" when description is empty
            if (disableOpen && newId == openId) return;
            onChanged(newId); // Return the selected id
          },
        ),
      ),
    );
  }
}

// Models
class TaskAndActivityDetailsModel1 {
  final String projectName;
  final String? projectModuleName;
  final String taskName;
  final String? activityName;
  final String assignedToFullName;
  final String activityStatusValue;
  final double? estimateHours;
  final String? targetMonth;
  final String? projectId;
  final String? activityNameDescription;

  TaskAndActivityDetailsModel1({
    required this.projectName,
    this.projectModuleName,
    required this.taskName,
    this.activityName,
    required this.assignedToFullName,
    required this.activityStatusValue,
    this.estimateHours,
    this.targetMonth,
    this.projectId,
    this.activityNameDescription,
  });

  factory TaskAndActivityDetailsModel1.fromJson(Map<String, dynamic> json) {
    return TaskAndActivityDetailsModel1(
      projectName: json['projectName'] ?? '',
      projectModuleName: json['projectModuleName'],
      taskName: json['taskName'] ?? '',
      activityName: json['name'] ?? '',
      assignedToFullName: json['assignedTo']?['person']?['fullName'] ?? '',
      activityStatusValue: json['activityStatus']?['dropDownValue'] ?? '',
      estimateHours: (json['estimateHours'] as num?)?.toDouble(),
      targetMonth: json['targetMonth'],
      projectId: json['id'] ?? '',
      activityNameDescription: json['activityNameDescription'] ?? '',
    );
  }
}

class _FilterData {
  final String label;
  final dynamic value;
  final VoidCallback onClear;

  _FilterData(this.label, this.value, this.onClear);
}
