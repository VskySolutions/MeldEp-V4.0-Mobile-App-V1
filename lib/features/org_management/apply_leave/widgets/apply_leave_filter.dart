import 'package:flutter/material.dart';
import 'package:test_project/core/constants/formats.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/utils/extensions.dart';
import 'package:test_project/core/widgets/buttons/custom_outlined_button.dart';
import 'package:test_project/core/widgets/date_picker/date_input_field.dart';
import 'package:test_project/core/widgets/input_field/custom_type_ahead_field.dart';
import 'package:test_project/features/org_management/org_management_service.dart';

class ApplyLeaveFilter extends StatefulWidget {
  final String? initialStatus;
  final String? initialCategory;
  final DateTime? initialDate;
  final String? initialYear;

  /// Called when user presses Search (status, category, date, year)
  final void Function(String?, String?, DateTime?, String?) onApplyFilter;

  /// Optional: the popup can call parent fetch if provided (not required).
  final Future<void> Function()? onFetch;

  const ApplyLeaveFilter({
    Key? key,
    required this.initialStatus,
    required this.initialCategory,
    required this.initialDate,
    required this.initialYear,
    required this.onApplyFilter,
    this.onFetch,
  }) : super(key: key);

  @override
  State<ApplyLeaveFilter> createState() => _ApplyLeaveFilterState();
}

class _ApplyLeaveFilterState extends State<ApplyLeaveFilter> {
  late String? _tmpStatus;
  late String? _tmpCategory;
  late DateTime? _tmpDate;
  late String? _tmpYear;

  List<Map<String, String>> _leaveStatusList = [];
  List<Map<String, String>> _leaveCategoryList = [];

  final TextEditingController _dateController = TextEditingController();

  bool _isLoading = true;
  bool _isApplying = false;

  final List<String> _yearOptions = List.generate(
    10,
    (i) => (2021 + i).toString(),
  );

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _loadInitialData();
  }

  void _initializeValues() {
    _tmpStatus = widget.initialStatus;
    _tmpCategory = widget.initialCategory;
    _tmpDate = widget.initialDate;
    _tmpYear = widget.initialYear ?? DateTime.now().year.toString();

    if (_tmpDate != null) {
      _dateController.text = _tmpDate!.format();
    }
  }

  void _loadInitialData() async {
    try {
      setState(() => _isLoading = true);

      // Load both dropdowns in parallel
      await Future.wait([_fetchLeaveStatuses(), _fetchLeaveCategories()]);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLeaveStatuses() async {
    try {
      final response = await OrgManagementService.instance
          .fetchLeaveDropdownStatus();
      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data;
        final items = dataList
            .map((json) => FilterItem.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          _leaveStatusList = items
              .map((item) => {"id": item.id, "name": item.name})
              .toList();
        });
      } else {
        setState(() => _leaveStatusList = []);
      }
    } catch (e) {
      setState(() => _leaveStatusList = []);
    }
  }

  Future<void> _fetchLeaveCategories() async {
    try {
      final response = await OrgManagementService.instance
          .fetchLeaveDropdownCategory();
      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data;
        final items = dataList
            .map((json) => FilterItem.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          _leaveCategoryList = items
              .map((item) => {"id": item.id, "name": item.name})
              .toList();
        });
      } else {
        setState(() => _leaveCategoryList = []);
      }
    } catch (e) {
      setState(() => _leaveCategoryList = []);
    }
  }

  Future<void> _applyFilters() async {
    setState(() => _isApplying = true);

    widget.onApplyFilter(_tmpStatus, _tmpCategory, _tmpDate, _tmpYear);

    if (widget.onFetch != null) {
      await widget.onFetch!();
    }

    setState(() => _isApplying = false);
    Navigator.of(context).pop();
  }

  Future<void> _clearFilters() async {
    setState(() {
      _tmpStatus = null;
      _tmpCategory = null;
      _tmpDate = null;
      _tmpYear = DateTime.now().year.toString();
      _dateController.clear();
    });

    widget.onApplyFilter(null, null, null, DateTime.now().year.toString());

    if (widget.onFetch != null) {
      await widget.onFetch!();
    }

  }

  @override
  void dispose() {
    _dateController.dispose();
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
            // Leave Status
            CustomTypeAheadField(
              items: _leaveStatusList,
              selectedId: _tmpStatus,
              label: "Leave Status",
              enabled: !_isLoading,
              isLoading: _isLoading,
              onChanged: (value) => setState(() => _tmpStatus = value),
            ),
            const SizedBox(height: 14),

            // Leave Type
            CustomTypeAheadField(
              items: _leaveCategoryList,
              selectedId: _tmpCategory,
              label: "Leave Type",
              enabled: !_isLoading,
              isLoading: _isLoading,
              onChanged: (value) => setState(() => _tmpCategory = value),
            ),
            const SizedBox(height: 14),

            DateInputField(
              labelText: 'Applied Date',
              initialDate: _tmpDate,
              onDateSelected: (date) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _tmpDate = date;
                      _dateController.text = date.format();
                    });
                  }
                });
              },
              onDateError: (value) {},
            ),
            const SizedBox(height: 14),

            // Year
            DropdownButtonFormField<String>(
              value: _tmpYear,
              decoration: const InputDecoration(
                labelText: 'Year',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: _yearOptions
                  .map(
                    (year) => DropdownMenuItem(value: year, child: Text(year)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _tmpYear = value),
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

class FilterItem {
  final String id;
  final String name;

  FilterItem({required this.id, required this.name});

  factory FilterItem.fromJson(Map<String, dynamic> json) {
    return FilterItem(
      id: json['id'] as String? ?? '',
      name: json['dropdownValue'] as String? ?? '',
    );
  }
}
