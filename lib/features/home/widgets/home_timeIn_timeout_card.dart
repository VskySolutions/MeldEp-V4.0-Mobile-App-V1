import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:test_project/core/constants/formats.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/utils/validators.dart';
import 'package:test_project/core/widgets/snackbar/custom_snackbar.dart';
import 'package:test_project/features/home/home_service.dart';
import 'package:test_project/features/home/widgets/home_timeIn_timeout_button.dart';
import 'package:test_project/states/model/timeInTimeOutOnIdResponseModel.dart';

class HomeTimeInTimeOutCard extends StatefulWidget {
  final VoidCallback? onRefresh;

  const HomeTimeInTimeOutCard({Key? key, this.onRefresh}) : super(key: key);

  @override
  State<HomeTimeInTimeOutCard> createState() => HomeTimeInTimeOutCardState();
}

/// --------------------------------------------------------------------------------------------------------------------------------------------------
/// Lists & Collections
/// --------------------------------------------------------------------------------------------------------------------------------------------------
final List<TimeInTimeOutDropdownModule> breakReasonOptions = List<
    TimeInTimeOutDropdownModule>.unmodifiable(<TimeInTimeOutDropdownModule>[
  TimeInTimeOutDropdownModule(id: 'Coffee break', name: 'Coffee break'),
  TimeInTimeOutDropdownModule(id: 'Walk break', name: 'Walk break'),
  TimeInTimeOutDropdownModule(id: 'Snack break', name: 'Snack break'),
  TimeInTimeOutDropdownModule(id: 'Lunch break', name: 'Lunch break'),
  TimeInTimeOutDropdownModule(id: 'Commute break', name: 'Commute break'),
]);

class HomeTimeInTimeOutCardState extends State<HomeTimeInTimeOutCard> {
  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Variable Declarations
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  // Time-in/out state
  bool _isTimedIn = false;
  TimeInTimeOutOnIdResponseModel? _timeInTimeOutDetails;

  // Break state
  String? _breakOutId;
  bool _isBreakFormVisible = false;
  bool _isLunchBreakSelected = false;
  int _lastBreakMinutes = 0;

  // Loading flags
  bool _isLoading = false;
  bool _isTimeInLoading = false;
  bool _isTimeOutLoading = false;
  bool _isBreakStartLoading = false;
  bool _isBreakEndLoading = false;
  bool _isTimeInOutDetailsLoading = false;

  // Break form fields
  String _breakDescription = '';
  String _breakMinutes = '';
  String? _breakDescriptionError;
  String? _breakMinutesError;

