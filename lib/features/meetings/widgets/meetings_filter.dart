// lib/features/time_buddy/widgets/time_buddy_filter.dart
import 'package:flutter/material.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/core/widgets/buttons/custom_outlined_button.dart';

class TimeBuddyFilter extends StatefulWidget {
  final int initialMonth;
  final int initialYear;
  final void Function(int month, int year) onApply;
  final Future<void> Function()? onFetch;

  const TimeBuddyFilter({
    Key? key,
    required this.initialMonth,
    required this.initialYear,
    required this.onApply,
    this.onFetch,
  }) : super(key: key);

  @override
  State<TimeBuddyFilter> createState() => _TimeBuddyFilterState();
}

class _TimeBuddyFilterState extends State<TimeBuddyFilter> {
  late int _tmpMonth;
  late int _tmpYear;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tmpMonth = widget.initialMonth;
    _tmpYear = widget.initialYear;
  }

  Future<void> _apply() async {
    setState(() => _isLoading = true);
    widget.onApply(_tmpMonth, _tmpYear);
    if (widget.onFetch != null) {
      await widget.onFetch!();
    }
    setState(() => _isLoading = false);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _clear() async {
    setState(() {
      _tmpMonth = DateTime.now().month;
      _tmpYear = DateTime.now().year;
    });
    widget.onApply(_tmpMonth, _tmpYear);
    if (widget.onFetch != null) {
      await widget.onFetch!();
    }
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
              DropdownButtonFormField<int>(
                value: _tmpMonth,
                decoration: const InputDecoration(
                  labelText: 'Month',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (i) {
                  final m = i + 1;
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m.toString().padLeft(2, '0')),
                  );
                }),
                onChanged: (v) => setState(() => _tmpMonth = v ?? _tmpMonth),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _tmpYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: List.generate(10, (i) {
                  final y = DateTime.now().year - 5 + i;
                  return DropdownMenuItem(value: y, child: Text(y.toString()));
                }),
                onChanged: (v) => setState(() => _tmpYear = v ?? _tmpYear),
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
            // const SizedBox(width: 8),
            // CustomOutlinedButton(
            //   onPressed: _clear,
            //   text: 'Clear',
            //   color: Colors.black,
            // ),
            const SizedBox(width: 8),
            CustomOutlinedButton(
              onPressed: _apply,
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
