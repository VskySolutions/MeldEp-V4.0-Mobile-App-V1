import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class LocalStorage {
  LocalStorage._();
  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  // Strings
  static Future<bool> setAuthToken(String token) =>
      _prefs().then((p) => p.setString(StorageKeys.AUTH_TOKEN, token));

  static Future<String?> getAuthToken() =>
      _prefs().then((p) => p.getString(StorageKeys.AUTH_TOKEN));

  static Future<bool> clearAuthToken() =>
      _prefs().then((p) => p.remove(StorageKeys.AUTH_TOKEN));

  // Remember Me
  static Future<bool> setRememberMe(bool value) =>
      _prefs().then((p) => p.setBool(StorageKeys.REMEMBER_ME, value));

  static Future<bool?> getRememberMe() =>
      _prefs().then((p) => p.getBool(StorageKeys.REMEMBER_ME));

  static Future<bool> clearRememberMe() =>
      _prefs().then((p) => p.remove(StorageKeys.REMEMBER_ME));

  // Employee fields
  static Future<bool> setEmployeeId(String id) =>
      _prefs().then((p) => p.setString(StorageKeys.EMPLOYEE_ID, id));

  static Future<String?> getEmployeeId() =>
      _prefs().then((p) => p.getString(StorageKeys.EMPLOYEE_ID));

  static Future<bool> setEmployeeName(String name) =>
      _prefs().then((p) => p.setString(StorageKeys.EMPLOYEE_NAME, name));

  static Future<String?> getEmployeeName() =>
      _prefs().then((p) => p.getString(StorageKeys.EMPLOYEE_NAME));

  // Roles (string list)
  static Future<bool> setRoles(List<String> roles) =>
      _prefs().then((p) => p.setStringList(StorageKeys.ROLES, roles));

  static Future<List<String>?> getRoles() =>
      _prefs().then((p) => p.getStringList(StorageKeys.ROLES));

  // Time In
  static Future<bool> setTimeIn(String time) =>
      _prefs().then((p) => p.setString(StorageKeys.TIME_IN_KEY, time));

  static Future<String?> getTimeIn() =>
      _prefs().then((p) => p.getString(StorageKeys.TIME_IN_KEY));

  static Future<bool> clearTimeIn() =>
      _prefs().then((p) => p.remove(StorageKeys.TIME_IN_KEY));

  // Break Out
  static Future<bool> setBreakOut(String breakOut) =>
      _prefs().then((p) => p.setString(StorageKeys.BREAK_OUT_KEY, breakOut));

  static Future<String?> getBreakOut() =>
      _prefs().then((p) => p.getString(StorageKeys.BREAK_OUT_KEY));

  static Future<bool> clearBreakOut() =>
      _prefs().then((p) => p.remove(StorageKeys.BREAK_OUT_KEY));

  // Last Break Minutes (int)
  static Future<bool> setLastBreakMinutes(String minutes) => _prefs().then(
        (p) => p.setString(StorageKeys.LAST_BREAK_MINUTES_KEY, minutes),
      );

  // ICS helpers
  static Future<String?> getLastBreakMinutes() =>
      _prefs().then((p) => p.getString(StorageKeys.LAST_BREAK_MINUTES_KEY));

  static Future<bool> clearLastBreakMinutes() =>
      _prefs().then((p) => p.remove(StorageKeys.LAST_BREAK_MINUTES_KEY));

  static Future<bool> setIcsKey(String url) =>
      _prefs().then((p) => p.setString(StorageKeys.ICS_KEY, url));

  static Future<String?> getIcsKey() =>
      _prefs().then((p) => p.getString(StorageKeys.ICS_KEY));

  static Future<bool> clearIcsKey() =>
      _prefs().then((p) => p.remove(StorageKeys.ICS_KEY));

      
  // ---------------- TIMER STORAGE ----------------

  // Activity ID
  static Future<bool> setActivityIdTimer(String value) =>
      _prefs().then((p) => p.setString(StorageKeys.ACTIVITY_ID_TIMER, value));

  static Future<String?> getActivityIdTimer() =>
      _prefs().then((p) => p.getString(StorageKeys.ACTIVITY_ID_TIMER));

  static Future<bool> clearActivityIdTimer() =>
      _prefs().then((p) => p.remove(StorageKeys.ACTIVITY_ID_TIMER));

  // Task Name
  static Future<bool> setTaskNameTimer(String value) =>
      _prefs().then((p) => p.setString(StorageKeys.TASK_NAME_TIMER, value));

  static Future<String?> getTaskNameTimer() =>
      _prefs().then((p) => p.getString(StorageKeys.TASK_NAME_TIMER));

  static Future<bool> clearTaskNameTimer() =>
      _prefs().then((p) => p.remove(StorageKeys.TASK_NAME_TIMER));

  // Activity Name
  static Future<bool> setActivityNameTimer(String value) =>
      _prefs().then((p) => p.setString(StorageKeys.ACTIVITY_NAME_TIMER, value));

  static Future<String?> getActivityNameTimer() =>
      _prefs().then((p) => p.getString(StorageKeys.ACTIVITY_NAME_TIMER));

  static Future<bool> clearActivityNameTimer() =>
      _prefs().then((p) => p.remove(StorageKeys.ACTIVITY_NAME_TIMER));

  // ---------------- TIMESTAMP LIST ----------------

  static Future<List<String>> getActivityTimerTimestamps() async {
    final prefs = await _prefs();
    return prefs.getStringList(StorageKeys.ACTIVITY_TIMER_TIMESTAMP) ?? [];
  }

  static Future<bool> addActivityTimerTimestamp(String value) async {
    final prefs = await _prefs();
    final list =
        prefs.getStringList(StorageKeys.ACTIVITY_TIMER_TIMESTAMP) ?? [];
    list.add(value); // add at end
    return prefs.setStringList(StorageKeys.ACTIVITY_TIMER_TIMESTAMP, list);
  }

  static Future<bool> removeLastActivityTimerTimestamp() async {
    final prefs = await _prefs();
    final list =
        prefs.getStringList(StorageKeys.ACTIVITY_TIMER_TIMESTAMP) ?? [];
    if (list.isNotEmpty) {
      list.removeLast();
      return prefs.setStringList(StorageKeys.ACTIVITY_TIMER_TIMESTAMP, list);
    }
    return false;
  }

  static Future<bool> clearActivityTimerTimestamps() =>
      _prefs().then((p) => p.remove(StorageKeys.ACTIVITY_TIMER_TIMESTAMP));

  // Generic helpers
  static Future<bool> clearAll() => _prefs().then((p) => p.clear());

  // ---------------- CLEAR ALL TIMERS ----------------

  static Future<void> removeTimerData() async {
    final prefs = await _prefs();
    await prefs.remove(StorageKeys.ACTIVITY_ID_TIMER);
    await prefs.remove(StorageKeys.TASK_NAME_TIMER);
    await prefs.remove(StorageKeys.ACTIVITY_NAME_TIMER);
    await prefs.remove(StorageKeys.ACTIVITY_TIMER_TIMESTAMP);
  }

    // Update Banner Ignore Count
  static Future<int> getUpdateIgnoreCount() =>
      _prefs().then((p) => p.getInt(StorageKeys.UPDATE_IGNORE_COUNT) ?? 0);

  static Future<bool> incrementUpdateIgnoreCount() async {
    final prefs = await _prefs();
    final currentCount = prefs.getInt(StorageKeys.UPDATE_IGNORE_COUNT) ?? 0;
    return prefs.setInt(StorageKeys.UPDATE_IGNORE_COUNT, currentCount + 1);
  }

  static Future<bool> clearUpdateIgnoreCount() =>
      _prefs().then((p) => p.remove(StorageKeys.UPDATE_IGNORE_COUNT));
}


