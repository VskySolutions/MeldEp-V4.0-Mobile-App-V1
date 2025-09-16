import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:test_project/boot/auth.dart';
import 'package:test_project/features/home/home.dart';
import 'package:test_project/features/my_task_and_activity/fill_timesheet/fill_timesheet_screen.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_edit/my_task_and_activity_edit.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_note/my_task_and_activity_note.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_page.dart';
import 'package:test_project/features/my_task_and_activity/my_task_and_activity_view_more/my_task_and_activity_view_more.dart';
import 'package:test_project/features/profile/profile_screen.dart';
import 'package:test_project/features/time_in_time_out/time_in_time_out_screen.dart';
import 'package:test_project/features/time_in_time_out/time_in_time_out_view_more/time_in_time_out_view_more.dart';
import 'package:test_project/features/timesheet/add_timesheet/add_timesheet_page.dart';
import 'package:test_project/features/timesheet/timesheets_page.dart';
import '../../features/auth/login/login_page.dart';
import '../../navigation/main_bottom_tab_bar.dart';
import '../../navigation/top_tab_org_management.dart';
import '../../features/org_management/apply_leave/apply_leave_screen.dart';




class AppRouter {
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static GoRouter get router => GoRouter(
    observers: [routeObserver],
    refreshListenable: AuthService.instance,
    initialLocation: AuthService.instance.isLoggedIn ? '/main/home' : '/login',
    routes: [
      // Public login route: can remain as-is
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // Non-tab detail routes: can remain as-is
      GoRoute(
        name: 'fillTimesheet',
        path: '/fillTimesheet/:id/:mins',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final mins = state.pathParameters['mins']!;
          return FillTimesheetScreen(id, activityMins: mins);
        },
      ),
      GoRoute(
        name: 'addTimesheet',
        path: '/addTimesheet/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return AddTimesheetScreen(timesheetId: id);
        },
      ),
      GoRoute(
        name: 'timeInTimeOutDetail',
        path: '/timeInTimeOutDetail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TimeInTimeOutViewMoreScreen(id: id);
        },
      ),
      GoRoute(
        name: 'myTaskAndActivityDetail',
        path: '/myTaskAndActivityDetail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProjectActivityDetailsScreen(id: id);
        },
      ),
      GoRoute(
        name: 'myTaskAndActivityEdit',
        path: '/myTaskAndActivityEdit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MyTaskAndActivityEditScreen(id: id);
        },
      ),
      GoRoute(
        name: 'myTaskAndActivityNote',
        path: '/myTaskAndActivityNote/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MyTaskAndActivityNoteScreen(id: id);
        },
      ),

      // Bottom tabs shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomTabBar(navigationShell: navigationShell);
        },
        branches: [
          // Home tab root: pageBuilder + key from state.uri
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'home',
                path: '/main/home',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey('home-${state.uri.toString()}'),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),

          // Task tab root
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'task',
                path: '/main/task',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey('task-${state.uri.toString()}'),
                  child: const TaskAndActivityScreen(),
                ),
              ),
            ],
          ),

          // Timesheet tab root
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'timesheet',
                path: '/main/timesheet',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey('timesheet-${state.uri.toString()}'),
                  child: const TimesheetScreen(),
                ),
              ),
            ],
          ),

          // Org tab root (with nested subroute)
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'org',
                path: '/main/org',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey('org-${state.uri.toString()}'),
                  child: const TopTabOrgManagement(),
                ),
                routes: [
                  GoRoute(
                    name: 'orgApplyLeave',
                    path: 'applyLeave',
                    builder: (_, __) => const ApplyLeaveScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Time-in/Time-out tab root
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'timeInTimeOut',
                path: '/main/timeInTimeOut',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey('tito-${state.uri.toString()}'),
                  child: TimeInTimeOutScreen(),
                ),
              ),
            ],
          ),

          // Profile tab root
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'profile',
                path: '/main/profile',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: ValueKey('profile-${state.uri.toString()}'),
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final loggedIn = AuthService.instance.isLoggedIn;
      final loggingIn = state.uri.path == '/login';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/main/home';
      return null;
    },
  );
}


