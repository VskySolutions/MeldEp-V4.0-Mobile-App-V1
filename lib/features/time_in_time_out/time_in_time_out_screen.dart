import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/widgets/chip/filter_chip_widget%20.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';
import 'package:test_project/features/time_in_time_out/time_in_time_out_service.dart';
import 'package:test_project/features/time_in_time_out/widgets/time_in_time_out_filter.dart';

class TimeInTimeOutScreen extends StatefulWidget {
  const TimeInTimeOutScreen({super.key});

  @override
  State<TimeInTimeOutScreen> createState() => _TimeInTimeOutScreenState();
}

class _TimeInTimeOutScreenState extends State<TimeInTimeOutScreen> {
  /// -----------------------------------------------------------------------------
  /// Variable Declarations
  /// -----------------------------------------------------------------------------

  // Loading flags
  bool _isTimeDataLoading = false;
  bool _isInitialLoading = false;

  // Pagination
  int _currentPage = 1;
  final int _pageSize = 15;
  bool _hasMore = true;

  // Role flag
  bool _isAdminRole = false;

  // Filters (search- prefixed)
  String? _searchCreatedBy = 'Created By Me';
  String? _searchEmployeeId;
  String? _searchShiftId;
  DateTime? _searchFromDate;
  DateTime? _searchToDate;

  // Display names for chips
  String? _employeeNameDisplay;
  String? _shiftNameDisplay;
  String? _createdByDisplay = 'Created By Me';

  // Data (lists end with List)
  List<TimeInOutRecord> _timeInOutRecordsList = <TimeInOutRecord>[];

