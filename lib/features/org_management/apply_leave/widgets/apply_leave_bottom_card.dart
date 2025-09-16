import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:test_project/core/constants/formats.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/validators.dart';
import 'package:test_project/core/widgets/snackbar/custom_snackbar.dart';
import 'package:test_project/features/org_management/org_management_service.dart';

Future<void> showApplyLeaveForm(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ApplyLeaveFormSheet(),
  );
}

class ApplyLeaveFormSheet extends StatefulWidget {
  const ApplyLeaveFormSheet({Key? key}) : super(key: key);

  @override
  _ApplyLeaveFormSheetState createState() => _ApplyLeaveFormSheetState();
}

class _ApplyLeaveFormSheetState extends State<ApplyLeaveFormSheet> {
  /// -----------------------------------------------------------------------------
  /// Variable Declarations
  /// -----------------------------------------------------------------------------
  /// // Controllers
  final TextEditingController _dateStartController = TextEditingController();
  final TextEditingController _dateEndController = TextEditingController();
  final TextEditingController _selectedLeaveTypeController =
      TextEditingController();
  final TextEditingController _reasonOfLeaveController =
      TextEditingController();
  final TextEditingController _totalLeaveDaysController =
      TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();

  // Dates
  DateTime? _startDate;
  DateTime? _endDate;

  // Booleans (must start with "is/has")
  bool _isHalfDay = false;
  bool _isFirstHalf = true;

  // Selection
  String _selectedLeaveTypeId = '';

  // Attachment
  File? _proofImage;

  // Validation errors
  String? _leaveTypeError;
  String? _startDateOfLeaveError;
  String? _endDateOfLeaveError;
  String? _reasonOfLeaveError;

  // Dropdown data (lists must end with "List")
  List<Map<String, String>> _leaveTypesList = <Map<String, String>>[];

  // Leave credits
  LeaveCreditsModel? _leaveCreditsDetails;
  bool _isLeaveCreditsLoading = false;

  // Submission
  bool _isSubmitting = false;

