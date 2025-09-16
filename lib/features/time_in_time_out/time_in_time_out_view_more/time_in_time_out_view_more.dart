import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/core/constants/formats.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/info_row/info_row_widget.dart';
import 'package:test_project/features/time_in_time_out/time_in_time_out_service.dart';
import 'package:test_project/states/model/timeInTimeOutOnIdResponseModel.dart';

/// Screen that shows detailed time-in/time-out information and break totals.
class TimeInTimeOutViewMoreScreen extends StatefulWidget {
  final String id;

  const TimeInTimeOutViewMoreScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  State<TimeInTimeOutViewMoreScreen> createState() =>
      _TimeInTimeOutViewMoreScreenState();
}

class _TimeInTimeOutViewMoreScreenState
    extends State<TimeInTimeOutViewMoreScreen> {
  /// -----------------------------------------------------------------------------
  /// Variable Declarations
  /// -----------------------------------------------------------------------------

  // Loading flags and data
  TimeInTimeOutOnIdResponseModel? _details;
  bool _isLoading = true;

  /// -----------------------------------------------------------------------------
  /// Lifecycle
  /// -----------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadTimeInTimeOutDetails(widget.id);
  }

  /// -----------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// -----------------------------------------------------------------------------

  /// Loads the time-in/time-out details by id and updates UI state.
  Future<void> _loadTimeInTimeOutDetails(String timeInKeyGuid) async {
    try {
      final response = await TimeInTimeOutService.instance
          .fetchTimeInTimeOutDetails(timeInKeyGuid);

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _details = TimeInTimeOutOnIdResponseModel.fromJson(response.data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('_loadTimeInTimeOutDetails error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// -----------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// -----------------------------------------------------------------------------

  /// Navigates back to the previous screen.
  void _onBackPressed() => context.pop();

  /// Calculates the break duration in minutes for a break-out/in pair.
  int _calculateBreakMinutes(String? breakOutStr, String? breakInStr) {
    if (breakOutStr == null ||
        breakInStr == null ||
        breakOutStr.isEmpty ||
        breakInStr.isEmpty) {
      return 0;
    }

    try {
      final outTime = _parseTimeString(breakOutStr);
      final inTime = _parseTimeString(breakInStr);
      final difference = inTime.difference(outTime);
      return difference.inMinutes.abs();
    } catch (e) {
      debugPrint('Error calculating break minutes: $e');
      return 0;
    }
  }

  /// Parses a 12-hour time string using the shared ConstFormats formatter.
  DateTime _parseTimeString(String timeStr) {
    try {
      final formattedTimeStr = timeStr.trim().toUpperCase();
      return ConstFormats.TIME_12H_FORMAT.parse(formattedTimeStr);
    } catch (e) {
      debugPrint('Error parsing time string: $timeStr, error: $e');
      // Return "now" on parse error to avoid crashing; value is not persisted.
      return DateTime.now();
    }
  }

  /// -----------------------------------------------------------------------------
  /// UI
  /// -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _onBackPressed,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Time In Time Out Info',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.PRIMARY,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(label: 'Date', value: _details?.timeInDate ?? '-'),
                  InfoRow(
                    label: 'Employee Name',
                    value: _details?.employee?.person?.fullName ?? '-',
                  ),
                  const InfoRow(label: 'Employee Shift', value: '-'),
                  InfoRow(label: 'Time In', value: _details?.timeInStr ?? '-'),
                  InfoRow(
                      label: 'Time Out', value: _details?.timeOutStr ?? '-'),
                  InfoRow(
                    label: 'Created By',
                    value: _details?.createdBy?.person?.fullName ?? '-',
                  ),
                  InfoRow(
                    label: 'Created Date',
                    value: _details?.createdOnUtc ?? '-',
                  ),
                  InfoRow(
                    label: 'Updated By',
                    value: _details?.updatedBy?.person?.fullName ?? '-',
                  ),
                  InfoRow(
                    label: 'Updated Date',
                    value: _details?.updatedOnUtc ?? '-',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Breaks Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.PRIMARY,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBreaksTable(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onBackPressed,
        heroTag: 'back',
        backgroundColor: AppColors.PRIMARY,
        child: const Icon(Icons.arrow_back, color: Colors.white),
        tooltip: 'Back',
      ),
    );
  }

  /// -----------------------------------------------------------------------------
  /// UI Helpers
  /// -----------------------------------------------------------------------------

  /// Builds the break summary table along with the grand total (in minutes).
  Widget _buildBreaksTable() {
    final breaks = _details?.timeInTimeOutBreakDetailList;
    if (breaks == null || breaks.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: const Text(
          'No breaks recorded',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Compute per-break minutes and a grand total.
    final breakMinutesList = breaks
        .map((b) => _calculateBreakMinutes(b.breakOutStr, b.breakInStr))
        .toList();
    final grandTotalMinutes =
        breakMinutesList.fold<int>(0, (sum, m) => sum + m);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.PRIMARY),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Break Out',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Break In',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Break Reason',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          // Table rows
          ...breaks.asMap().entries.map((entry) {
            final index = entry.key;
            final b = entry.value;
            final minutes = breakMinutesList[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(b.breakOutStr ?? '')),
                  Expanded(flex: 2, child: Text(b.breakInStr ?? '')),
                  Expanded(flex: 3, child: Text(b.breakReason ?? '')),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(minutes.toString()),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Grand total row
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                const Expanded(flex: 2, child: SizedBox()),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Grand Total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.PRIMARY,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      grandTotalMinutes.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.PRIMARY,
                      ),
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