  /// -----------------------------------------------------------------------------
  /// Lifecycle
  /// -----------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadTimeInOutRecords();
    _loadAdminRoleFlag();
  }

  /// -----------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// -----------------------------------------------------------------------------
  /// Loads admin role flag from stored roles and updates UI state.
  void _loadAdminRoleFlag() async {
    final List<String> roles = await LocalStorage.getRoles() ?? [];

    final bool isPrivilegedRole = roles.any(
      (role) =>
          role == 'system-super-admin' ||
          role == 'site-super-admin' ||
          role == 'admin',
    );

    setState(() {
      _isAdminRole = isPrivilegedRole;
    });
  }

  /// Loads a page of time-in/time-out records using current filters; appends on isLoadMore.
  Future<void> _loadTimeInOutRecords({bool isLoadMore = false}) async {
    if (_isTimeDataLoading) return;

    if (!isLoadMore) {
      setState(() {
        _currentPage = 1;
        _isInitialLoading = true;
      });
    }

    setState(() => _isTimeDataLoading = true);

    final payload = {
      "_searchCreatedBy": _searchCreatedBy ?? "Created By Me",
      "descending": true,
      "_searchEmployeeId": _searchEmployeeId ?? "",
      "_searchFromDate":
          _searchFromDate != null ? _searchFromDate!.format() : null,
      "page": _currentPage,
      "_pageSize": _pageSize,
      "searchText": "",
      "_searchShiftId": _searchShiftId ?? "",
      "sortBy": "createdOnUtc",
      "_searchToDate": _searchToDate != null ? _searchToDate!.format() : null,
    };

    try {
      final res = await TimeInTimeOutService.instance.fetchTimeData(payload);

      if (res.statusCode == 200) {
        final body = res.data;
        final List<dynamic> data = body['data'] ?? <dynamic>[];
        final fetched = data
            .map((e) => TimeInOutRecord.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          if (_currentPage == 1) {
            _timeInOutRecordsList = fetched;
          } else {
            _timeInOutRecordsList.addAll(fetched);
          }

          // update pagination
          _hasMore = fetched.length == _pageSize;
          if (_hasMore) _currentPage++;
          // else keep _currentPage as-is

          _isTimeDataLoading = false;
          _isInitialLoading = false;
        });
      } else {
        setState(() {
          _isTimeDataLoading = false;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint('fetchTimeData error: $e');
      setState(() {
        _isTimeDataLoading = false;
        _isInitialLoading = false;
      });
    }
  }

  /// -----------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// -----------------------------------------------------------------------------

  /// -----------------------------------------------------------------------------
  /// UI Helpers
  /// -----------------------------------------------------------------------------
  /// Opens the filter dialog and applies selected filters on submit.
  void _onFilterPressed() async {
    // open popup and pass initial values, popup will fetch employees/shifts
    showDialog(
      context: context,
      builder: (ctx) => TimeInTimeOutFilter(
        initialCreatedBy: _searchCreatedBy,
        initialEmployeeId: _searchEmployeeId,
        initialEmployeeName: _employeeNameDisplay,
        initialShiftId: _searchShiftId,
        initialShiftName: _shiftNameDisplay,
        initialFromDate: _searchFromDate,
        initialToDate: _searchToDate,
        isPrivilegedRole: _isAdminRole,
        onApplyFilter: (
          newCreatedBy,
          newEmployeeId,
          newEmployeeName,
          newShiftId,
          newShiftName,
          newFromDate,
          newToDate,
        ) {
          setState(() {
            _searchCreatedBy = newCreatedBy;
            _createdByDisplay = newCreatedBy;
            _searchEmployeeId = newEmployeeId;
            _employeeNameDisplay = newEmployeeName;
            _searchShiftId = newShiftId;
            _shiftNameDisplay = newShiftName;
            _searchFromDate = newFromDate;
            _searchToDate = newToDate;

            // reset pagination and data
            _currentPage = 1;
            _hasMore = true;
            _timeInOutRecordsList.clear();
          });

          // fetch results using new filters
          _loadTimeInOutRecords();
        },
        onFetch: null,
      ),
    );
  }

  /// Builds active filter chips and refreshes the list on clear.
  List<Widget> _buildFilterChips() {
    final filters = [
      _FilterChipData(
        'Created By',
        _createdByDisplay,
        () => setState(() {
          _searchCreatedBy = _createdByDisplay = null;
        }),
      ),
      _FilterChipData(
        'Employee',
        _employeeNameDisplay,
        () => setState(() {
          _searchEmployeeId = _employeeNameDisplay = null;
        }),
      ),
      _FilterChipData(
        'Shift',
        _shiftNameDisplay,
        () => setState(() {
          _searchShiftId = _shiftNameDisplay = null;
        }),
      ),
      _FilterChipData(
        'From Date',
        _searchFromDate,
        () => setState(() {
          _searchFromDate = null;
        }),
      ),
      _FilterChipData(
        'To Date',
        _searchToDate,
        () => setState(() {
          _searchToDate = null;
        }),
      ),
    ];

    return filters
        .where((f) => f.value != null)
        .map(
          (f) => FilterChipWidget(
            label: f.label,
            value: f.value,
            onClear: () {
              f.onClear();
              _currentPage = 1;
              _hasMore = true;
              _timeInOutRecordsList.clear();
              _loadTimeInOutRecords();
            },
          ),
        )
        .toList();
  }

  /// -----------------------------------------------------------------------------
  /// UI
  /// -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusableAppBar(title: 'Time-in Time-out'),
      body: Column(
        children: [
          // Filters row with chips + filter button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: _buildFilterChips()),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _onFilterPressed,
                  label: const Text(
                    'Filter',
                    style: TextStyle(color: AppColors.PRIMARY),
                  ),
                  icon: const Icon(Icons.filter_list, color: AppColors.PRIMARY),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.PRIMARY,
              onRefresh: () async {
                _currentPage = 1;
                _hasMore = true;
                await _loadTimeInOutRecords();
              },
              child: _isInitialLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.PRIMARY,
                      ),
                    )
                  : _timeInOutRecordsList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: const Center(
                                child: Text(
                                  'No Data Available',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _timeInOutRecordsList.length + 1,
                          itemBuilder: (ctx, i) {
                            if (i == _timeInOutRecordsList.length) {
                              // Load more button
                              return Column(
                                children: [
                                  if (_hasMore)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12.0,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isTimeDataLoading
                                              ? null
                                              : () => _loadTimeInOutRecords(
                                                  isLoadMore: true),
                                          child: _isTimeDataLoading
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
                                    ),
                                  if (_timeInOutRecordsList.length > 0 &&
                                      !_hasMore)
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
                                    margin:
                                        EdgeInsets.only(bottom: 14, top: 10),
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

                            final r = _timeInOutRecordsList[i];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              elevation: 3,
                              child: Stack(
                                children: [
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
                                              r.timeInDate ?? "",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    onTap: () async {
                                                      context.push(
                                                        '/timeInTimeOutDetail/${r.id ?? ""}',
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
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Time In - Break - Time Out - Actual Hours row
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.login,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  r.timeInStr ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),

                                                // Show break if not 0.00
                                                if (r.totalBreak != null &&
                                                    (r.totalBreak ?? 0) >
                                                        0) ...[
                                                  SizedBox(width: 4),
                                                  Text('-'),
                                                  SizedBox(width: 4),
                                                  Text("["),
                                                  Icon(
                                                    Icons.local_cafe,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '${r.totalBreak?.toStringAsFixed(2) ?? '0.00'}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text("]"),
                                                  SizedBox(width: 4),
                                                ],

                                                // Time Out
                                                if (r.totalHours
                                                        ?.toStringAsFixed(
                                                      2,
                                                    ) !=
                                                    "0.00") ...[
                                                  Text('-'),
                                                  SizedBox(width: 4),
                                                  Icon(
                                                    Icons.logout,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    r.timeOutStr ?? '',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],

                                                // Actual Hours with equals sign
                                                if (r.actualHours != null &&
                                                    (r.actualHours ?? 0) >
                                                        0) ...[
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '= ${r.actualHours?.toStringAsFixed(2) ?? '0.00'} Hrs.',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),

                                            // Shift only if not null
                                            if (r.shift != null)
                                              if (r.shift!.isNotEmpty) ...[
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                        'Shift: ${r.shift ?? ''}'),
                                                  ],
                                                ),
                                              ],
                                          ],
                                        ),
                                      ),
                                      if (_isAdminRole) SizedBox(height: 20),
                                    ],
                                  ),

                                  // Employee name in bottom right
                                  if (_isAdminRole)
                                    Positioned(
                                      bottom: 8,
                                      right: 12,
                                      child: Text(
                                        r.employeeName ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
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
    );
  }
}

/// -----------------------------------------------------------------------------
/// Model
/// -----------------------------------------------------------------------------

class TimeInOutRecord {
  final String? id;
  final String? timeInDate;
  final String? timeOutDate;
  final String? timeInStr;
  final String? timeOutStr;
  final double? totalHours;
  final double? totalBreak;
  final double? actualHours;
  final String? employeeName;
  final String? shift;

  TimeInOutRecord({
    this.id,
    this.timeInDate,
    this.timeOutDate,
    this.timeInStr,
    this.timeOutStr,
    this.totalHours,
    this.totalBreak,
    this.actualHours,
    this.employeeName,
    this.shift,
  });

  factory TimeInOutRecord.fromJson(Map<String, dynamic> json) {
    return TimeInOutRecord(
      id: json['id'] as String?,
      timeInDate: json['timeInDate'] as String?,
      timeOutDate: json['timeOutDate'] as String?,
      timeInStr: json['timeInStr'] as String?,
      timeOutStr: json['timeOutStr'] as String?,
      totalHours: (json['totalHours'] as num?)?.toDouble(),
      totalBreak: (json['totalBreak'] as num?)?.toDouble(),
      actualHours: (json['actualHours'] as num?)?.toDouble(),
      employeeName: json['employee']?['person']?['fullName'] as String?,
      shift: json['shiftName'] as String? ?? json['shift'] as String? ?? '',
    );
  }
}

class _FilterChipData {
  final String label;
  final dynamic value;
  final VoidCallback onClear;

  _FilterChipData(this.label, this.value, this.onClear);
}
