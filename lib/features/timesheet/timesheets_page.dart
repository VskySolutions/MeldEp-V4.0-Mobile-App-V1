import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:html/parser.dart' as parser;

import 'package:test_project/core/dialogs/delete_confirmation_dialog.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/widgets/chip/filter_chip_widget%20.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';
import 'package:test_project/core/widgets/snackbar/custom_snackbar.dart';
import 'package:test_project/features/timesheet/timesheet_service.dart';
import 'package:test_project/features/timesheet/widgets/timesheet_filter.dart';

class MyTimesheet extends StatelessWidget {
  const MyTimesheet({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timesheet Screen',
      home: TimesheetScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  _TimesheetScreenState createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  /// -----------------------------------------------------------------------------
  /// Variable Declarations
  /// -----------------------------------------------------------------------------

  // Loading flags
  bool _isLoading = false;
  bool _isListLoading = true;
  bool _isInitialLoading = true;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;

  // Data (list of timesheet)
  List<TimesheetModel> _timesheetsList = <TimesheetModel>[];
  String? _expandedActivityDetails;
  String? _deletingTimesheetId;
  String? _employeeName = '';

  // Filter
  String? tempCreatedBy = 'Created By Me';
  String? tempEmployeeId;
  String? tempProjectId;
  String? tempModuleId;
  String? tempTaskId;
  DateTime? tempActivityDate;
  String? tempWeekFilter;
  DateTime? tempFromMonth;
  DateTime? tempToMonth;

  // Static Search
  final TextEditingController _staticSearchFilterController =
      TextEditingController();
  bool _isShowStaticSearchField = false;
  Timer? _searchDebounceTimer;

  /// -----------------------------------------------------------------------------
  /// Lifecycle
  /// -----------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetchTimesheets();
    _loadEmployeeName();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _staticSearchFilterController.dispose();
    super.dispose();
  }

  /// -----------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// -----------------------------------------------------------------------------
  ///
  /// Loads the current employee name (for author checks) and updates state.
  void _loadEmployeeName() async {
    _employeeName = await LocalStorage.getEmployeeName();
  }

  /// Fetches a page of timesheets using current filters; appends on isLoadMore.
  Future<void> _fetchTimesheets({
    bool isLoadMore = false,
    bool isSearchLoad = false,
    String searchText = "",
  }) async {
    if (!isLoadMore) {
      setState(() {
        _isInitialLoading = true;
        _currentPage = 1;
      });
    }

    if (isSearchLoad) {
      setState(() {
        _currentPage = 1;
      });
    }

    setState(() => _isListLoading = true);

    final payload = {
      "page": _currentPage,
      "pageSize": 15,
      "sortBy": "",
      "descending": true,
      "searchText": searchText,
      "createdBy": tempCreatedBy,
      "employeeId": tempEmployeeId ?? "",
      "projectId": tempProjectId,
      "projectModuleId": tempModuleId,
      "projectTaskId": tempTaskId ?? "",
      "activityDate":
          tempActivityDate != null ? tempActivityDate!.format() : null,
      "fromDate": tempFromMonth != null ? tempFromMonth!.format() : null,
      "toDate": tempToMonth != null ? tempToMonth!.format() : null,
      "weekFilter": tempWeekFilter ?? '',
    };

    try {
      final response = await TimesheetService.instance.fetchTimesheets(payload);
      if (response.statusCode == 200) {
        final parsed = response.data;
        final List<dynamic> dataList = parsed['data'];
        final fetchedTimesheets =
            dataList.map((json) => TimesheetModel.fromJson(json)).toList();

        setState(() {
          if (_currentPage == 1) {
            _timesheetsList = fetchedTimesheets;
          } else {
            _timesheetsList.addAll(fetchedTimesheets);
          }
          _hasMore = fetchedTimesheets.length == 15;
          _isLoading = false;
          _isListLoading = false;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isListLoading = false;
        _isInitialLoading = false;
      });
    }
  }

  /// Deletes a timesheet by id and refreshes the list on success.
  Future<void> _deleteTimesheet(String id) async {
    Fluttertoast.showToast(
      msg: "Deleting... please wait",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );

    setState(() {
      _deletingTimesheetId = id;
    });

    try {
      final response = await TimesheetService.instance.deleteTimesheet(id);
      if (response.statusCode == 204) {
        showCustomSnackBar(
          context,
          message: 'Timesheet deleted successfully!',
          durationSeconds: 2,
        );
        _fetchTimesheets();
      }
    } catch (e) {
      showCustomSnackBar(
        context,
        message: 'Error: $e',
        backgroundColor: AppColors.ERROR,
      );
    }

    setState(() {
      _deletingTimesheetId = '';
    });
  }

  /// -----------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// -----------------------------------------------------------------------------

  /// Opens the filter dialog and applies selected filters on submit.
  void _onFilterPressed() {
    showDialog(
      context: context,
      builder: (context) {
        return TimesheetFilterPopup(
          initialCreatedBy: tempCreatedBy,
          initialEmployeeId: tempEmployeeId,
          initialProjectId: tempProjectId,
          initialModuleId: tempModuleId,
          initialTaskId: tempTaskId,
          initialActivityDate: tempActivityDate,
          initialWeekFilter: tempWeekFilter,
          initialFromMonth: tempFromMonth,
          initialToMonth: tempToMonth,
          onApplyFilter: (
            newVal1,
            newVal2,
            newVal3,
            newVal4,
            newVal5,
            newVal6,
            newVal7,
            newVal8,
            newVal9,
          ) {
            setState(() {
              tempCreatedBy = newVal1;
              tempEmployeeId = newVal2;
              tempProjectId = newVal3;
              tempModuleId = newVal4;
              tempTaskId = newVal5;
              tempActivityDate = newVal6;
              tempWeekFilter = newVal7;
              tempFromMonth = newVal8;
              tempToMonth = newVal9;
              _currentPage = 1;
              _hasMore = true;
              _timesheetsList.clear();
            });
          },
          onFetchTimesheets: _fetchTimesheets,
        );
      },
    );
  }

  void _onStaticSearchFilterChange(String value) {
    if (_searchDebounceTimer?.isActive ?? false) _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchTimesheets(searchText: value, isSearchLoad: true, isLoadMore: true);
    });
  }

