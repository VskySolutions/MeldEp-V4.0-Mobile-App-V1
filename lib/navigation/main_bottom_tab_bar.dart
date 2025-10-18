import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/core/flavor/flavor.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/floating_actions/floating_timer_panel.dart';
import 'timer_key.dart';

class BottomTabBar extends StatefulWidget {
  /// The shell that holds the Navigator stack for each tab
  final StatefulNavigationShell navigationShell;

  BottomTabBar({Key? key, required this.navigationShell}) : super(key: key);

  @override
  State<BottomTabBar> createState() => BottomTabBarState();
}

class BottomTabBarState extends State<BottomTabBar> {
  static const _titles = [
    'Home',
    'My Task And Activity',
    'Timesheet',
    'Org Management',
    'More',
  ];

  static const int moreIndex = 4;
  final showAppBarIndexes = [0, 3];

  // final GlobalKey<DraggableTimerState> draggableTimerKey = GlobalKey<DraggableTimerState>();
  // final GlobalKey draggableTimerKey = GlobalKey();

  bool _isMoreOpen = false;

  // MAP of tab index -> list of path-segment prefixes to consider that tab active.
  // Use path segments to avoid accidental prefix collisions.
  final Map<int, List<List<String>>> tabRoutePrefixes = {
    0: [
      ['main', 'home'],
    ],
    1: [
      ['main', 'task'],
    ],
    2: [
      ['main', 'timesheet'],
    ],
    3: [
      ['main', 'timeBuddy'],
    ],
    // More tab should include any branch that you want to treat as "More".
    // We include both /main/more (if ever used), /main/timeInTimeOut, and /main/profile
    4: [
      ['main', 'timeInTimeOut'],
      ['main', 'org'],
      ['main', 'profile'],
    ],
  };

  final Map<int, String> tabRootPaths = {
    0: '/main/home',
    1: '/main/task',
    2: '/main/timesheet',
    3: '/main/timeBuddy',
    4: '/main/timeInTimeOut', // Default for more tab
  };

  bool _matchPrefixSegments(List<String> prefix, List<String> actualSegments) {
    if (prefix.length > actualSegments.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (prefix[i] != actualSegments[i]) return false;
    }
    return true;
  }

  bool _isLocationInTab(String location, int tabIndex) {
    final uri = Uri.parse(location);
    final segments = uri.pathSegments; // e.g. ['main','profile']
    final prefixes = tabRoutePrefixes[tabIndex] ?? [];
    for (final p in prefixes) {
      if (_matchPrefixSegments(p, segments)) return true;
    }
    return false;
  }

  // void _onNavTap(int index) {
  //   if (index == moreIndex) {
  //     setState(() => _isMoreOpen = !_isMoreOpen);
  //     return;
  //   }

  //   if (_isMoreOpen) setState(() => _isMoreOpen = false);

  //   widget.navigationShell.goBranch(index);
  // }

  void _onNavTap(int index) {
    if (index == moreIndex) {
      setState(() => _isMoreOpen = !_isMoreOpen);
      return;
    }

    if (_isMoreOpen) setState(() => _isMoreOpen = false);

    final rootPath = _getRootPathForBranch(index);
    if (rootPath != null) {
      final refresh = DateTime.now().microsecondsSinceEpoch.toString();

      // Option A: Switch branch (safe if coming from another branch)
      widget.navigationShell.goBranch(index);

      // Force a remount of the root by changing the URI (updates the page key)
      final uri = Uri(path: rootPath, queryParameters: {'r': refresh});
      context.replace(uri.toString());
    }
  }

  // Helper method to navigate to the root of a branch
  void _navigateToRoot(int index) {
    final rootPath = _getRootPathForBranch(index);
    if (rootPath != null) {
      context.go(rootPath);
    }
  }

  // Define the root path for each branch
  String? _getRootPathForBranch(int index) {
    switch (index) {
      case 0:
        return '/main/home';
      case 1:
        return '/main/task';
      case 2:
        return '/main/timesheet';
      case 3:
        return '/main/timeBuddy';
      case 4:
        return '/main/org'; // Default for more tab
      default:
        return null;
    }
  }

