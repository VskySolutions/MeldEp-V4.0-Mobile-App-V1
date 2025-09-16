import 'package:flutter/material.dart';
import 'package:test_project/core/constants/formats.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/buttons/custom_outlined_button.dart';
import 'package:test_project/core/widgets/date_picker/date_input_field.dart';
import 'package:test_project/core/widgets/input_field/custom_type_ahead_field.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/features/time_in_time_out/time_in_time_out_service.dart';

class TimeInTimeOutFilter extends StatefulWidget {
  final String? initialCreatedBy;
  final String? initialEmployeeId;
  final String? initialEmployeeName;
  final String? initialShiftId;
  final String? initialShiftName;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final bool isPrivilegedRole;

  /// Returns:
  /// (createdBy, employeeId, employeeName, shiftId, shiftName, fromDate, toDate)
  final void Function(
    String?,
    String?,
    String?,
    String?,
    String?,
    DateTime?,
    DateTime?,
  )
  onApplyFilter;

  /// Optional: if provided, popup will call it after Search / Clear
  final Future<void> Function()? onFetch;

  const TimeInTimeOutFilter({
    Key? key,
    required this.initialCreatedBy,
    required this.initialEmployeeId,
    required this.initialEmployeeName,
    required this.initialShiftId,
    required this.initialShiftName,
    required this.initialFromDate,
    required this.initialToDate,
    required this.isPrivilegedRole,
    required this.onApplyFilter,
    this.onFetch,
  }) : super(key: key);

  @override
  State<TimeInTimeOutFilter> createState() => _TimeInTimeOutFilterState();
}

class _TimeInTimeOutFilterState extends State<TimeInTimeOutFilter> {
  late String? _tmpCreatedBy;
  late String? _tmpEmployeeId;
  late String? _tmpEmployeeName;
  late String? _tmpShiftId;
  late String? _tmpShiftName;
  late DateTime? _tmpFromDate;
  late DateTime? _tmpToDate;

  List<Map<String, String>> _employeeList = [];
  List<Map<String, String>> _shiftList = [];

  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  bool _isLoading = true;
  bool _isApplying = false;