  /// -----------------------------------------------------------------------------
  /// UI Helpers
  /// -----------------------------------------------------------------------------

  List<Widget> _buildFilterChips() {
    final filters = [
      _FilterChipData('Created By', tempCreatedBy,
          () => setState(() => tempCreatedBy = null)),
      _FilterChipData('Employee Name', tempEmployeeId,
          () => setState(() => tempEmployeeId = null)),
      _FilterChipData(
          'Project', tempProjectId, () => setState(() => tempProjectId = null)),
      _FilterChipData(
        'Project Modules',
        tempModuleId,
        () => setState(() => tempModuleId = null),
      ),
      _FilterChipData(
          'Project Tasks', tempTaskId, () => setState(() => tempTaskId = null)),
      _FilterChipData('Activity Date', tempActivityDate,
          () => setState(() => tempActivityDate = null)),
      _FilterChipData('Week Filter', tempWeekFilter,
          () => setState(() => tempWeekFilter = null)),
      _FilterChipData('From Month', tempFromMonth,
          () => setState(() => tempFromMonth = null)),
      _FilterChipData(
          'To Month', tempToMonth, () => setState(() => tempToMonth = null)),
    ];

    return filters
        .where((filter) => filter.value != null)
        .map(
          (filter) => FilterChipWidget(
            label: filter.label,
            value: filter.value,
            onClear: () {
              filter.onClear();
              _fetchTimesheets(); // refresh
            },
          ),
        )
        .toList();
  }

  String _parseHtmlPreview(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return 'No details available';
    }