  /// -----------------------------------------------------------------------------
  /// Lifecycle
  /// -----------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadLeaveCategories();
    _loadLeaveCredits();
    _loadEmployeeName();
  }

  /// -----------------------------------------------------------------------------
  /// API Calls & Data Ops
  /// -----------------------------------------------------------------------------
  /// Loads leave categories for the typeahead dropdown.
  Future<void> _loadLeaveCategories() async {
    try {
      final response = await OrgManagementService.instance.fetchCategories();

      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data;
        final fetchedEmployeeNames =
            dataList.map((json) => LeaveCategoryModel.fromJson(json)).toList();

        setState(() {
          _leaveTypesList = fetchedEmployeeNames
              .map((module) => {"id": module.id, "name": module.name})
              .toList();
        });
      } else {
        throw Exception('Failed to load activity owner');
      }
    } catch (e) {
      debugPrint('_loadLeaveCategories error: $e');
    }
  }

  /// Loads current leave credit/balance details to show at the top.
  Future<void> _loadLeaveCredits() async {
    try {
      setState(() => _isLeaveCreditsLoading = true);

      final response =
          await OrgManagementService.instance.fetchLeaveBalanceDetails();

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _leaveCreditsDetails = LeaveCreditsModel.fromJson(data);
          _isLeaveCreditsLoading = false;
        });
      } else {
        throw Exception('Failed to load activity owner');
      }
    } catch (e) {
      debugPrint('_loadLeaveCredits error: $e');
      setState(() => _isLeaveCreditsLoading = false);
    }
  }

  /// Builds and posts the leave application (multipart form) to the server.
  Future<void> _postLeaveApplication({
    required String fromDateStr,
    required String toDateStr,
    required bool isHalfDay,
    required bool halfDay,
    required String leaveCategoryId,
    required String employeeName,
    required String noOfLeaves,
    required String reason,
    required String fileChangeFlag,
    required String leaveCreditId,
    File? filePic,
    required BuildContext context,
  }) async {
    final formData = FormData.fromMap({
      'fromDateStr': fromDateStr,
      'toDateStr': toDateStr,
      'isHalfDay': isHalfDay.toString(),
      'halfDay': halfDay.toString(),
      'leaveCategoryId': leaveCategoryId,
      'employeeName': employeeName,
      'noofLeaves': noOfLeaves,
      'reason': reason,
      'fileChangeFlag': fileChangeFlag,
      'leaveCreditId': leaveCreditId,
      if (filePic != null)
        'filePic': await MultipartFile.fromFile(
          filePic.path,
          filename: filePic.path.split('/').last,
        ),
    });

    try {
      setState(() {
        _isSubmitting = true;
      });

      Fluttertoast.showToast(
        msg: "Submitting… please wait",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      );

      final response = await OrgManagementService.instance.applyLeave(formData);

      if (response.statusCode == 204) {
        showCustomSnackBar(
          context,
          message: 'Leave applied successfully!',
          durationSeconds: 2,
        );
        context.pop();
      } else {
        throw Exception('Failed to apply leave');
      }
    } catch (e) {
      debugPrint('applyLeave error: $e');
      setState(() => _isSubmitting = false);
    }
  }

  /// -----------------------------------------------------------------------------
  /// Actions & Event Handlers
  /// -----------------------------------------------------------------------------
  /// Fetches and sets the employee name into the form field.
  Future<void> _loadEmployeeName() async {
    setState(() async {
      _employeeNameController.text = await LocalStorage.getEmployeeName() ?? "";
    });
  }

  /// Opens date picker and applies the selected date (start or end).
  Future<void> _onPickDatePressed({
    required TextEditingController ctrl,
    required bool isStart,
  }) async {
    final now = DateTime.now();
    final first = isStart ? DateTime(2020) : _startDate ?? DateTime(2020);
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? now : (_startDate ?? now),
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          ctrl.text = ConstFormats.DATE_FORMAT.format(picked);
          _startDateOfLeaveError = null;
          _endDateOfLeaveError = null;
          if (_isHalfDay) {
            _endDate = picked;
            _dateEndController.text = ctrl.text;
          }
          if (!_isHalfDay) {
            // if (_endDate == null || _endDate!.isBefore(picked)) {
            //   _endDate = picked;
            //   _dateEndController.text = ctrl.text;
            // }
          }
        } else {
          _endDate = picked;
          ctrl.text = ConstFormats.DATE_FORMAT.format(picked);
          _endDateOfLeaveError = null;
        }
      });
    }
  }

  /// Validates fields and triggers the leave submission.
  void _onSubmitPressed(BuildContext context) async {
    _leaveTypeError = Validators.validateText(
      _selectedLeaveTypeId,
      fieldName: "Leave type",
    );
    _reasonOfLeaveError = Validators.validateDescription(
      _reasonOfLeaveController.text,
      fieldName: "Reason of leave",
    );
    _onDateChanged(_dateStartController.text.toString(), true);
    _onDateChanged(_dateEndController.text.toString(), false);

    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      _endDateOfLeaveError = 'End date should be after start date';
    }

    setState(() {});

    if (_leaveTypeError != null ||
        _reasonOfLeaveError != null ||
        _startDateOfLeaveError != null ||
        (_endDateOfLeaveError != null && !_isHalfDay)) return;

    await _postLeaveApplication(
      fromDateStr: _formatToMMDDYYYY(_dateStartController.text),
      toDateStr: _formatToMMDDYYYY(_dateEndController.text),
      isHalfDay: _isHalfDay,
      halfDay: _isFirstHalf,
      leaveCategoryId: _selectedLeaveTypeId,
      employeeName: _employeeNameController.text,
      noOfLeaves: _totalDays.toString(),
      reason: _reasonOfLeaveController.text,
      fileChangeFlag: 'new',
      leaveCreditId: '',
      filePic: _proofImage,
      context: context,
    );

    // print('''
    // --- Apply Leave Request ---
    // fromDateStr     : ${_formatToMMDDYYYY(_dateStartController.text)}
    // fromDateEnd     : ${_formatToMMDDYYYY(_dateEndController.text)}
    // isHalfDay       : $_isFirstHalf
    // halfDay         : $_isHalfDay
    // leaveCategoryId : $_selectedLeaveTypeId
    // employeeName    : ${_employeeNameController.text}
    // noOfLeaves      : '${_totalDays.toString()}'
    // reason          : '${_reasonOfLeaveController.text}'
    // fileChangeFlag  : edit
    // leaveCreditId   : ''
    // proofImage      : ${_proofImage != null ? _proofImage!.path : 'None'}
    // ''');
  }

  /// Picks an image using the camera and sets it as proof.
  Future<void> _onPickFromCameraPressed() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) setState(() => _proofImage = File(file.path));
  }

  /// Picks an image from the gallery and sets it as proof.
  Future<void> _onPickFromGalleryPressed() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _proofImage = File(file.path));
  }

  double get _totalDays {
    double totalLeaveDays;
    if (_isHalfDay) {
      totalLeaveDays = 0.5;
      _totalLeaveDaysController.text = totalLeaveDays.toString();
      return totalLeaveDays;
    }
    if (_startDate == null || _endDate == null) {
      _totalLeaveDaysController.text = '0';
      return 0;
    }
    totalLeaveDays = _endDate!.difference(_startDate!).inDays + 1;
    _totalLeaveDaysController.text = totalLeaveDays.toString();
    return totalLeaveDays.toDouble();
  }

  String _formatToMMDDYYYY(String input) {
    final parsedDate = DateFormat(ConstFormats.DATE_MMDDYYYY).parse(input);
    return DateFormat(
      ConstFormats.DATE_MMDDYYYY,
    ).format(parsedDate);
  }

  void _onDateChanged(String text, bool isStartDate) {
    final String? _isDateError = Validators.validateDate(text);

    setState(() {
      if (_isDateError == null) {
        final parsedDate = ConstFormats.DATE_FORMAT.parseStrict(text);

        if (isStartDate) {
          _startDate = parsedDate;
          _startDateOfLeaveError = null;

          if (_isHalfDay && _dateStartController.text.isNotEmpty) {
            _dateEndController.text = _formatToMMDDYYYY(
              _dateStartController.text,
            );
            _endDate = ConstFormats.DATE_FORMAT.parseStrict(
              _dateEndController.text,
            );
            _endDateOfLeaveError = null;
          }
        } else {
          _endDate = parsedDate;
          _endDateOfLeaveError = null;
        }
      } else {
        if (isStartDate) {
          _startDateOfLeaveError = _isDateError;
        } else {
          _endDateOfLeaveError = _isDateError;
        }
      }
    });
  }

  /// -----------------------------------------------------------------------------
  /// UI
  /// -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      builder: (_, ctl) => Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: EdgeInsets.only(bottom: 60),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    height: 5,
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Apply Leave',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 500,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.lightBlue.shade300,
                  child: _isLeaveCreditsLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.PRIMARY,
                          ),
                        )
                      : _leaveCreditsDetails != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Total Leaves: ${_leaveCreditsDetails!.totalLeaves} '
                                  'Casual Leaves: ${_leaveCreditsDetails!.casualLeaves}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Sick Leaves: ${_leaveCreditsDetails!.sickLeaves} '
                                  'Leave Balance: ${_leaveCreditsDetails!.leaveBalance}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : const Text('Leave details not available'),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      child: ListView(
                        controller: ctl,
                        children: [
                          // Employee Name
                          TextFormField(
                            // initialValue: _employeeName,
                            decoration: const InputDecoration(
                              labelText: 'Employee Name *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            readOnly: true,
                            controller: _employeeNameController,
                          ),
                          const SizedBox(height: 16),
                          TypeAheadField(
                            suggestionsCallback: (pattern) {
                              return _leaveTypesList.where((item) {
                                return item['name']!.toLowerCase().contains(
                                      pattern.toLowerCase(),
                                    );
                              }).toList();
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                title: Text(suggestion['name'].toString()),
                              );
                            },
                            onSelected: (suggestion) {
                              setState(() {
                                _selectedLeaveTypeId =
                                    suggestion['id'].toString();
                                _selectedLeaveTypeController.text =
                                    suggestion['name'].toString();
                                _leaveTypeError = null;
                              });
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
                              child: Text('Leave type not found'),
                            ),
                            builder: (context, fieldController, focusNode) {
                              final showClear = fieldController.text.isNotEmpty;
                              return TextField(
                                controller: fieldController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Leave Type *',
                                  errorText: _leaveTypeError,
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
                                              _leaveTypeError = null;
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
                                  setState(() {});
                                },
                              );
                            },
                            controller: _selectedLeaveTypeController,
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _dateStartController,
                            keyboardType: TextInputType.datetime,
                            onChanged: (value) => _onDateChanged(value, true),
                            decoration: InputDecoration(
                              labelText: 'Start Date of Leave *',
                              hintText: ConstFormats.DATE_MMDDYYYY,
                              errorText: _startDateOfLeaveError,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: () => _onPickDatePressed(
                                  ctrl: _dateStartController,
                                  isStart: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Half Day
                          Row(
                            children: [
                              Checkbox(
                                value: _isHalfDay,
                                onChanged: (v) => setState(() {
                                  _isHalfDay = v!;
                                  if (_isHalfDay) {
                                    _endDate = _startDate;
                                    _dateEndController.text =
                                        _dateStartController.text;
                                  }
                                }),
                              ),
                              const Text('Half Day'),
                              if (_isHalfDay) ...[
                                const SizedBox(width: 16),
                                Radio<bool>(
                                  value: true,
                                  groupValue: _isFirstHalf,
                                  onChanged: (v) =>
                                      setState(() => _isFirstHalf = v!),
                                ),
                                const Text('1st Half'),
                                Radio<bool>(
                                  value: false,
                                  groupValue: _isFirstHalf,
                                  onChanged: (v) =>
                                      setState(() => _isFirstHalf = v!),
                                ),
                                const Text('2nd Half'),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. End Date
                          TextField(
                            controller: _dateEndController,
                            keyboardType: TextInputType.datetime,
                            onChanged: (value) => _onDateChanged(value, false),
                            decoration: InputDecoration(
                              labelText: 'End Date of Leave *',
                              hintText: ConstFormats.DATE_MMDDYYYY,
                              errorText: _endDateOfLeaveError,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: _isHalfDay
                                    ? null
                                    : () => _onPickDatePressed(
                                          ctrl: _dateEndController,
                                          isStart: false,
                                        ),
                              ),
                            ),
                            enabled: !_isHalfDay,
                          ),
                          const SizedBox(height: 16),

                          // 4. Total Leave Days
                          TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Total Leave Days',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              hintText: _totalDays.toString(),
                            ),
                            controller: _totalLeaveDaysController,
                          ),
                          const SizedBox(height: 16),

                          // 5. Reason
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Reason *',
                              errorText: _reasonOfLeaveError,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) => setState(() {
                              _reasonOfLeaveError = null;
                            }),
                            maxLines: 3,
                            controller: _reasonOfLeaveController,
                          ),
                          const SizedBox(height: 16),
                          Text('Proof Of Medical'),
                          if (_proofImage != null)
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // The proof box with image preview
                                Container(
                                  height: 140,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.file(
                                      _proofImage!,
                                      // fit: BoxFit.cover,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _proofImage = null;
                                      });
                                    },
                                    icon: Icon(Icons.cancel),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: double.infinity,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    onTap: _onPickFromCameraPressed,
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(24),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.camera_alt, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'Camera',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Colors.grey.shade300,
                                  ),
                                  InkWell(
                                    onTap: _onPickFromGalleryPressed,
                                    borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(24),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.insert_drive_file,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'File',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 16,
            child: Opacity(
              opacity: _isLeaveCreditsLoading || _isSubmitting
                  ? 0.5
                  : 1.0, // fade when loading
              child: FloatingActionButton.extended(
                onPressed: _isLeaveCreditsLoading || _isSubmitting
                    ? null
                    : () => _onSubmitPressed(context),
                backgroundColor: AppColors.PRIMARY,
                label: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
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
class LeaveCategoryModel {
  final String id;
  final String name;

  LeaveCategoryModel({required this.id, required this.name});

  factory LeaveCategoryModel.fromJson(Map<String, dynamic> json) {
    return LeaveCategoryModel(
      id: json['id'] ?? '',
      name: json['dropdownValue'] ?? '',
    );
  }
}

class LeaveCreditsModel {
  final String _totalLeaves;
  final String _casualLeaves;
  final String _sickLeaves;
  final double _leaveBalance;

  LeaveCreditsModel({
    required String totalLeaves,
    required String casualLeaves,
    required String sickLeaves,
    required double leaveBalance,
  })  : _totalLeaves = totalLeaves,
        _casualLeaves = casualLeaves,
        _sickLeaves = sickLeaves,
        _leaveBalance = leaveBalance;

  factory LeaveCreditsModel.fromJson(Map<String, dynamic> json) {
    return LeaveCreditsModel(
      totalLeaves: json['totalLeaves'] ?? '',
      casualLeaves: json['casualLeaves'] ?? '',
      sickLeaves: json['sickLeaves'] ?? '',
      leaveBalance: (json['leaveBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get totalLeaves => _totalLeaves;
  String get casualLeaves => _casualLeaves;
  String get sickLeaves => _sickLeaves;
  double get leaveBalance => _leaveBalance;
}