  Widget _buildMorePanel(BuildContext context) {
    // Check which more item is currently active
    final location = GoRouterState.of(context).uri.toString();
    final isTimeInTimeOutActive =
        _isLocationInTab(location, 4) && location.contains('timeInTimeOut');
    final isOrgActive =
        _isLocationInTab(location, 4) && location.contains('org');
    final isEyeGlassesArActive =
        _isLocationInTab(location, 4) && location.contains('eyeGlassesAR');
    final isProfileActive =
        _isLocationInTab(location, 4) && location.contains('profile');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildMoreItem(
                  icon: Icons.approval,
                  label: 'Org',
                  onTap: () {
                    context.go('/main/org');
                    setState(() => _isMoreOpen = false);
                  },
                  isActive: isOrgActive,
                ),
                if (isDev) ...[
                  _buildMoreItem(
                    icon: Icons.access_time,
                    label: 'Time-in\nTime-out',
                    onTap: () {
                      context.go('/main/timeInTimeOut');
                      setState(() => _isMoreOpen = false);
                    },
                    isActive: isTimeInTimeOutActive,
                  ),
                  // _buildMoreItem(
                  //   icon: Icons.camera_alt_outlined,
                  //   label: 'AR',
                  //   onTap: () {
                  //     context.go('/eyeGlassesAR');
                  //     setState(() => _isMoreOpen = false);
                  //   },
                  //   isActive: isEyeGlassesArActive,
                  // ),
                ],
                _buildMoreItem(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () {
                    context.go('/main/profile');
                    setState(() => _isMoreOpen = false);
                  },
                  isActive: isProfileActive,
                ),
              ],
            ),
            _buildMoreItem(
              icon: Icons.expand_more_outlined,
              label: 'Less',
              onTap: () => setState(() => _isMoreOpen = false),
              isActive: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    final color = isActive ? AppColors.PRIMARY : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // shellIndex is the actual branch index held by the navigation shell
    final shellIndex = widget.navigationShell.currentIndex;
    final location = GoRouterState.of(context).uri.toString();

    // Determine which tab should be selected in the bottom bar (safe to use as index)
    int effectiveIndex;

    // If more panel open always highlight "More"
    if (_isMoreOpen) {
      effectiveIndex = moreIndex;
    } else {
      // find first matching prefix; fallback to shellIndex but clip into valid bottom items count
      final foundTab = tabRoutePrefixes.keys.firstWhere(
        (tab) => _isLocationInTab(location, tab),
        orElse: () => -1,
      );

      if (foundTab != -1) {
        effectiveIndex = foundTab;
      } else {
        // shellIndex might be >= bottom items count (this caused your crash).
        // Clamp shellIndex into bottom bar range:
        final bottomItemCount = 5; // you have 5 bottom items (0..4)
        if (shellIndex < 0) {
          effectiveIndex = 0;
        } else if (shellIndex >= bottomItemCount) {
          // if shell index belongs to a branch that doesn't have a bottom item, show "More"
          effectiveIndex = moreIndex;
        } else {
          effectiveIndex = shellIndex;
        }
      }
    }

    final showAppBar = showAppBarIndexes.contains(shellIndex);

    return Scaffold(
      // appBar: showAppBar
      //     ? ReusableAppBar(
      //         title: _titles[shellIndex.clamp(0, _titles.length - 1)],
      //       )
      //     : null,
      body: Stack(
        children: [
          widget.navigationShell,
          DraggableTimer(key: draggableTimerKey),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isMoreOpen) _buildMorePanel(context),
          BottomNavigationBar(
            // Use the safe effectiveIndex (guaranteed 0..items.length-1)
            currentIndex: effectiveIndex,
            onTap: _onNavTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.PRIMARY,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Task'),
              BottomNavigationBarItem(
                icon: Icon(Icons.timelapse_sharp),
                label: 'Timesheet',
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month), label: 'Meetings'),
              BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz),
                label: 'More',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
