import 'package:flutter/material.dart';

class ArrowDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final TextStyle? textStyle;
  final Color? activeIconColor;
  final Color disabledIconColor;
  final bool enabled;

  const ArrowDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.firstDate,
    required this.lastDate,
    this.textStyle,
    this.activeIconColor = Colors.black,
    this.disabledIconColor = Colors.grey,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle = textStyle ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );
    final effectiveActiveIconColor = activeIconColor ?? theme.iconTheme.color ?? Colors.black;

    final canGoBack = enabled && selectedDate.isAfter(firstDate);
    final canGoForward = enabled && selectedDate.isBefore(lastDate.subtract(Duration(days: 1)));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left Arrow (Previous Day)
        IconButton(
          onPressed: canGoBack
              ? () {
                  final newDate = selectedDate.subtract(const Duration(days: 1));
                  onDateChanged(newDate);
                }
              : null,
          icon: Icon(
            Icons.chevron_left,
            color: canGoBack ? effectiveActiveIconColor : disabledIconColor,
          ),
        ),

        // Date Display
        GestureDetector(
          onTap: enabled
              ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                  if (picked != null) {
                    onDateChanged(picked);
                  }
                }
              : null,
          child: Text(
            _formatDate(selectedDate),
            style: effectiveTextStyle.copyWith(
              color: enabled ? effectiveTextStyle.color : effectiveTextStyle.color?.withOpacity(0.5),
            ),
          ),
        ),

        // Right Arrow (Next Day)
        IconButton(
          onPressed: canGoForward
              ? () {
                  final newDate = selectedDate.add(const Duration(days: 1));
                  onDateChanged(newDate);
                }
              : null,
          icon: Icon(
            Icons.chevron_right,
            color: canGoForward ? effectiveActiveIconColor : disabledIconColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
  }
}