import 'package:flutter/material.dart';
import 'package:test_project/core/utils/extensions.dart';
import '../../constants/formats.dart';
import '../../utils/validators.dart';

class DateInputFieldValue {
  final String value;
  final String? error;
  final bool hasError;

  DateInputFieldValue(this.value, this.error) : hasError = error != null;
}

class DateInputField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final String? datePickerFormat;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<String?> onDateError;
  final FormFieldValidator<String> validator;
  final InputBorder border;
  final bool isDense;
  final bool readOnly;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;

  static final DateTime _defaultFirstDate = DateTime(2000);
  static final DateTime _defaultLastDate = DateTime(2100);

  DateInputField({
    Key? key,
    required this.labelText,
    this.hintText = ConstFormats.DATE_MMDDYYYY,
    this.initialDate,
    this.datePickerFormat,
    DateTime? firstDate,
    DateTime? lastDate,
    required this.onDateSelected,
    required this.onDateError,
    this.validator = Validators.validateDateFormat,
    this.border = const OutlineInputBorder(),
    this.isDense = true,
    this.readOnly = false,
    this.labelStyle,
    this.hintStyle,
    this.errorStyle,
  })  : firstDate = firstDate ?? _defaultFirstDate,
        lastDate = lastDate ?? _defaultLastDate,
        super(key: key);

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late TextEditingController _dateController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: widget.initialDate?.format() ?? '',
    );

    // Schedule the initial validation after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateController.text.isNotEmpty) {
        _validateAndNotify(_dateController.text);
      }
    });
  }

  @override
  void didUpdateWidget(DateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _dateController.text = widget.initialDate?.format() ?? '';

      // Schedule the validation after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateAndNotify(_dateController.text);
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _validateAndNotify(String text) {
    final error = widget.validator(text);

    setState(() {
      _errorText = error;
    });

    // Notify about error state
    widget.onDateError(error);

    if (error == null && text.isNotEmpty) {
      try {
        final parsedDate = ConstFormats.DATE_FORMAT.parseStrict(text);
        widget.onDateSelected(parsedDate);
      } catch (e) {
        // This should not happen if validator is correct
        final parseError = 'Invalid date format';
        setState(() {
          _errorText = parseError;
        });
        widget.onDateError(parseError);
      }
    }
  }

  void _onDateChanged(String text) {
    _validateAndNotify(text);
  }

  Future<void> _pickDate() async {
    final initial = widget.initialDate ?? DateTime.now();
    final initialDate =
        initial.isBefore(widget.firstDate) || initial.isAfter(widget.lastDate)
            ? widget.firstDate
            : initial;

    DateTime? picked;

    if (widget.datePickerFormat == "week") {
      picked = await showDatePicker(
          context: context,
          initialDate: widget.initialDate != null ? initialDate : null,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          selectableDayPredicate: (date) {
            return date.weekday == DateTime.sunday;
          });
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
      );
    }

    if (picked != null) {
      final formattedDate = picked.format();
      _dateController.text = formattedDate;
      _validateAndNotify(formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _dateController,
      readOnly: false, // Always allow manual editing
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: _errorText,
        border: widget.border,
        isDense: widget.isDense,
        labelStyle: widget.labelStyle,
        hintStyle: widget.hintStyle,
        errorStyle: widget.errorStyle,
        suffixIcon: widget.readOnly
            ? IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: null, // Disable calendar button if readOnly is true
              )
            : IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: _pickDate,
              ),
      ),
      onChanged: _onDateChanged,
    );
  }
}
