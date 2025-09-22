import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:test_project/core/dialogs/delete_confirmation_dialog.dart';

import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/custom_snackbar.dart';
import 'package:test_project/core/widgets/reusable_app_bar.dart';
import 'package:test_project/core/widgets/chip/filter_chip_widget .dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/features/meetings/model/calendar_list_responce_model.dart';
import 'package:test_project/features/meetings/meetings_service.dart';
import 'package:test_project/features/meetings/widgets/meetings_filter.dart';

// Model aligned to API-style usage
class IcsEvent {
  final String id;
  final String summary;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;
  final String? description;

  IcsEvent({
    required this.id,
    required this.summary,
    required this.start,
    required this.end,
    required this.isAllDay,
    this.description,
  });
}

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({Key? key}) : super(key: key);

  @override
  State<MeetingsScreen> createState() => MeetingsScreenState();
}

class MeetingsScreenState extends State<MeetingsScreen> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  // ICS input (only shown when no ICS saved)
  final TextEditingController _icsController = TextEditingController();

  // Filters
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // State
  bool _isInitialLoading = false;
  bool _isFetching = false;

  // Saved ICS url
  String? _savedIcsUrl;
  String? _icsUrlError;

  // Data
  final List<IcsEvent> _allEvents = <IcsEvent>[];
  List<IcsEvent> _filteredEvents = <IcsEvent>[];

  // UI pagination
  int _currentPage = 1;
  final int _pageSize = 15;
  bool _hasMore = true;

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _isInitialLoading = true);
    final saved = await LocalStorage.getIcsKey();
    _savedIcsUrl = saved;
    if (saved != null && saved.trim().isNotEmpty) {
      await _refreshFromStoredKey();
    }
    setState(() => _isInitialLoading = false);
  }

  @override
  void dispose() {
    _icsController.dispose();
    super.dispose();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  // Save ICS and fetch
  Future<void> _saveIcsKey() async {
    final url = _icsController.text.trim();
    if (url.isEmpty) {
      setState(() => _icsUrlError = 'ICS URL cannot be empty');
      return;
    }
    await LocalStorage.setIcsKey(url);
    setState(() => _savedIcsUrl = url);
    await _refreshFromStoredKey();
  }

  // Delete ICS
  Future<void> _deleteIcsKey() async {
    await LocalStorage.clearIcsKey();
    setState(() {
      _savedIcsUrl = null;
      _icsController.clear();
      _allEvents.clear();
      _filteredEvents.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    showCustomSnackBar(
      context,
      message: 'ICS key deleted',
      backgroundColor: AppColors.ERROR,
    );
  }

  // Refresh from saved ICS
  Future<void> _refreshFromStoredKey() async {
    final saved = await LocalStorage.getIcsKey();
    if (saved == null || saved.trim().isEmpty) {
      showCustomSnackBar(context,
          message: 'No ICS key saved', backgroundColor: AppColors.ERROR);
      return;
    }
    await _fetchAndBind(saved.trim());
  }

  Future<void> _fetchAndBind(String icsUrl) async {
    setState(() => _isFetching = true);
    try {
      final payload = {
        'month': _selectedMonth.toString().padLeft(2, '0'),
        'year': _selectedYear.toString(),
        'outlookICSLink': icsUrl,
      };

      final resp = await TimeBuddyService.instance.fetchCalendarData(payload);

      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        final parsed = CalendarListResponse.fromJson(
          resp.data as Map<String, dynamic>,
        );

        final events = parsed.data.map((e) {
          final start = (e.startDateTimeCalendar != null &&
                  e.startDateTimeCalendar!.isNotEmpty)
              ? DateTime.parse(e.startDateTimeCalendar!)
              : DateTime.parse('${e.startDateStr}T00:00:00');
          final end = (e.endDateTimeCalendar != null &&
                  e.endDateTimeCalendar!.isNotEmpty)
              ? DateTime.parse(e.endDateTimeCalendar!)
              : DateTime.parse('${e.endDateStr}T23:59:59');

          return IcsEvent(
            id: e.uid ?? '',
            summary: (e.subject ?? '').trim(),
            start: start,
            end: end,
            isAllDay: false,
            description: e.description,
          );
        }).toList();

        setState(() {
          _allEvents
            ..clear()
            ..addAll(events);
        });
        _applyMonthYearFilter(resetPaging: true);
      } else {
        showCustomSnackBar(
          context,
          message: 'Failed to fetch calendar (${resp.statusCode})',
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
      setState(() => _isFetching = false);
    }
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  void _applyMonthYearFilter({bool resetPaging = false}) {
    _filteredEvents = _allEvents.where((e) {
      return e.start.month == _selectedMonth && e.start.year == _selectedYear;
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    // Pagination disabled
    _currentPage = 1;
    _hasMore = false;
    setState(() {});
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    setState(() {
      _currentPage += 1;
      _hasMore = _filteredEvents.length > _currentPage * _pageSize;
    });
  }

  void _openFilter() {
    showDialog(
      context: context,
      builder: (_) => TimeBuddyFilter(
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
        onApply: (m, y) {
          setState(() {
            _selectedMonth = m;
            _selectedYear = y;
          });
          if (_savedIcsUrl != null && _savedIcsUrl!.isNotEmpty) {
            _fetchAndBind(_savedIcsUrl!);
          } else {
            _applyMonthYearFilter(resetPaging: true);
          }
        },
        onFetch: null,
      ),
    );
  }

  Future<void> _confirmDeleteIcs() async {
    await showDeleteConfirmationDialog(
      context,
      title: "Delete Confirmation",
      description: "Are you sure you want to remove ICS URL?",
      // subDescription: _savedIcsUrl ?? '',
      onDelete: _deleteIcsKey,
    );
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasIcs = (_savedIcsUrl != null && _savedIcsUrl!.trim().isNotEmpty);

    return Scaffold(
        appBar: const ReusableAppBar(title: 'Meetings'),
        body: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : hasIcs
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    FilterChipWidget(
                                      label: 'Month',
                                      value: _selectedMonth
                                          .toString()
                                          .padLeft(2, '0'),
                                    ),
                                    const SizedBox(width: 4),
                                    FilterChipWidget(
                                      label: 'Year',
                                      value: _selectedYear.toString(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openFilter,
                              icon: const Icon(Icons.filter_list,
                                  color: AppColors.PRIMARY),
                              label: const Text('Filter',
                                  style: TextStyle(color: AppColors.PRIMARY)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _confirmDeleteIcs,
                              child: const Icon(Icons.delete_outline,
                                  color: AppColors.PRIMARY),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_circle_down_outlined,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text('Pull down to refresh content',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Expanded(
                          child: RefreshIndicator(
                        color: AppColors.PRIMARY,
                        onRefresh: _refreshFromStoredKey,
                        child: _isFetching
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.PRIMARY))
                            : _pagedListView(),
                      )),
                    ],
                  )
                : Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Meetings',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                            'To get calendar meetings data, you have to provide Microsoft ICS URL'),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _icsController,
                          decoration: InputDecoration(
                            labelText: 'Microsoft ICS URL',
                            hintText: 'Paste Outlook published ICS link',
                            errorText: _icsUrlError,
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) =>
                              setState(() => _icsUrlError = null),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.PRIMARY,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            onPressed: _isFetching ? null : _saveIcsKey,
                            child: _isFetching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.help_outline,
                            size: 20,
                          ),
                          title: const Text(
                            'How to get your Microsoft ICS URL',
                            style: TextStyle(fontSize: 14),
                          ),
                          childrenPadding: const EdgeInsets.only(
                              left: 8, right: 4, bottom: 8),
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Outlook on the web (Outlook.com / Microsoft 365):',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  '1) Open Calendar → Settings (gear) → View all Outlook settings.'),
                            ),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('2) Calendar → Shared calendars.'),
                            ),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  '3) Under “Publish a calendar”, choose your calendar + permission (e.g., “Can view all details”), then Publish.'),
                            ),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  '4) Copy the ICS link (not HTML) and paste it below.'),
                            ),
                            const SizedBox(height: 12),

                            // New Outlook for Windows
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'New Outlook for Windows:',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  '1) Go to Calendar → View tab → Calendar settings → Calendar → Shared calendars.'),
                            ),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  '2) Under “Publish a calendar”, pick your calendar + permission, click Publish, then copy the ICS link.'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ));
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI Helpers
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  Widget _pagedListView() {
    final items = _filteredEvents;

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(child: Text('No Data Available')),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + 1,
      itemBuilder: (ctx, i) {
        if (i == items.length) {
          return Column(
            children: [
              if (_hasMore)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: ElevatedButton(
                      onPressed: _isFetching ? null : _loadMore,
                      child: _isFetching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.PRIMARY),
                              ),
                            )
                          : const Text('Load More',
                              style: TextStyle(color: AppColors.PRIMARY)),
                    ),
                  ),
                ),
              if (items.isNotEmpty && !_hasMore)
                Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('All items loaded',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
            ],
          );
        }
        return _buildEventCard(items[i]);
      },
    );
  }

  // Card
  Widget _buildEventCard(IcsEvent e) {
    // Formatting
    final dateFmt = DateFormat('MM/dd/yyyy'); // e.g., 09/20/2025 [intl]
    final timeFmt = DateFormat('hh:mm a'); // e.g., 05:30 PM   [intl]
    final sameDay = e.start.year == e.end.year &&
        e.start.month == e.end.month &&
        e.start.day == e.end.day;

    // Header pieces
    final startDateTime =
        '${dateFmt.format(e.start)} ${timeFmt.format(e.start)}';
    final endDateTime = '${dateFmt.format(e.end)} ${timeFmt.format(e.end)}';

    // Duration and rounded hours
    final Duration dur = e.end.isAfter(e.start)
        ? e.end.difference(e.start)
        : e.start.difference(e.end);
    final int totalSeconds = dur.inSeconds;
    final double roundedHours = ((totalSeconds / 3600.0) * 100).round() / 100;

    // Final header line including total hours
    final String headerLine = sameDay
        ? '$startDateTime - ${timeFmt.format(e.end)}'
        : '$startDateTime - $endDateTime';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  headerLine,
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
                        borderRadius: BorderRadius.circular(4),
                        onTap: () async {
                          context.pushNamed(
                            'addTimesheetLines',
                            pathParameters: {
                              'id': e.id,
                              'subject': Uri.encodeComponent(e.summary),
                              'strDate': Uri.encodeComponent(startDateTime),
                              'endDate': Uri.encodeComponent(endDateTime),
                              'duration': Uri.encodeComponent(
                                  roundedHours.toStringAsFixed(2)),
                            },
                          );
                        },
                        child: Container(
                          height: 25,
                          width: 25,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              4,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.add,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject
                Text(
                  e.summary.isEmpty ? '(No title)' : e.summary,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                // Description
                if ((e.description ?? '').trim().isNotEmpty)
                  Text(e.description!.trim(),
                      style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