  // Controllers and timers
  final TextEditingController _breakDescriptionController =
      TextEditingController();
  final TextEditingController _breakMinutesController = TextEditingController();
  Timer? _timer;

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Lifecycle
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadIsTimedIn();
    _loadBreakStart();
    _loadLastBreakMinutes();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breakDescriptionController.dispose();
    _breakMinutesController.dispose();
    super.dispose();
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Check if user is timed in and update state (async work done before setState)
  Future<void> _loadIsTimedIn() async {
    try {
      final timeInGuid = await LocalStorage.getTimeIn();
      final bool isTimed = timeInGuid != null && timeInGuid.isNotEmpty;

      if (!mounted) return;
      setState(() {
        _isTimedIn = isTimed;
      });

      if (_isTimedIn) {
        // fetch details but do not block setState above
        await _fetchTimeInTimeOutDetails();
      }
    } catch (e, st) {
      debugPrint('_loadIsTimedIn error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isTimedIn = false;
      });
    }
  }

  /// Load break-out id from local storage and update state
  Future<void> _loadBreakStart() async {
    try {
      final breakOutGuid = await LocalStorage.getBreakOut();
      if (!mounted) return;
      setState(() {
        _breakOutId =
            (breakOutGuid != null && breakOutGuid.toString().isNotEmpty)
                ? breakOutGuid.toString()
                : null;
      });
    } catch (e, st) {
      debugPrint('_loadBreakStart error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _breakOutId = null;
      });
    }
  }

  /// Read last break minutes and set state
  Future<void> _loadLastBreakMinutes() async {
    try {
      final minFromLocalStorage = await LocalStorage.getLastBreakMinutes();
      if (!mounted) return;

      if (minFromLocalStorage != null) {
        final parsedDouble = double.tryParse(minFromLocalStorage);
        if (parsedDouble != null) {
          setState(() {
            _lastBreakMinutes = parsedDouble.round();
          });
        } else {
          debugPrint('Invalid double format in SharedPreferences');
        }
      }
    } catch (e, st) {
      debugPrint('_loadLastBreakMinutes error: $e\n$st');
    }
  }

  // Returns the persisted time-in guid from local storage.
  Future<String?> _getTimeInGuid() async {
    return await LocalStorage.getTimeIn();
  }

  // Fetches time-in/out details for the current guid and updates state.
  Future<void> _fetchTimeInTimeOutDetails() async {
    final timeInKeyGuid = await _getTimeInGuid();
    if (timeInKeyGuid == null || timeInKeyGuid.isEmpty) return;
    setState(() => _isTimeInOutDetailsLoading = true);

    try {
      final response = await HomeService.instance.getTimeInTimeOutDetails(
        timeInKeyGuid,
      );

      if (response.statusCode == 200) {
        final jsonMap = response.data;
        if (!mounted) return;
        setState(() {
          _timeInTimeOutDetails = TimeInTimeOutOnIdResponseModel.fromJson(
            jsonMap as Map<String, dynamic>,
          );
        });
        setState(() => _isTimeInOutDetailsLoading = false);
      } else {
        setState(() => _isTimeInOutDetailsLoading = true);
        debugPrint('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e, st) {
      setState(() => _isTimeInOutDetailsLoading = true);
      debugPrint('Error fetching details: $e\n$st');
    }
  }

  // Handles the Time In action: creates a new entry, persists the guid, and refreshes details.
  Future<void> _handleTimeIn() async {
    // mark loading BEFORE async work so UI shows spinner immediately
    if (!mounted) return;
    setState(() {
      _isTimeInLoading = true;
    });

    final uuid = Uuid();
    final guid = uuid.v4();

    final now = DateTime.now();
    final payload = {
      "Id": guid,
      "TimeInDate": now.format(),
      "TimeInStr": now.format24H,
    };

    try {
      final response = await HomeService.instance.postTimeIn(payload);

      if (response.statusCode == 200) {
        await LocalStorage.setTimeIn(guid);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isTimeInLoading = false;
          _isTimedIn = true;
        });
        // fetch details (can be awaited)
        await _fetchTimeInTimeOutDetails();
        showCustomSnackBar(
          context,
          message: 'Timed in successfully!',
          durationSeconds: 2,
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isTimeInLoading = false;
        });
        showCustomSnackBar(
          context,
          message: 'Failed to get time in',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e, st) {
      debugPrint('Error on time-in: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isTimeInLoading = false;
      });
      showCustomSnackBar(
        context,
        message: 'Something went wrong',
        backgroundColor: AppColors.ERROR,
      );
    }
  }

  // Handles the Time Out action: updates the record, clears local keys, and resets state.
  Future<void> _handleTimeOut() async {
    final timeInKeyGuid = await _getTimeInGuid() ?? "";

    if (!mounted) return;
    setState(() {
      _isTimeOutLoading = true;
    });

    final now = DateTime.now();
    final payload = {"TimeOutDate": now.format(), "TimeOutStr": now.format24H};

    try {
      final response = await HomeService.instance.putTimeOut(
        timeInKeyGuid,
        payload,
      );

      if (response.statusCode == 200) {
        await LocalStorage.clearTimeIn();
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isTimeOutLoading = false;
          _isTimedIn = false;
          _isBreakFormVisible = false;
          _timeInTimeOutDetails = null;
        });
        showCustomSnackBar(
          context,
          message: 'Timed out successfully!',
          durationSeconds: 2,
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isTimeOutLoading = false;
        });
        showCustomSnackBar(
          context,
          message: 'Failed to time out',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e, st) {
      debugPrint('Error on time-out: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isTimeOutLoading = false;
      });
      showCustomSnackBar(
        context,
        message: 'Something went wrong',
        backgroundColor: AppColors.ERROR,
      );
    }
  }

  // Validates and submits the break start request.
  void _onSubmitBreak() {
    if ((_breakDescription.isNotEmpty) && (_breakMinutes.isNotEmpty)) {
      _handleBreakStart();
    } else {
      showCustomSnackBar(
        context,
        message: 'Please select both minutes and description.',
        durationSeconds: 4,
        backgroundColor: AppColors.ERROR,
      );
      if (!mounted) return;
      setState(() {
        _breakDescriptionError = Validators.validateText(
          _breakDescription,
          fieldName: "Break description",
        );
        _breakMinutesError = Validators.validateInteger(
          _breakMinutes,
          fieldName: "Minutes",
        );
      });
    }
  }

  // Starts a break for the current time-in record and persists the break guid.
  Future<void> _handleBreakStart() async {
    final parsedMins = double.tryParse(_breakMinutes);
    final timeInKeyGuid = await _getTimeInGuid() ?? "";

    if (!mounted) return;
    setState(() {
      _isBreakStartLoading = true;
    });

    final uuid = Uuid();
    final guid = uuid.v4();

    if (parsedMins == null) {
      if (!mounted) return;
      setState(() => _isBreakStartLoading = false);
      return showCustomSnackBar(
        context,
        message: 'Invalid break length',
        backgroundColor: AppColors.ERROR,
      );
    }

    final inTime = DateTime.now();

    final breakInTimeStr = _breakDescription == "Lunch break"
        ? inTime.add(const Duration(minutes: 60))
        : null;

    final payload = {
      "TimeInTimeOutBreakDetailModel": [
        {
          "Id": guid,
          "BreakInStr":
              breakInTimeStr != null ? breakInTimeStr.format24H : null,
          "BreakOutStr": inTime.format24H,
          "BreakReason": _breakDescription,
          "Flag": "New",
        },
      ],
    };

    try {
      final response = await HomeService.instance.putBreak(
        timeInKeyGuid,
        payload,
      );

      if (response.statusCode == 200) {
        await LocalStorage.setBreakOut(guid.toString());
        await LocalStorage.setLastBreakMinutes(parsedMins.toString());
        if (!mounted) return;
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
        setState(() {
          _lastBreakMinutes = parsedMins.toInt();
          _isLoading = false;
          _isBreakStartLoading = false;
          _breakOutId = guid.toString();
          _isBreakFormVisible = false;
        });
        await _fetchTimeInTimeOutDetails();
        showCustomSnackBar(
          context,
          message:
              'Break: $_breakDescription for ${_breakMinutesController.text} minutes recorded.',
          durationSeconds: 4,
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isBreakStartLoading = false;
        });
        showCustomSnackBar(
          context,
          message: 'Failed to start break',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e, st) {
      debugPrint('Error on break start: $e\n$st');
      if (!mounted) return;
      setState(() => _isBreakStartLoading = false);
      showCustomSnackBar(
        context,
        message: 'Something went wrong',
        backgroundColor: AppColors.ERROR,
      );
    }
  }

  // Ends an existing break by updating the record using the stored break guid.
  Future<void> _handleBreakEnd({
    required String breakOutStr,
    required String breakReason,
  }) async {
    final inTime = DateTime.now();
    final guid = await LocalStorage.getBreakOut();
    final timeInKeyGuid = await _getTimeInGuid() ?? "";

    if (!mounted) return;
    setState(() {
      _isBreakEndLoading = true;
    });

    final payload = {
      "TimeInTimeOutBreakDetailModel": [
        {
          "Id": guid,
          "BreakInStr": inTime.format24H,
          "BreakOutStr": ConstFormats.TIME_24H_FORMAT.format(
            ConstFormats.TIME_12H_FORMAT.parse(breakOutStr),
          ),
          "BreakReason": breakReason,
          "Flag": "Edit",
        },
      ],
    };

    try {
      final response = await HomeService.instance.putBreak(
        timeInKeyGuid,
        payload,
      );

      if (response.statusCode == 200) {
        await LocalStorage.clearBreakOut();
        await LocalStorage.clearLastBreakMinutes();
        if (!mounted) return;
        setState(() {
          _isBreakEndLoading = false;
          _breakOutId = null;
        });
        await _fetchTimeInTimeOutDetails();
        showCustomSnackBar(
          context,
          message: 'Break ended successfully ',
          durationSeconds: 4,
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isBreakEndLoading = false;
        });
        showCustomSnackBar(
          context,
          message: 'Failed to end break',
          backgroundColor: AppColors.ERROR,
        );
      }
    } catch (e, st) {
      debugPrint('Error on break end: $e\n$st');
      if (!mounted) return;
      setState(() => _isBreakEndLoading = false);
      showCustomSnackBar(
        context,
        message: 'Something went wrong',
        backgroundColor: AppColors.ERROR,
      );
    }
  }

  // Ends lunch break locally when overdue and refreshes details.
  Future<void> _endLunchBreak() async {
    try {
      await LocalStorage.clearBreakOut();
      await LocalStorage.clearLastBreakMinutes();
      if (!mounted) return;
      setState(() {
        _lastBreakMinutes = 0;
        _breakOutId = null;
      });
      await _fetchTimeInTimeOutDetails();
    } catch (e, st) {
      debugPrint('_endLunchBreak error: $e\n$st');
    }
  }

  // --------------------------------------------------------------------------------------------------------------------------------------------------
  // Actions & Event Handlers
  // --------------------------------------------------------------------------------------------------------------------------------------------------

  Future<void> onRefreshCardData() async {
    _loadIsTimedIn();
    _loadBreakStart();
    _loadLastBreakMinutes();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
    // if (widget.onRefresh != null) {
    //   widget.onRefresh!();
    // }
  }

  // Toggles the break form and resets its fields and validation errors.
  void _toggleBreakForm() {
    if (!mounted) return;
    setState(() {
      _isBreakFormVisible = !_isBreakFormVisible;
      _breakDescription = '';
      _breakMinutes = '';
      _breakDescriptionError = null;
      _breakMinutesError = null;
      _breakDescriptionController.clear();
      _breakMinutesController.clear();
      _isLunchBreakSelected = false;
    });
  }

  // Updates break description selection and auto-fills minutes for lunch when applicable.
  void _onBreakDescriptionSelected(TimeInTimeOutDropdownModule suggestion) {
    _breakDescription = suggestion.id.toString();
    _breakDescriptionController.text = suggestion.name.toString();

    if (!mounted) return;
    setState(() {
      if (suggestion.name.toString() == "Lunch break") {
        _breakMinutes = "60";
        _breakMinutesController.text = _breakMinutes;
        _isLunchBreakSelected = true;
        _breakMinutesError = null;
      } else {
        _isLunchBreakSelected = false;
      }
      _breakDescriptionError = null;
    });
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// Utilities & Formatters
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  /// Formats a seconds value into 'mm:ss' for timers; returns '00:00' if the input is negative.
  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) return '00:00';
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Converts fractional hours into a human-friendly '{h}h {m}m' string for display.
  String _formatDurationFromHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  /// Computes worked time since time-in minus breaks and returns a '{h}h {m}m' string (minimum '0h 0m').
  String _getWorkedHoursText() {
    final details = _timeInTimeOutDetails;
    if (details == null ||
        details.timeInDate == null ||
        details.timeIn == null) {
      return '';
    }

    final dateParts = details.timeInDate!.split('/');
    final month = int.parse(dateParts[0]);
    final day = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);
    final totalMinutes = ((details.timeIn ?? 0) * 60).toInt();
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;

    final timeInDateTime = DateTime(year, month, day, hour, minute);
    final now = DateTime.now();
    final diffMinutes = now.difference(timeInDateTime).inMinutes;
    final breakMins = ((details.totalBreak ?? 0) * 60).toInt();
    final workedMins = diffMinutes - breakMins;
    final h = (workedMins / 60).floor();
    final m = workedMins % 60;

    return h <= 0 && m <= 0 ? '0h 0m' : '${h}h ${m}m';
  }

  /// --------------------------------------------------------------------------------------------------------------------------------------------------
  /// UI
  /// --------------------------------------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ───────────── Time In Button ─────────────
              Flexible(
                flex: 1,
                child: HomeTimeInTimeOutButton(
                  label: 'Time In',
                  icon: Icons.login,
                  onTap: _isTimedIn || _isTimeInLoading ? null : _handleTimeIn,
                  isLoading: _isTimeInLoading,
                  isDisabled: _isTimedIn,
                  displayText: _timeInTimeOutDetails?.timeInStr,
                ),
              ),

              // ───────────── Add Break Button ─────────────
              Flexible(
                flex: 1,
                child: HomeTimeInTimeOutButton(
                  label: 'Add Break',
                  icon: Icons.local_cafe,
                  onTap: _isTimedIn && _breakOutId == null && !_isTimeOutLoading
                      ? _toggleBreakForm
                      : null,
                  isDisabled: !(_isTimedIn && _breakOutId == null),
                  displayText: _timeInTimeOutDetails?.totalBreak != null &&
                          _timeInTimeOutDetails!.totalBreak != 0.0
                      ? _formatDurationFromHours(
                          _timeInTimeOutDetails!.totalBreak!,
                        )
                      : null,
                  showBadge: true,
                  badgeCount: _timeInTimeOutDetails
                      ?.timeInTimeOutBreakDetailList?.length,
                ),
              ),

              // ───────────── Time Out Button ─────────────
              Flexible(
                flex: 1,
                child: HomeTimeInTimeOutButton(
                  label: 'Time Out',
                  icon: Icons.logout,
                  onTap:
                      (_isTimedIn && _breakOutId == null) && !_isTimeOutLoading
                          ? _handleTimeOut
                          : null,
                  isLoading: _isTimeOutLoading,
                  isDisabled: !(_isTimedIn && _breakOutId == null),
                  displayText: _getWorkedHoursText(),
                ),
              ),
            ],
          ),

          // Time In
          const SizedBox(height: 6),
          // Break form
          if (_isBreakFormVisible) ...[
            const Divider(),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _breakMinutesController,
                    readOnly: _isLunchBreakSelected,
                    // focusNode: ,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minutes',
                      errorText: _breakMinutesError,
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        onPressed: () {
                          !_isLunchBreakSelected
                              ? _showMinutesPicker(context)
                              : null;
                        },
                        icon: Icon(Icons.timelapse),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _breakMinutesError = Validators.validateInteger(
                          _breakMinutesController.text,
                          fieldName: "Minutes",
                        );
                      });
                    },
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: TypeAheadField(
                    suggestionsCallback: (pattern) {
                      return breakReasonOptions.where((item) {
                        return item.name!.toLowerCase().contains(
                              pattern.toLowerCase(),
                            );
                      }).toList();
                    },
                    itemBuilder:
                        (context, TimeInTimeOutDropdownModule suggestion) {
                      return ListTile(
                        title: Text(suggestion.name.toString()),
                      );
                    },
                    onSelected: (TimeInTimeOutDropdownModule suggestion) {
                      _onBreakDescriptionSelected(suggestion);
                    },
                    loadingBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.PRIMARY,
                        ),
                      ),
                    ),
                    emptyBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No description found please create your custom',
                      ),
                    ),
                    builder: (context, fieldController, focusNode) {
                      final showClear = fieldController.text.isNotEmpty;
                      return TextFormField(
                        controller: fieldController,
                        // maxLines: 2,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Break Description',
                          errorText: _breakDescriptionError,
                          border: const OutlineInputBorder(),
                          isDense: false,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showClear)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    fieldController.clear();
                                    setState(() {
                                      _breakDescription = '';
                                    });
                                  },
                                ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  focusNode.hasFocus
                                      ? focusNode.unfocus()
                                      : focusNode.requestFocus();
                                },
                                icon: Icon(
                                  focusNode.hasFocus
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _breakDescription = value;
                            _breakDescriptionError = Validators.validateText(
                              _breakDescriptionController.text,
                              fieldName: "Break description",
                            );
                          });
                        },
                      );
                    },
                    controller: _breakDescriptionController,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: ElevatedButton(
                    onPressed: _isBreakStartLoading ? null : _onSubmitBreak,
                    child: _isBreakStartLoading
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(),
                          )
                        : const Text("Start Break"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _toggleBreakForm,
                    child: const Text(
                      "Cancel",
                      // style: TextStyle(color: AppColors.ERROR),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!_isBreakFormVisible && _timeInTimeOutDetails != null)
            if (_timeInTimeOutDetails!.timeInTimeOutBreakDetailList!.length > 0)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      (_timeInTimeOutDetails?.timeInTimeOutBreakDetailList ??
                              [])
                          // .reversed
                          .map((breakData) {
                    // 1. Safely parse createdOnUtc, fallback to now on failure
                    DateTime createdDate;
                    try {
                      createdDate = DateTime.parse(breakData.createdOnUtc!);
                      if (createdDate.year < 1900) throw FormatException();
                    } catch (_) {
                      createdDate = DateTime.now();
                    }

                    // 2. Use breakOut as the break START, breakIn as the break END
                    final startValue = breakData.breakOut ?? 0.0;
                    final endValue = breakData.breakIn ?? 0.0;

                    // 3. Build `start` and `end` DateTimes off the same day
                    final startHour = startValue.floor();
                    final startMin = ((startValue - startHour) * 60).round();
                    final start = DateTime(
                      createdDate.year,
                      createdDate.month,
                      createdDate.day,
                      startHour,
                      startMin,
                    );

                    final endHour = endValue.floor();
                    final endMin = ((endValue - endHour) * 60).round();
                    final end = DateTime(
                      createdDate.year,
                      createdDate.month,
                      createdDate.day,
                      endHour,
                      endMin,
                    );

                    // 4. Durations and progress
                    final totalMins = _breakOutId == breakData.id
                        ? _lastBreakMinutes
                        : end.difference(start).inMinutes;
                    final elapsedSecs =
                        DateTime.now().difference(start).inSeconds;
                    final percent = totalMins > 0
                        ? (elapsedSecs / (totalMins * 60)).clamp(0.0, 1.0)
                        : 1.0;
                    final remainingSecs = (totalMins * 60) - elapsedSecs;

                    // 5. Timer colour
                    Color timerColor = AppColors.PRIMARY;
                    if (remainingSecs <= 300) timerColor = Colors.amber;
                    if (remainingSecs < 0) timerColor = AppColors.ERROR;
                    if (breakData.breakReason == "Lunch break" &&
                        remainingSecs < 0 &&
                        _lastBreakMinutes > 0) {
                      _endLunchBreak();
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: IntrinsicWidth(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (_breakOutId == breakData.id) ...[
                                    SizedBox(
                                      width: 55,
                                      height: 55,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            width: 55,
                                            height: 55,
                                            child: CircularProgressIndicator(
                                              value: percent != 1.0
                                                  ? 1 - percent
                                                  : 1.0,
                                              strokeWidth: 4,
                                              backgroundColor: Colors.grey[300],
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                timerColor,
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              _formatDuration(
                                                remainingSecs,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (breakData.breakReason != "Lunch break")
                                      GestureDetector(
                                        onTap: _isBreakEndLoading
                                            ? null
                                            : () {
                                                _handleBreakEnd(
                                                  breakOutStr:
                                                      breakData.breakOutStr ??
                                                          '',
                                                  breakReason:
                                                      breakData.breakReason ??
                                                          '',
                                                );
                                              },
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            if (_isBreakEndLoading)
                                              const SizedBox(
                                                width: 54,
                                                height: 54,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: AppColors.ERROR
                                                    .withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: _isBreakEndLoading
                                                  ? Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: AppColors.ERROR,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.stop,
                                                      color: AppColors.ERROR,
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ] else ...[
                                    Container(
                                      width: 55,
                                      height: 55,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromRGBO(
                                          27,
                                          117,
                                          171,
                                          0.3,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${totalMins}m',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 12),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(
                                            context,
                                          ).size.width *
                                          0.6,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          breakData.breakReason ?? '',
                                          textAlign: TextAlign.left,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            right: 10,
                            child: Text(
                              start.format12H,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 153, 147, 147),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------------------------------------------------------------------------------
  // UI Helpers
  // --------------------------------------------------------------------------------------------------------------------------------------------------

  void _showMinutesPicker(BuildContext context) {
    final List<int> minuteOptions = List.generate(
      12,
      (index) => (index + 1) * 5,
    );
    int selectedMinute = int.tryParse(_breakMinutes) ?? 5;
    int selectedIndex = minuteOptions.indexOf(selectedMinute);

    FixedExtentScrollController scrollController = FixedExtentScrollController(
      initialItem: selectedIndex >= 0 ? selectedIndex : 0,
    );

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.all(14),
          child: Column(
            children: [
              Text(
                'Select break minutes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ListWheelScrollView.useDelegate(
                      controller: scrollController,
                      itemExtent: 35,
                      diameterRatio: 1.2,
                      perspective: 0.005,
                      onSelectedItemChanged: (index) {
                        selectedMinute = minuteOptions[index];
                      },
                      physics: FixedExtentScrollPhysics(),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: minuteOptions.length,
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              '${minuteOptions[index]} min',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        height: 40,
                        margin: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _breakMinutes = selectedMinute.toString();
                    _breakMinutesController.text = _breakMinutes;
                    _breakMinutesError = null;
                  });
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.PRIMARY,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Select'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TimeInTimeOutDropdownModule {
  String? id;
  String? name;
  TimeInTimeOutDropdownModule({this.id, this.name});
}

class TimeInTimeOutMinutesDropdownModule {
  double? id;
  String? name;
  TimeInTimeOutMinutesDropdownModule({this.id, this.name});
}
