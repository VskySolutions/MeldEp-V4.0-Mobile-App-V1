import 'package:flutter/material.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final dynamic value;
  final VoidCallback onClear;
  final EdgeInsetsGeometry margin;

  const FilterChipWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.onClear,
    this.margin = const EdgeInsets.only(right: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Chip(
        label: Text(_getDisplayText()),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onClear,
      ),
    );
  }

  String _getDisplayText() {
    if (value is DateTime) {
      // Format DateTime as needed
      // return '$label: ${_formatDate(value)}';
      return label;
    }
    // return '$label: $value';
    return label;
  }

  String _formatDate(DateTime date) {
    // Customize date formatting as needed
    return "${date.month}/${date.day}/${date.year}";
  }
}