    try {
      // Check if it's plain text (no HTML tags)
      if (!htmlString.contains('<') || !htmlString.contains('>')) {
        return _truncateText(htmlString, maxLength: 100);
      }

      final document = parser.parse(htmlString);
      final liElements = document.querySelectorAll('li');

      if (liElements.isEmpty) {
        // Handle other HTML elements
        return _truncateText(document.body?.text ?? htmlString, maxLength: 100);
      }

      final firstItemText = _cleanText(liElements[0].text);
      final additionalItems = liElements.length - 1;

      return additionalItems > 0
          ? '$firstItemText (+$additionalItems more)'
          : firstItemText;
    } catch (e) {
      // Fallback for any parsing errors
      return _truncateText(htmlString, maxLength: 100);
    }
  }

  String _cleanText(String text) {
    return text.trim().replaceAll('\n', ' ').replaceAll(RegExp(r'\s{2,}'), ' ');
  }

  String _truncateText(String text, {required int maxLength}) {
    final cleaned = _cleanText(text);

    if (cleaned.length <= maxLength) {
      return cleaned;
    }

    return cleaned.substring(0, maxLength).trim() + '...';
  }

  /// -----------------------------------------------------------------------------
  /// UI
  /// -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusableAppBar(title: "Timesheet"),
      body: _isInitialLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.PRIMARY))
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: _buildFilterChips()),
                        ),
                      ),
                      // ElevatedButton.icon(
                      //   onPressed: _onFilterPressed,
                      //   label: Text(
                      //     'Filter',
                      //     style: TextStyle(color: AppColors.PRIMARY),
                      //   ),
                      //   icon: Icon(Icons.filter_list, color: AppColors.PRIMARY),
                      // ),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                onTap: _onFilterPressed,
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
                    padding:
                        const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: TextFormField(
                      controller: _staticSearchFilterController,
                      onChanged: (value) => _onStaticSearchFilterChange(value),
                      decoration: InputDecoration(
                        labelText: 'Search',
                        hintText: 'Search',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: _isListLoading
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
                    onRefresh: () async {
                      await _fetchTimesheets();
                    },
                    child: _timesheetsList.isEmpty
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
                            itemCount: _timesheetsList.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _timesheetsList.length) {
                                return Column(
                                  children: [
                                    if (_hasMore)
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: _isListLoading
                                              ? null
                                              : () {
                                                  setState(
                                                      () => _currentPage++);
                                                  _fetchTimesheets(
                                                    isLoadMore: true,
                                                  );
                                                },
                                          child: _isListLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            AppColors.PRIMARY),
                                                  ),
                                                )
                                              : const Text(
                                                  'Load More',
                                                  style: TextStyle(
                                                    color: AppColors.PRIMARY,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    if (_timesheetsList.length > 0 && !_hasMore)
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
                                  ],
                                );
                              }

                              final timesheet = _timesheetsList[index];
                              final totalHours = timesheet.timesheetLines
                                  .map((line) => line.hours ?? 0)
                                  .fold(0.0, (prev, element) => prev + element);

                              return Card(
                                elevation: 4,
                                margin: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    // Existing content
                                    Column(
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
                                            children: [
                                              Text(
                                                timesheet.timesheetDate,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Total: ${totalHours.toStringAsFixed(2)} Hrs',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (_employeeName!
                                                          .toLowerCase() ==
                                                      timesheet.createdBy
                                                          .toLowerCase()) ...[
                                                    SizedBox(width: 8),
                                                    Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          4,
                                                        ),
                                                        onTap: () async {
                                                          await context.push(
                                                            '/addTimesheet/${timesheet.id}',
                                                          );
                                                          _fetchTimesheets();
                                                        },
                                                        child: Container(
                                                          height: 25,
                                                          width: 25,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withOpacity(
                                                              0.2,
                                                            ),
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
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Material(
                                                      color: Colors.transparent,
                                                      child:
                                                          _deletingTimesheetId ==
                                                                  timesheet.id
                                                              ? Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                    5,
                                                                  ),
                                                                  child:
                                                                      SizedBox(
                                                                    height: 18,
                                                                    width: 18,
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                      valueColor:
                                                                          AlwaysStoppedAnimation<
                                                                              Color>(
                                                                        Colors
                                                                            .white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              : InkWell(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    4,
                                                                  ),
                                                                  onTap: () {
                                                                    showDeleteConfirmationDialog(
                                                                      context,
                                                                      title:
                                                                          "Delete Confirmation",
                                                                      description:
                                                                          "Are you sure you want to remove this entry permanently?",
                                                                      subDescription:
                                                                          timesheet
                                                                              .timesheetDate,
                                                                      onDelete:
                                                                          () =>
                                                                              _deleteTimesheet(
                                                                        timesheet
                                                                            .id,
                                                                      ),
                                                                    );
                                                                  },
                                                                  child:
                                                                      Container(
                                                                    height: 25,
                                                                    width: 25,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                        0.2,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .circular(
                                                                        4,
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        const Center(
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .delete_outline,
                                                                        size:
                                                                            18,
                                                                        color: AppColors
                                                                            .ERROR,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        ...timesheet.timesheetLines
                                            .asMap()
                                            .entries
                                            .map((
                                          entry,
                                        ) {
                                          final index = entry.key;
                                          final line = entry.value;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Wrap(
                                                      crossAxisAlignment:
                                                          WrapCrossAlignment
                                                              .center,
                                                      spacing: 4,
                                                      runSpacing: 4,
                                                      children: [
                                                        Text(
                                                          line.projectName ??
                                                              '',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons.double_arrow,
                                                          color:
                                                              Colors.grey[600],
                                                          size: 18,
                                                        ),
                                                        Text(
                                                          line.projectModuleName ??
                                                              '',
                                                        ),
                                                        Icon(
                                                          Icons.double_arrow,
                                                          color:
                                                              Colors.grey[600],
                                                          size: 18,
                                                        ),
                                                        Text(
                                                          line.taskName ?? '',
                                                        ),
                                                        if ((line.activityName ??
                                                                '')
                                                            .isNotEmpty) ...[
                                                          Text(
                                                            '(${line.activityName})',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    SizedBox(height: 10),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Flexible(
                                                          child: Row(
                                                            children: [
                                                              Flexible(
                                                                child: RichText(
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  text:
                                                                      TextSpan(
                                                                    style:
                                                                        DefaultTextStyle
                                                                            .of(
                                                                      context,
                                                                    ).style,
                                                                    children: [
                                                                      TextSpan(
                                                                        text:
                                                                            'Activity: ',
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      TextSpan(
                                                                        text:
                                                                            _parseHtmlPreview(
                                                                          line.description,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              GestureDetector(
                                                                onTap: () =>
                                                                    _onDetailsDialogPressed(
                                                                  context,
                                                                  line.description,
                                                                ),
                                                                child:
                                                                    CircleAvatar(
                                                                  radius: 10,
                                                                  backgroundColor:
                                                                      Colors.grey[
                                                                          600],
                                                                  child: Icon(
                                                                    Icons
                                                                        .info_outline,
                                                                    size: 12,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          'Hours: ${line.hours}',
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
                                              if (index !=
                                                  timesheet.timesheetLines
                                                          .length -
                                                      1)
                                                Divider(
                                                  height: 1,
                                                  color: Colors.grey,
                                                ),
                                            ],
                                          );
                                        }),
                                        if (timesheet.createdBy.isNotEmpty)
                                          SizedBox(height: 20),
                                      ],
                                    ),
                                    if (timesheet.createdBy.isNotEmpty)
                                      Positioned(
                                        bottom: 8,
                                        right: 10,
                                        child: Text(
                                          timesheet.createdBy,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/addTimesheet/${null}');
          // context.goNamed('addTimesheet');
          _fetchTimesheets();
        },
        backgroundColor: AppColors.PRIMARY,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

void _onDetailsDialogPressed(BuildContext context, String? htmlContent) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Activity Details'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: htmlContent != null && htmlContent.isNotEmpty
          ? SingleChildScrollView(
              child: Html(
                data: htmlContent,
                style: {
                  "ul": Style(margin: Margins.zero),
                  "li": Style(
                    margin: Margins.only(bottom: 8),
                    listStylePosition: ListStylePosition.outside,
                  ),
                  "p": Style(margin: Margins.zero),
                },
              ),
            )
          : const Text('No details available'),
    ),
  );
}

/// -----------------------------------------------------------------------------
/// Model
/// -----------------------------------------------------------------------------

class TimesheetModel {
  final String id;
  final String timesheetDate;
  final String createdBy;
  final List<TimesheetLineModel> timesheetLines;

  TimesheetModel({
    required this.timesheetDate,
    required this.timesheetLines,
    required this.createdBy,
    required this.id,
  });

  factory TimesheetModel.fromJson(Map<String, dynamic> json) {
    return TimesheetModel(
      id: json['id'],
      timesheetDate: json['timesheetDate'] ?? '',
      createdBy: json['user']?['person']?['fullName'] ?? '',
      timesheetLines: (json['timesheetLines'] as List<dynamic>)
          .map((e) => TimesheetLineModel.fromJson(e))
          .toList(),
    );
  }
}

class TimesheetLineModel {
  final String? projectName;
  final String? projectModuleName;
  final String? taskName;
  final String? activityName;
  final String? description;
  final String? createdBy;
  final double? hours;

  TimesheetLineModel({
    this.projectName,
    this.projectModuleName,
    this.taskName,
    this.activityName,
    this.description,
    this.createdBy,
    this.hours,
  });

  factory TimesheetLineModel.fromJson(Map<String, dynamic> json) {
    return TimesheetLineModel(
      projectName: json['project']?['name'],
      projectModuleName: json['projectModule']?['name'],
      taskName: json['task']?['name'],
      activityName: json['projectActivity']?['name'],
      description: json['description'],
      createdBy: json['user']?['person']?['fullName'],
      hours: (json['hours'] as num?)?.toDouble(),
    );
  }
}

class _FilterChipData {
  final String label;
  final dynamic value;
  final VoidCallback onClear;

  _FilterChipData(this.label, this.value, this.onClear);
}