  List<Map<String, String>> createdByOptions = const [
    {"id": "Created By Me", "name": "Created By Me"},
    {"id": "View All", "name": "View All"},
  ];

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _loadInitialData();
  }

  void _initializeValues() {
    _tmpCreatedBy = widget.initialCreatedBy;
    _tmpEmployeeId = widget.initialEmployeeId;
    _tmpEmployeeName = widget.initialEmployeeName;
    _tmpShiftId = widget.initialShiftId;
    _tmpShiftName = widget.initialShiftName;
    _tmpFromDate = widget.initialFromDate;
    _tmpToDate = widget.initialToDate;

    if (_tmpFromDate != null) {
      _fromDateController.text = _tmpFromDate!.format();
    }
    if (_tmpToDate != null) {
      _toDateController.text = _tmpToDate!.format();
    }
  }

  void _loadInitialData() async {
    try {
      setState(() => _isLoading = true);

      // Load both dropdowns in parallel
      await Future.wait([_fetchEmployees(), _fetchShifts()]);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await TimeInTimeOutService.instance.fetchEmployees();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _employeeList = data
              .map(
                (e) => {
                  "id": e["id"] as String? ?? '',
                  "name": e["person"]?["fullName"] as String? ?? '',
                },
              )
              .toList();
        });
      } else {
        setState(() => _employeeList = []);
      }
    } catch (e) {
      setState(() => _employeeList = []);
    }
  }

  Future<void> _fetchShifts() async {
    try {
      final response = await TimeInTimeOutService.instance.fetchShifts();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _shiftList = data
              .map(
                (e) => {
                  "id": e["id"] as String? ?? '',
                  "name": e["dropdownValue"] as String? ?? '',
                },
              )
              .toList();
        });
      } else {
        setState(() => _shiftList = []);
      }
    } catch (e) {
      setState(() => _shiftList = []);
    }
  }

  Future<void> _applyFilters() async {
    setState(() => _isApplying = true);

    widget.onApplyFilter(
      _tmpCreatedBy,
      _tmpEmployeeId,
      _tmpEmployeeName,
      _tmpShiftId,
      _tmpShiftName,
      _tmpFromDate,
      _tmpToDate,
    );

    if (widget.onFetch != null) {
      await widget.onFetch!();
    }

    setState(() => _isApplying = false);
    Navigator.of(context).pop();
  }

  Future<void> _clearFilters() async {
    setState(() {
      _tmpCreatedBy = "Created By Me";
      _tmpEmployeeId = null;
      _tmpEmployeeName = null;
      _tmpShiftId = null;
      _tmpShiftName = null;
      _tmpFromDate = null;
      _tmpToDate = null;
      _fromDateController.clear();
      _toDateController.clear();
    });

    widget.onApplyFilter("Created By Me", null, null, null, null, null, null);

    if (widget.onFetch != null) {
      await widget.onFetch!();
    }
  }

  Future<void> _pickFromDate() async {
    final initialDate = _tmpFromDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _tmpFromDate = picked;
        _fromDateController.text = picked.format();
      });
    }
  }

  Future<void> _pickToDate() async {
    final initialDate = _tmpToDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _tmpToDate = picked;
        _toDateController.text = picked.format();
      });
    }
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter'),
      backgroundColor: Colors.white,
      content: SizedBox(
      width: MediaQuery.of(context).size.width * 0.95,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Created By
            CustomTypeAheadField(
              items: createdByOptions,
              selectedId: _tmpCreatedBy,
              label: "Created By",
              enabled: widget.isPrivilegedRole && !_isLoading,
              isLoading: _isLoading,
              onChanged: (value) => setState(() => _tmpCreatedBy = value),
            ),
            const SizedBox(height: 14),

            // Employee Name
            CustomTypeAheadField(
              items: _employeeList,
              selectedId: _tmpEmployeeId,
              label: "Employee Name",
              enabled: widget.isPrivilegedRole && !_isLoading,
              isLoading: _isLoading,
              onChanged: (value) {
                setState(() {
                  _tmpEmployeeId = value;
                  _tmpEmployeeName = _employeeList.firstWhere(
                    (e) => e['id'] == value,
                    orElse: () => {'name': ''},
                  )['name'];
                });
              },
            ),
            const SizedBox(height: 14),

            // Employee Shift
            CustomTypeAheadField(
              items: _shiftList,
              selectedId: _tmpShiftId,
              label: "Employee Shift",
              enabled: !_isLoading,
              isLoading: _isLoading,
              onChanged: (value) {
                setState(() {
                  _tmpShiftId = value;
                  _tmpShiftName = _shiftList.firstWhere(
                    (s) => s['id'] == value,
                    orElse: () => {'name': ''},
                  )['name'];
                });
              },
            ),
            const SizedBox(height: 14),
            DateInputField(
              labelText: 'From Date',
              initialDate: _tmpFromDate,
              onDateSelected: (date) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _tmpFromDate = date;
                      _fromDateController.text = date.format();
                    });
                  }
                });
              },
              onDateError: (value) {},
            ),
            const SizedBox(height: 14),

            DateInputField(
              labelText: 'To Date',
              initialDate: _tmpToDate,
              onDateSelected: (date) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _tmpToDate = date;
                      _toDateController.text = date.format();
                    });
                  }
                });
              },
              onDateError: (value) {},
            ),
          ],
        ),
      ),
      ),
      actions: [
        Row(
          children: [
            CustomOutlinedButton(
              onPressed: () => Navigator.pop(context),
              text: 'Close',
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            CustomOutlinedButton(
              onPressed: _clearFilters,
              text: 'Clear',
              color: Colors.black,
            ),
            const SizedBox(width: 8),
            CustomOutlinedButton(
              onPressed: _applyFilters,
              text: 'Search',
              color: AppColors.PRIMARY,
              isLoading: _isLoading,
            ),
          ],
        ),
      ],
    );
  }
}
