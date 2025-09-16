import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:test_project/core/constants/formats.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/flavor/flavor.dart';
import 'package:test_project/core/widgets/date_picker/arrow_date_picker.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';
import 'package:test_project/features/home/home_service.dart';
import 'package:test_project/features/home/widgets/home_timeIn_timeout_card.dart';
import 'package:test_project/features/home/widgets/movement_register_bottom_card.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Home Screen', home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  // Feature flags
  bool _isTimeCardVisible = true;
  bool _isAdmin = true;

  // Pagination
  int _currentPage = 1;
  bool _hasMoreMovementRegisters = false;

  // Loading state
  bool _isMovementRegisterLoading = false;
  bool _isMovementRegisterInitialLoading = false;

  // Date selection
  DateTime _movementRegisterSelectedDate = DateTime.now();

  // Controllers/keys
  final GlobalKey<HomeTimeInTimeOutCardState> _timeCardKey = GlobalKey();

  // Data
  List<MovementRegisterMessageModel> _movementRegisterList =
      <MovementRegisterMessageModel>[];

  // Config
  final String _apiBaseUrl = dotenv.env['API_BASE_URL']!;

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchMovementRegisterList();
  }

  // --------------------------------------------------------------------------------------------------------------------------------------------------
  // API Calls
  // --------------------------------------------------------------------------------------------------------------------------------------------------

  // Fetches paginated movement register items for the selected date and updates state.
  Future<void> _fetchMovementRegisterList({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _currentPage = 1; // reset to 1 on fresh fetch
        _isMovementRegisterInitialLoading = true;
      });
    }
    setState(() {
      _isMovementRegisterLoading = true;
    });

    final payload = {
      "filter": "string",
      "page": _currentPage,
      "pageSize": 7,
      "sortBy": "createdOnUtc",
      "descending": true,
      "searchText": "",
      "createdBy": "View All",
      "employeeId": "",
      "fromDate": _movementRegisterSelectedDate.format(),
      "toDate": _movementRegisterSelectedDate.format(),
    };

    try {
      final response = await HomeService.instance.getMovementRegisterList(
        payload,
      );

      if (response.statusCode == 200) {
        final dynamic jsonBody = response.data;
        final newRegisters = MovementRegisterMessageModel.fromJsonList(
          jsonBody,
        );

        setState(() {
          if (newRegisters.length != 7) {
            _hasMoreMovementRegisters = false;
          } else {
            _hasMoreMovementRegisters = true;
          }
          if (isLoadMore) {
            _movementRegisterList.addAll(newRegisters);
          } else {
            _movementRegisterList = newRegisters;
          }
          _isMovementRegisterLoading = false;
          _isMovementRegisterInitialLoading = false;
        });
      } else {
        setState(() => _isMovementRegisterLoading = false);
        throw Exception('Failed to fetch movement register list');
      }
    } catch (e, st) {
      setState(() {
        _isMovementRegisterLoading = false;
        _isMovementRegisterInitialLoading = false;
      });

      debugPrint('fetch_MovementRegisterList error: $e\n$st');
      rethrow;
    }
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  // Handles pull-to-refresh to reload home screen data, including the time card.
  Future<void> _refreshAllHomeData() async {
    await _fetchMovementRegisterList();

    if (_timeCardKey.currentState != null) {
      await _timeCardKey.currentState!.onRefreshCardData();
    }
  }

  // Handles pagination “Load More” button press for the movement register list.
  void _onLoadMorePressed() {
    setState(() {
      _currentPage += 1;
    });
    _fetchMovementRegisterList(isLoadMore: true);
  }

  // Resets filters when the time card is refreshed and fetches list data.
  void _onTimeCardRefreshed() {
    setState(() {
      _movementRegisterSelectedDate = DateTime.now();
      _currentPage = 1;
      _hasMoreMovementRegisters = false;
    });
    _fetchMovementRegisterList();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusableAppBar(title: "Home"),
      body: !isDev 
          ? const Center(child: Text("Home screen"))
          : SafeArea(
              child: RefreshIndicator(
                color: AppColors.PRIMARY,
                onRefresh: _refreshAllHomeData,
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    if (_isTimeCardVisible)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: HomeTimeInTimeOutCard(
                          onRefresh: _onTimeCardRefreshed, // Pass the callback
                        ),
                      ),
                    if (_isAdmin) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Movement Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ArrowDatePicker(
                            selectedDate: _movementRegisterSelectedDate,
                            onDateChanged: (newDate) {
                              setState(() =>
                                  _movementRegisterSelectedDate = newDate);
                              _fetchMovementRegisterList();
                            },
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            enabled: true,
                          ),
                        ],
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
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
                      ),
                      _isMovementRegisterInitialLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _movementRegisterList.isEmpty
                              ? const Center(child: Text("No data available"))
                              : Column(
                                  children: [
                                    ..._movementRegisterList.map((timeDetails) {
                                      final parsedDate = DateFormat(
                                        ConstFormats.DATETIME_MMDDYYYY_12HS,
                                      ).parse(timeDetails.date);
                                      final hours = DateFormat(
                                        ConstFormats.TIME_12H,
                                      ).format(parsedDate);
                                      final bgColor =
                                          Colors.green.withOpacity(0.2);

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 3,
                                        child: Stack(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        bottom: 20,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            timeDetails.message,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            softWrap: true,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 6,
                                              right: 10,
                                              child: Text(
                                                "${timeDetails.employeeName}   $hours",
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const SizedBox(height: 8),
                                    if (_movementRegisterList.length > 1 &&
                                        _hasMoreMovementRegisters)
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: _isMovementRegisterLoading
                                              ? null
                                              : () => _onLoadMorePressed(),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: _isMovementRegisterLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
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
                                                    color: AppColors.PRIMARY,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    // For the "no more data" indicator
                                    if (_movementRegisterList.length > 0 &&
                                        !_hasMoreMovementRegisters)
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

                                    // For the pull to refresh indicator
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
                                ),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: isDev
          ? FloatingActionButton(
              backgroundColor: AppColors.PRIMARY,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const MovementRegisterBottomSheet(),
                );
                if (result == true) {
                  setState(() {
                    _movementRegisterSelectedDate = DateTime.now();
                    _currentPage = 1;
                    _hasMoreMovementRegisters = false;
                  });
                  _fetchMovementRegisterList();
                }
              },
            )
          : null,
    );
  }
}

/// --------------------------------------------------------------------------------------------------------------------------------------------------
/// Model
/// --------------------------------------------------------------------------------------------------------------------------------------------------

class MovementRegisterMessageModel {
  final String message;
  final String employeeName;
  final String date;

  MovementRegisterMessageModel({
    required this.message,
    required this.employeeName,
    required this.date,
  });

  static List<MovementRegisterMessageModel> fromJsonList(dynamic jsonRoot) {
    final List<dynamic> registers = jsonRoot is List
        ? jsonRoot
        : (jsonRoot['moveRegisterList'] as List<dynamic>? ?? []);

    return registers.expand<MovementRegisterMessageModel>((reg) {
      final String date = reg['dateStr'] as String? ?? '';
      final List<dynamic> details =
          reg['movementRegisterDetails'] as List<dynamic>? ?? [];
      return details.map<MovementRegisterMessageModel>((det) {
        final d = det as Map<String, dynamic>;
        return MovementRegisterMessageModel(
          message: d['message'] as String? ?? '',
          employeeName: d['employees']?['person']?['fullName'] as String? ?? '',
          date: date,
        );
      });
    }).toList();
  }
}
