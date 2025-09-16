import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import 'package:test_project/core/dialogs/confirmation_dialog.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/widgets/chip/filter_chip_widget%20.dart';
import 'package:test_project/core/widgets/custom_snackbar.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';
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
  List<ProjectTaskActivityModel> _taskList = <ProjectTaskActivityModel>[];
  List<ProjectTaskActivityModel> _selectedTasks = <ProjectTaskActivityModel>[];

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

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchTasks(isGetEmployeeId: true);
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Fetches paginated tasks with current filters; supports initial load and load-more.
  Future<void> _fetchTasks({
    bool isGetEmployeeId = false,
    bool isLoadMore = false,
  }) async {
    if (_isLoading) return;

    if (!isLoadMore) {
      setState(() {
        _currentPage = 1;
        _isTaskActivityInitialLoading = true;
        _selectedTasks = [];
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
      "searchText": "",
      "sortBy": "project.name",
      "statusIds": _searchTaskStatusId != null ? [_searchTaskStatusId] : [],
    };

    try {
      final response = await MyTaskAndActivityService.instance.fetchTasks(
        payload,
      );
      final parsed = response.data;
      final List<dynamic> dataList = parsed['data'];

      final fetchedTasks = dataList
          .map((json) => ProjectTaskActivityModel.fromJson(json))
          .toList();

      setState(() {
        if (_currentPage == 1) {
          _taskList = fetchedTasks;
        } else {
          _taskList.addAll(fetchedTasks);
        }
        _currentPage++;
        _hasMore = fetchedTasks.length == 15;
        _isLoading = false;
        _isTaskActivityLoading = false;
        _isTaskActivityInitialLoading = false;
      });
    } catch (e) {
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

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Adds/removes a task from the selection when the checkbox is toggled.
  void _onTaskSelected(bool selected, ProjectTaskActivityModel task) {
    setState(() {
      if (selected) {
        _selectedTasks.add(task);
      } else {
        _selectedTasks.remove(task);
      }
    });
  }

  /// Navigates to Fill Timesheet with selected projectIds and clears selection on success.
  void _onFillTimesheetPressed(BuildContext context) async {
    String allIds = _selectedTasks.map((task) => task.projectId).join(',');
    final isSaveAndClose = await context.push('/fillTimesheet/$allIds/${null}');
    if (isSaveAndClose == true) setState(() => _selectedTasks = []);
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
              _taskList.clear();
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
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: _buildFilterChips()),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showFilterDialog,
                            label: Text(
                              'Filter',
                              style: TextStyle(color: AppColors.PRIMARY),
                            ),
                            icon: Icon(
                              Icons.filter_list,
                              color: AppColors.PRIMARY,
                            ),
                          ),
                        ],
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
                        onRefresh: () async {
                          await _fetchTasks();
                        },
                        child: _taskList.isEmpty
                            ? Center(
                                child: Text(
                                  'No Data Available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _taskList.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _taskList.length) {
                                    return Column(
                                      children: [
                                        if (_hasMore)
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                _isTaskActivityLoading
                                                    ? null
                                                    : _fetchTasks(
                                                        isLoadMore: true,
                                                      );
                                              },
                                              child: _isTaskActivityLoading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          AppColors.PRIMARY,
                                                        ),
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Load More',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.PRIMARY,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        if (_taskList.length > 0 && !_hasMore)
                                          Container(
                                            margin: EdgeInsets.only(top: 6),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "All items loaded",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Container(
                                          margin: EdgeInsets.only(
                                            bottom: 14,
                                            top: 10,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .arrow_circle_down_outlined,
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
                                      ],
                                    );
                                  }

                                  final task = _taskList[index];
                                  final isSelected = _selectedTasks.contains(
                                    task,
                                  );

                                  return Card(
                                    elevation: 4,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.PRIMARY,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                value: isSelected,
                                                onChanged: (value) =>
                                                    _onTaskSelected(
                                                        value!, task),
                                                activeColor: AppColors.PRIMARY,
                                                side: BorderSide(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    240,
                                                    239,
                                                    239,
                                                  ),
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
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        4,
                                                      ),
                                                      onTap: () async {
                                                        context.push(
                                                          '/myTaskAndActivityDetail/${task.projectId ?? ""}',
                                                        );
                                                      },
                                                      child: Container(
                                                        height: 25,
                                                        width: 25,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            4,
                                                          ),
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons
                                                                .remove_red_eye_outlined,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        4,
                                                      ),
                                                      onTap: () async {
                                                        final isSaveAndClose =
                                                            await context.push(
                                                          '/myTaskAndActivityEdit/${task.projectId ?? ""}',
                                                        );
                                                        if (isSaveAndClose ==
                                                            true) _fetchTasks();
                                                      },
                                                      child: Container(
                                                        height: 25,
                                                        width: 25,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            4,
                                                          ),
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.edit,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        4,
                                                      ),
                                                      onTap: () =>
                                                          _onTimerPressed(
                                                        task.projectId ?? "",
                                                        task.taskName,
                                                        task.projectName,
                                                      ),
                                                      child: Container(
                                                        height: 25,
                                                        width: 25,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            4,
                                                          ),
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.timer,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        4,
                                                      ),
                                                      onTap: () async {
                                                        final isSaveAndClose =
                                                            await context.push(
                                                          '/myTaskAndActivityNote/${task.projectId ?? ""}',
                                                        );
                                                        if (isSaveAndClose ==
                                                            true) _fetchTasks();
                                                      },
                                                      child: Container(
                                                        height: 25,
                                                        width: 25,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            4,
                                                          ),
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.assignment,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        4,
                                                      ),
                                                      onTap: () async {
                                                        _updateTaskStatus(
                                                          task.projectId ?? "",
                                                          false,
                                                          context,
                                                        );
                                                      },
                                                      child: Container(
                                                        height: 25,
                                                        width: 25,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            4,
                                                          ),
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.block,
                                                            size: 18,
                                                            color:
                                                                AppColors.ERROR,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: 4,
                                            left: 10,
                                            right: 10,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Checkbox(
                                              //   value: isSelected,
                                              //   onChanged: (value) =>
                                              //       _onTaskSelected(value!, task),
                                              //   activeColor: AppColors.PRIMARY,
                                              // ),
                                              Expanded(
                                                child: Wrap(
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children: [
                                                    Text(
                                                      task.projectName,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.double_arrow,
                                                      color: Colors.grey[600],
                                                      size: 18,
                                                    ),
                                                    Text(
                                                      task.projectModuleName ??
                                                          '',
                                                    ),
                                                    Icon(
                                                      Icons.double_arrow,
                                                      color: Colors.grey[600],
                                                      size: 18,
                                                    ),
                                                    Text(task.taskName),
                                                    Text(
                                                      '(${task.activityName})',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Divider(),
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: 10,
                                            right: 10,
                                            bottom: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              // Row(
                                              //   children: [
                                              //     Icon(
                                              //       Icons.calendar_today,
                                              //       size: 16,
                                              //       color: Colors.grey[700],
                                              //     ),
                                              //     SizedBox(width: 4),
                                              //     Text(task.targetMonth ?? ''),
                                              //   ],
                                              // ),
                                              // SizedBox(width: 14),
                                              Tooltip(
                                                message:
                                                    task.assignedToFullName,
                                                preferBelow: true,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          "Press and hold to view full name",
                                                      toastLength:
                                                          Toast.LENGTH_SHORT,
                                                      gravity:
                                                          ToastGravity.BOTTOM,
                                                    );
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        size: 18,
                                                        color: Colors.grey[700],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        task.assignedToFullName
                                                            .toInitials(),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons.info_outline,
                                                        size: 18,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              Spacer(),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: AppColors.PRIMARY,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  task.activityStatusValue,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 14),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 16,
                                                    color: Colors.grey[700],
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '${task.estimateHours ?? ''} Hrs',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
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
                    ),
                  ],
                ),
                if (_selectedTasks.isNotEmpty)
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
                        if (_selectedTasks.isNotEmpty)
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
                                '${_selectedTasks.length}',
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
}

