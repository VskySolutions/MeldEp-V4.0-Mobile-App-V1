import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/core/dialogs/delete_confirmation_dialog.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/custom_snackbar.dart';

class DraggableTimer extends StatefulWidget {
  final Duration initialDuration;
  final double panelSize;
  final double panelRight;
  final double panelTopOffset;
  final double panelTopDelta;

  const DraggableTimer({
    Key? key,
    this.initialDuration = Duration.zero,
    this.panelSize = 60.0,
    this.panelRight = 10.0,
    this.panelTopOffset = 0.5,
    this.panelTopDelta = 100.0,
  }) : super(key: key);

  @override
  DraggableTimerState createState() => DraggableTimerState();
}

class DraggableTimerState extends State<DraggableTimer>
    with SingleTickerProviderStateMixin {
  // position (left/top)
  double? _left;
  double? _top;

  // dimensions
  final double _collapsedSize = 65.0; // circular bubble when collapsed

  String? _activityId;
  String? _taskName;
  String? _activityName;
  bool _showFloatingTimer = false;

  // timer state
  Duration _duration = Duration.zero;
  Timer? _ticker;
  bool _isRunning = false;

  // UI state
  bool _expanded = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    restoreActiveTimer();
    _duration = widget.initialDuration;
    _ticker = Timer.periodic(Duration(seconds: 1), (_) {
      if (_isRunning) if (mounted)
        setState(() => _duration += Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> restoreActiveTimer() async {
    try {
      final activeId = await LocalStorage.getActivityIdTimer();
      if (activeId == null) return;

      final timerTimestamp = await LocalStorage.getActivityTimerTimestamps();
      final duration = _calcDurationFromTimestamps(timerTimestamp);
      final isRunning =
          (timerTimestamp.isNotEmpty && (timerTimestamp.length % 2 == 1));

      final taskName = await LocalStorage.getTaskNameTimer();
      final activityName = await LocalStorage.getActivityNameTimer();

      debugPrint(
        "Restored Timer -> id: $activeId | duration: $duration | running: $isRunning",
      );

      if (!mounted) return;
      setState(() {
        _activityId = activeId;
        _taskName = taskName;
        _activityName = activityName;
        _duration = duration;
        _isRunning = isRunning;
        _showFloatingTimer = true;
      });

      // optional: restore dock side if you persist it (not required)
      // final dock = await LocalStorage.getTimerDockSide();
      // if (dock == 'left') _left = 8.0;
      // if (dock == 'right') _left = MediaQuery.of(context).size.width - _collapsedSize - 8.0;
    } catch (e, st) {
      debugPrint('Error restoring timer: $e\n$st');
      if (mounted) {
        try {
          showCustomSnackBar(
            context,
            message: 'Failed to restore timer',
            backgroundColor: AppColors.ERROR,
          );
        } catch (_) {}
      }
    }
  }

  static Duration _calcDurationFromTimestamps(List<String> timestampStrings) {
    if (timestampStrings.isEmpty) return Duration.zero;

    int totalMilliseconds = 0;
    final now = DateTime.now();

    for (int i = 0; i < timestampStrings.length; i += 2) {
      try {
        final startTime = DateTime.parse(timestampStrings[i]);

        DateTime endTime;
        if (i + 1 < timestampStrings.length) {
          endTime = DateTime.parse(timestampStrings[i + 1]);
        } else {
          endTime = now;
        }
        final duration = endTime.difference(startTime);
        if (duration.inMilliseconds > 0) {
          totalMilliseconds += duration.inMilliseconds;
        }
      } catch (e) {
        print("Error parsing timestamp: $e");
      }
    }
    return Duration(milliseconds: totalMilliseconds);
  }

  Future<void> startActiveTimer(
    String activityIdStr,
    String taskNameStr,
    String activityNameStr,
  ) async {
    try {
      final r1 = await LocalStorage.setActivityIdTimer(activityIdStr);
      final r2 = await LocalStorage.setTaskNameTimer(taskNameStr);
      final r3 = await LocalStorage.setActivityNameTimer(activityNameStr);
      final r4 = await LocalStorage.addActivityTimerTimestamp(
        DateTime.now().toString(),
      );

      bool success = _wrappedBool(r1) &&
          _wrappedBool(r2) &&
          _wrappedBool(r3) &&
          _wrappedBool(r4);

      if (!success) {
        if (mounted) {
          showCustomSnackBar(
            context,
            message: 'Failed to start timer',
            backgroundColor: AppColors.ERROR,
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _activityId = activityIdStr;
        _taskName = taskNameStr;
        _activityName = activityNameStr;
        _showFloatingTimer = true;
        _isRunning = true;
      });

      showCustomSnackBar(
        context,
        message: 'Task Timer Started',
        durationSeconds: 2,
      );
    } catch (e, st) {
      debugPrint('Error starting timer: $e\n$st');
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Failed to start timer',
          backgroundColor: AppColors.ERROR,
        );
      }
    }
  }

  Future<void> _toggleRunning() async {
    try {
      final res = await LocalStorage.addActivityTimerTimestamp(
        DateTime.now().toString(),
      );
      final ok = _wrappedBool(res);
      if (!ok) {
        if (mounted) {
          showCustomSnackBar(
            context,
            message: 'Failed to update timer',
            backgroundColor: AppColors.ERROR,
          );
        }
        return;
      }

      if (!mounted) return;

      final bool nextRunning = !_isRunning;
      setState(() => _isRunning = nextRunning);

      if (!nextRunning) {
        showCustomSnackBar(
          context,
          message: 'Task Timer Paused',
          backgroundColor: Colors.amber,
        );
      } else {
        showCustomSnackBar(
          context,
          message: 'Task Timer Resumed',
          durationSeconds: 2,
        );
      }
    } catch (e, st) {
      debugPrint('Error toggling timer: $e\n$st');
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Failed to update timer',
          backgroundColor: AppColors.ERROR,
        );
      }
    }
  }

  Future<void> _showTaskDetails() async {
    Fluttertoast.showToast(
      msg: "$_taskName \n($_activityName)",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _restart() async {
    try {
      final res = await LocalStorage.clearActivityTimerTimestamps();
      final ok = _wrappedBool(res);
      if (!ok) {
        if (mounted) {
          showCustomSnackBar(
            context,
            message: 'Failed to reset timer',
            backgroundColor: AppColors.ERROR,
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _duration = Duration.zero;
        _isRunning = false;
      });

      showCustomSnackBar(
        context,
        message: 'Task Timer reset Successfully',
        durationSeconds: 2,
      );
    } catch (e, st) {
      debugPrint('Error restarting timer: $e\n$st');
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Failed to reset timer',
          backgroundColor: AppColors.ERROR,
        );
      }
    }
  }

  Future<void> _delete() async {
    try {
      showDeleteConfirmationDialog(
        context,
        title: "Delete Confirmation",
        description: "Are you sure you want to remove this entry permanently?",
        subDescription: _fmt(_duration),
        onDelete: () async {
          try {
            await LocalStorage.removeTimerData();

            if (!mounted) return;
            setState(() {
              _duration = Duration.zero;
              _showFloatingTimer = false;
              _isRunning = false;
              _activityId = null;
              _taskName = null;
              _activityName = null;
            });

            showCustomSnackBar(
              context,
              message: 'Task Timer Deleted it successfully',
              durationSeconds: 2,
            );
          } catch (e, st) {
            debugPrint('Error deleting timer data: $e\n$st');
            if (mounted) {
              showCustomSnackBar(
                context,
                message: 'Failed to delete timer',
                backgroundColor: AppColors.ERROR,
              );
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Error showing delete confirmation: $e');
    }
  }

  Future<void> _send() async {
    if (_duration.inMinutes < 1) {
      showCustomSnackBar(
        context,
        message: 'Task timer cannot be less than 1 min',
        backgroundColor: Colors.amber,
      );
      return;
    }

    try {
      final totalSeconds = _duration.inSeconds;
      int hours = totalSeconds ~/ 3600;
      final remainingSeconds = totalSeconds % 3600;
      final minutesFloat = remainingSeconds / 60.0;

      int convertedMinutes = ((minutesFloat / 60.0) * 100.0).round();

      if (convertedMinutes >= 100) {
        hours += 1;
        convertedMinutes = 0;
      }

      final hh = hours.toString().padLeft(2, '0');
      final mm = convertedMinutes.toString().padLeft(2, '0');
      final formatted = '$hh.$mm';

      final safeId = Uri.encodeComponent(_activityId ?? '');
      final safeTime = Uri.encodeComponent(formatted);

      final isSaveAndClose = await context.push(
        '/fillTimesheet/$safeId/$safeTime',
      );

      if (isSaveAndClose == true) {
        await LocalStorage.removeTimerData();

        if (!mounted) return;
        setState(() {
          _duration = Duration.zero;
          _showFloatingTimer = false;
          _isRunning = false;
          _activityId = null;
          _taskName = null;
          _activityName = null;
        });
      }
    } catch (e, st) {
      debugPrint('Error sending timesheet: $e\n$st');
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Failed to send to timesheet',
          backgroundColor: AppColors.ERROR,
        );
      }
    }
  }

  bool _wrappedBool(dynamic r) {
    if (r is bool) return r;
    if (r == null) return true;
    try {
      return r != false;
    } catch (_) {
      return true;
    }
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  // If < 1 hour -> mm:ss, else -> hh:mm
  String _expandedTimerFormat(Duration d) {
    if (d.inHours > 0) {
      final hh = d.inHours.toString().padLeft(2, '0');
      final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      return "$hh:$mm";
    } else {
      final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return "$mm:$ss";
    }
  }

  void _ensureInitialPosition(BuildContext context) {
    if (_left != null && _top != null) return;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final panelTop = h * widget.panelTopOffset - widget.panelTopDelta;

    final double initialLeft = w -
        widget.panelRight -
        widget.panelSize +
        (widget.panelSize - _collapsedSize) / 2;
    final double initialTop =
        panelTop + (widget.panelSize - _collapsedSize) / 2;

    _left = initialLeft;
    _top = initialTop;
    _clampToBounds(context);
  }

  void _clampToBounds(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final minLeft = 8.0;

    final maxLeft = sw - _collapsedSize - 8.0;
    final minTop = 8.0 + MediaQuery.of(context).padding.top;

    final double bottomBarHeight = 56.0;
    final maxTop = sh -
        _collapsedSize -
        30.0 -
        MediaQuery.of(context).padding.bottom -
        bottomBarHeight;

    _left = (_left ?? minLeft).clamp(minLeft, maxLeft);
    _top = (_top ?? minTop).clamp(minTop, maxTop);
  }

  void _dockToNearestSide(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final centerX = (_left ?? 0) + (_collapsedSize / 2);
    final bool dockToLeft = centerX <= (sw / 2);

    final targetLeft = dockToLeft ? 8.0 : (sw - _collapsedSize - 8.0);

    setState(() {
      _left = targetLeft;
      _clampToBounds(context);
      _dragging = false;
    });

    // optionally persist dock side
    // try {
    //   LocalStorage.setTimerDockSide(dockToLeft ? 'left' : 'right');
    // } catch (_) {}
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) _clampToBounds(context);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _ensureInitialPosition(context));
      }
    });

    if (!_showFloatingTimer) return SizedBox.shrink();
    if (_left == null || _top == null) return SizedBox.shrink();

    final sw = MediaQuery.of(context).size.width;
    final maxExpandedWidth = sw * 0.16; // responsive cap
    final expandedWidth = min(maxExpandedWidth, 360.0);

    // compute left for expanded state so it never overflows horizontally
    double effectiveLeft = _left ?? 8.0;
    if (_expanded) {
      // Prefer to keep the bubble visually "attached":
      // if bubble is on right half, place expanded so it grows leftwards,
      // otherwise grow rightwards from bubble left.
      final bubbleCenterX = (_left ?? 0) + (_collapsedSize / 2);
      if (bubbleCenterX > sw / 2) {
        // bubble on right side: align expanded right edge to bubble right edge
        double candidate = (_left ?? 0) + _collapsedSize - expandedWidth;
        if (candidate < 8.0) candidate = 8.0;
        if (candidate + expandedWidth + 8.0 > sw)
          candidate = sw - expandedWidth - 8.0;
        effectiveLeft = candidate;
      } else {
        // bubble on left side: align expanded left to bubble left (but clamp)
        double candidate = _left ?? 8.0;
        if (candidate + expandedWidth + 8.0 > sw)
          candidate = sw - expandedWidth - 8.0;
        if (candidate < 8.0) candidate = 8.0;
        effectiveLeft = candidate;
      }
    }

    return Stack(
      children: [
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (mounted) setState(() => _expanded = false);
              },
            ),
          ),
        AnimatedPositioned(
          duration: Duration(milliseconds: 240),
          curve: Curves.easeOut,
          left: _expanded ? effectiveLeft : _left,
          top: _top,
          child: GestureDetector(
            onPanStart: (details) {
              _dragging = true;
              if (_expanded) {
                setState(() {
                  _expanded = false;
                });
                _clampToBounds(context);
              }
            },
            onPanUpdate: (details) {
              setState(() {
                _left = (_left ?? 0) + details.delta.dx;
                _top = (_top ?? 0) + details.delta.dy;
                _clampToBounds(context);
              });
            },
            onPanEnd: (details) {
              _dockToNearestSide(context);
            },
            onTap: () {
              _toggleExpanded();
            },
            child: AnimatedSize(
              duration: Duration(milliseconds: 160),
              curve: Curves.easeInOut,
              child: _expanded
                  ? _buildExpanded(context, expandedWidth)
                  : _buildCollapsed(context),
              alignment: Alignment.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    return Material(
      elevation: 6,
      shape: CircleBorder(),
      color: Colors.transparent,
      child: Container(
        width: _collapsedSize,
        height: _collapsedSize,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26),
        ),
        child: Center(
          child: Text(
            _shortFormat(_duration),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
    );
  }

  Widget _buildExpanded(BuildContext context, double maxWidth) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 60),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag dots (top) - tapping collapses
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _expanded = false);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dot(),
                        const SizedBox(width: 6),
                        _dot(),
                        const SizedBox(width: 6),
                        _dot(),
                      ],
                    ),
                  ),
                ),
              ),

              // timer display
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _expandedTimerFormat(_duration),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              Container(height: 2, color: Colors.black12),

              // action blocks stacked vertically (icons only). Each block is full width and tappable.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _verticalActionBlock(
                    icon: Icons.info,
                    onTap: _showTaskDetails,
                  ),
                  _verticalDivider(),
                  _verticalActionBlock(
                    IconColor: _isRunning ? AppColors.ERROR : AppColors.SUCCESS,
                    icon: _isRunning
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    onTap: _toggleRunning,
                  ),
                  _verticalDivider(),
                  _verticalActionBlock(icon: Icons.refresh, onTap: _restart),
                  _verticalDivider(),
                  _verticalActionBlock(
                    IconColor: AppColors.ERROR,
                    icon: Icons.delete_outline,
                    onTap: _delete,
                  ),
                  _verticalDivider(),
                  _verticalActionBlock(
                    icon: Icons.send,
                    IconColor: AppColors.SUCCESS,
                    onTap: _send,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verticalDivider() => Container(height: 2, color: Colors.black12);

  Widget _verticalActionBlock({
    required IconData icon,
    required VoidCallback onTap,
    Color IconColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Center(child: Icon(icon, size: 26, color: IconColor)),
      ),
    );
  }

  // short mm:ss or h:mm:ss if hours > 0
  String _shortFormat(Duration d) {
    if (d.inHours > 0)
      return "${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}";
    return "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }
}
