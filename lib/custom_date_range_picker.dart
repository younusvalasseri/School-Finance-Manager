import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const CustomDateRangePicker({super.key, this.initialDateRange});

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  final DateFormat _dateFormat = DateFormat('dd/MMM/yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange?.start ?? DateTime.now();
    _endDate = widget.initialDateRange?.end ??
        DateTime.now().add(const Duration(days: 7));
    _startDateController =
        TextEditingController(text: _dateFormat.format(_startDate));
    _endDateController =
        TextEditingController(text: _dateFormat.format(_endDate));
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate.isBefore(DateTime(2000)) ? DateTime.now() : _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _startDateController.text = _dateFormat.format(_startDate);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _endDate.isBefore(DateTime(2000)) ? DateTime.now() : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _endDateController.text = _dateFormat.format(_endDate);
      });
    }
  }

  void _showInvalidDateFormatMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wrong input type'),
      ),
    );
  }

  void _validateAndSubmit() {
    try {
      _startDate = _dateFormat.parse(_startDateController.text);
      _endDate = _dateFormat.parse(_endDateController.text);

      if (_endDate.isBefore(_startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date must be after start date')),
        );
      } else {
        Navigator.of(context)
            .pop(DateTimeRange(start: _startDate, end: _endDate));
      }
    } catch (e) {
      _showInvalidDateFormatMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Date Range',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  try {
                    _dateFormat.parse(_startDateController.text);
                  } catch (e) {
                    _showInvalidDateFormatMessage();
                  }
                }
              },
              child: TextField(
                controller: _startDateController,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  hintText: 'dd/MMM/yyyy (e.g., 15/Jun/2023)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectStartDate(context),
                  ),
                ),
                inputFormatters: [DateTextInputFormatter()],
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(height: 8),
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  try {
                    _dateFormat.parse(_endDateController.text);
                  } catch (e) {
                    _showInvalidDateFormatMessage();
                  }
                }
              },
              child: TextField(
                controller: _endDateController,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  hintText: 'dd/MMM/yyyy (e.g., 22/Jun/2023)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectEndDate(context),
                  ),
                ),
                inputFormatters: [DateTextInputFormatter()],
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _validateAndSubmit,
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DateTextInputFormatter extends TextInputFormatter {
  final RegExp _regExp = RegExp(r'^\d{0,2}(/)?(\w{0,3})?(/)?(\d{0,4})?$');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (_regExp.hasMatch(newValue.text)) {
      String newText = newValue.text;

      if (newValue.text.length == 2 && oldValue.text.length == 1) {
        newText += '/';
      } else if (newValue.text.length == 6 && oldValue.text.length == 5) {
        newText += '/';
      }

      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    return oldValue;
  }
}