// Models
class ProjectTaskActivityModel {
  final String projectName;
  final String? projectModuleName;
  final String taskName;
  final String? activityName;
  final String assignedToFullName;
  final String activityStatusValue;
  final double? estimateHours;
  final String? targetMonth;
  final String? projectId;

  ProjectTaskActivityModel({
    required this.projectName,
    this.projectModuleName,
    required this.taskName,
    this.activityName,
    required this.assignedToFullName,
    required this.activityStatusValue,
    this.estimateHours,
    this.targetMonth,
    this.projectId,
  });

  factory ProjectTaskActivityModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskActivityModel(
      projectName: json['projectName'] ?? '',
      projectModuleName: json['projectModuleName'],
      taskName: json['taskName'] ?? '',
      activityName: json['name'] ?? '',
      assignedToFullName: json['assignedTo']?['person']?['fullName'] ?? '',
      activityStatusValue: json['activityStatus']?['dropDownValue'] ?? '',
      estimateHours: (json['estimateHours'] as num?)?.toDouble(),
      targetMonth: json['targetMonth'],
      projectId: json['id'] ?? '',
    );
  }
}

class _FilterData {
  final String label;
  final dynamic value;
  final VoidCallback onClear;

  _FilterData(this.label, this.value, this.onClear);
}
