import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/widgets/chip/filter_chip_widget%20.dart';
import 'package:test_project/features/org_management/apply_leave/widgets/apply_leave_bottom_card.dart';
import 'package:test_project/features/org_management/apply_leave/widgets/apply_leave_filter.dart';
import 'package:test_project/features/org_management/org_management_service.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  /// -----------------------------------------------------------------------------
  /// Variable Declarations
  /// -----------------------------------------------------------------------------
  // Loading flags
  bool _isLeaveDataLoading = false;
  bool _isInitialLoading = false;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;

  // Role flag
  bool _isAdminRole = false;

  // Filters
  String? _searchStatusId;
  String? _searchCategoryId;
  DateTime? _searchAppliedDate;
  String? _searchYear = DateTime.now().year.toString();

  // Static Search
  final TextEditingController _staticSearchFilterController =
      TextEditingController();
  bool _isShowStaticSearchField = false;
  Timer? _searchDebounceTimer;

  // Data (lists end with List)
  List<LeaveRecord> _leaveRecordsList = <LeaveRecord>[];

  /// -----------------------------------------------------------------------------
  /// Lifecycle
  /// -----------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadAdminRoleFlag();
    _loadLeaveRecords();
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
  /// Loads admin role flag based on stored roles and updates UI state.
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

  /// Loads a page of leave records using current filters; appends on isLoadMore.
  Future<void> _loadLeaveRecords({
    bool isLoadMore = false,
    bool isSearchLoad = false,
    String? searchText,
  }) async {
    if (_isLeaveDataLoading) return;

    if (!isLoadMore) {
      setState(() {
        _currentPage = 1;
        _isInitialLoading = true;
      });
    }

    if (isSearchLoad) {
      setState(() {
        _currentPage = 1;
      });
    }

    setState(() {
      _isLeaveDataLoading = true;
    });

    final payload = {
      "createdOnUtc":
          _searchAppliedDate != null ? _searchAppliedDate!.format() : null,
      "descending": true,
      "leaveCategoryId": _searchCategoryId != null ? [_searchCategoryId] : [],
      "page": _currentPage,
      "pageSize": 15,
      "personIds": [],
      "searchText": searchText ?? "",
      "sortBy": "createdOnUtc",
      "statusIds": _searchStatusId != null ? [_searchStatusId] : [],
      "years": _searchYear,
    };

    try {
      final response = await OrgManagementService.instance.fetchLeaveData(
        payload,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final List<dynamic> data = body['data'];
        final fetchedLeaves = data
            .map((e) => LeaveRecord.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          if (_currentPage == 1) {
            _leaveRecordsList = fetchedLeaves;
          } else {
            _leaveRecordsList.addAll(fetchedLeaves);
          }

          _currentPage++;
          _hasMore = fetchedLeaves.length == 15;

          _isLeaveDataLoading = false;
          _isInitialLoading = false;
        });
      } else {
        setState(() {
          _isLeaveDataLoading = false;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint('fetchLeaveData error: $e');
      setState(() {
        _isLeaveDataLoading = false;
        _isInitialLoading = false;
      });
    }
  }

  /// -----------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// -----------------------------------------------------------------------------
  /// Opens the filter dialog and applies selected filters on submit.
  void _onFilterPressed() {
    showDialog(
      context: context,
      builder: (context) => ApplyLeaveFilter(
        initialStatus: _searchStatusId,
        initialCategory: _searchCategoryId,
        initialDate: _searchAppliedDate,
        initialYear: _searchYear,
        onApplyFilter: (newStatus, newCategory, newDate, newYear) {
          setState(() {
            _searchStatusId = newStatus;
            _searchCategoryId = newCategory;
            _searchAppliedDate = newDate;
            _searchYear = newYear;
            _currentPage = 1;
            _hasMore = true;
            _leaveRecordsList.clear();
          });
          // parent will fetch after popup calls onApply (popup also optionally calls onFetch)
          _loadLeaveRecords();
        },
        onFetch:
            null, // we fetch in screen after popup apply; popup already fetches its own dropdowns
      ),
    );
  }

  void _onStaticSearchFilterChange(String value) {
    if (_searchDebounceTimer?.isActive ?? false) _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadLeaveRecords(
          searchText: value, isSearchLoad: true, isLoadMore: true);
    });
  }

  /// -----------------------------------------------------------------------------
  /// UI Helpers
  /// -----------------------------------------------------------------------------
  /// Builds active filter chips and refreshes the list on clear.
  List<Widget> _buildFilterChips() {
    final filters = [
      _FilterChipData('Status', _searchStatusId,
          () => setState(() => _searchStatusId = null)),
      _FilterChipData('Category', _searchCategoryId,
          () => setState(() => _searchCategoryId = null)),
      _FilterChipData('Applied Date', _searchAppliedDate,
          () => setState(() => _searchAppliedDate = null)),
      _FilterChipData(
          'Year', _searchYear, () => setState(() => _searchYear = null)),
    ];

    return filters
        .where((filter) => filter.value != null)
        .map(
          (filter) => FilterChipWidget(
            label: filter.label,
            value: filter.value,
            onClear: () {
              filter.onClear();
              _loadLeaveRecords(); // refresh
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
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.PRIMARY),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
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
                      // ElevatedButton.icon(
                      //   onPressed: _onFilterPressed,
                      //   label: const Text(
                      //     'Filter',
                      //     style: TextStyle(color: AppColors.PRIMARY),
                      //   ),
                      //   icon: const Icon(
                      //     Icons.filter_list,
                      //     color: AppColors.PRIMARY,
                      //   ),
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
                        suffixIcon: _isLeaveDataLoading
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
                      await _loadLeaveRecords();
                    },
                    child: _leaveRecordsList.isEmpty
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
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _leaveRecordsList.length + 1,
                            itemBuilder: (ctx, i) {
                              if (i == _leaveRecordsList.length) {
                                return Column(
                                  children: [
                                    if (_hasMore)
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: _isLeaveDataLoading
                                              ? null
                                              : () => _loadLeaveRecords(
                                                    isLoadMore: true,
                                                  ),
                                          child: _isLeaveDataLoading
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
                                    if (_leaveRecordsList.length > 0 &&
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

                              final r = _leaveRecordsList[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            r.fromDate,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '- [ ${r.noOfLeaves} ]',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (r.noOfLeaves > 1) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '- ${r.toDate}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(r.reason),
                                      const Divider(),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            r.status.name ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
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
                                              r.category.name,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (_isAdminRole)
                                            Tooltip(
                                              message: r.fullName,
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
                                                      r.fullName.toInitials(),
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
                                          const SizedBox(width: 14),
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Colors.grey[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(r.appliedDate ?? ''),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 4),
        width: 58,
        height: 58,
        child: FloatingActionButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onPressed: () async {
            await showApplyLeaveForm(context);
            await _loadLeaveRecords();
          },
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: AppColors.PRIMARY,
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------------
/// Model
/// -----------------------------------------------------------------------------

class FilterItem {
  final String id;
  final String name;
  FilterItem({required this.id, required this.name});
  factory FilterItem.fromJson(Map<String, dynamic> json) => FilterItem(
        id: json['id'] as String,
        name: json['dropdownValue'] as String,
      );
}

class LeaveRecord {
  final String fromDate;
  final String toDate;
  final String fullName;
  final double noOfLeaves;
  final String reason;
  final String? appliedDate;
  final FilterItem status;
  final FilterItem category;
  final String id;

  LeaveRecord({
    required this.id,
    required this.fromDate,
    required this.toDate,
    required this.fullName,
    required this.noOfLeaves,
    required this.reason,
    required this.appliedDate,
    required this.status,
    required this.category,
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      id: json['id'] as String,
      fromDate: json['fromDate'] as String,
      toDate: json['toDate'] as String,
      fullName:
          "${json['employee']['person']['firstName']} ${json['employee']['person']['lastName']}",
      noOfLeaves: (json['noofLeaves'] as num).toDouble(),
      reason: json['reason'] as String,
      appliedDate: json['createdOnUtc'] as String?,
      status: FilterItem(
        id: json['leaveStatuses']['id'] as String,
        name: json['leaveStatuses']['dropDownValue'] as String,
      ),
      category: FilterItem(
        id: json['leaveCategories']['id'] as String,
        name: json['leaveCategories']['dropDownValue'] as String,
      ),
    );
  }
}

class _FilterChipData {
  final String label;
  final dynamic value;
  final VoidCallback onClear;

  _FilterChipData(this.label, this.value, this.onClear);
}