/*
---------------------------------------------------------
USE EXAMPLES
---------------------------------------------------------

// Example: saving auth token (what you showed)
await LocalStorage.setAuthToken(token);

// Example: saving employee data
await LocalStorage.setEmployeeId(responseData.employeeId);
await LocalStorage.setEmployeeName('${responseData.firstName} ${responseData.lastName}');
await LocalStorage.setRoles(responseData.roles);

// Example: reading back
final token = await LocalStorage.getAuthToken();        // String? (or null)
final empId = await LocalStorage.getEmployeeId();       // String?
final roles = await LocalStorage.getRoles();            // List<String>? or null

// Example: using date/time formats
final now = DateTime.now();
final dateStr = DateFormat(Formats.DATE_MMDDYYYY).format(now);      // e.g. 08/08/2025
final time12 = DateFormat(Formats.TIME_12H).format(now);            // e.g. 02:35 PM
final time24 = DateFormat(Formats.TIME_24H).format(now);            // e.g. 14:35

// Example: using colors
Container(
  color: AppColors.SCAFFOLD_BG,
  child: Text('Hello', style: TextStyle(color: AppColors.TEXT_PRIMARY)),
);

// Example: Accessing storage keys directly (rarely needed, prefer LocalStorage wrapper)
final key = StorageKeys.AUTH_TOKEN; // 'auth_token'
await prefs.setString(StorageKeys.AUTH_TOKEN, token);

*/