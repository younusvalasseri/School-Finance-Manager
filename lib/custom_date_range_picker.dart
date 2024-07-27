import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const CustomDateRangePicker({super.key, this.initialDateRange});

  @override
  // ignore: library_private_types_in_public_api
  _CustomDateRangePickerState createState() => _CustomDateRangePickerState();
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

  void _updateStartDate(String value) {
    try {
      _startDate = _dateFormat.parse(value);
      setState(() {});
    } catch (e) {
      // Handle invalid date format
    }
  }

  void _updateEndDate(String value) {
    try {
      _endDate = _dateFormat.parse(value);
      setState(() {});
    } catch (e) {
      // Handle invalid date format
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
            TextField(
              controller: _startDateController,
              decoration: const InputDecoration(
                labelText: 'Start Date',
                hintText: 'dd/MMM/yyyy (e.g., 15/Jun/2023)',
              ),
              inputFormatters: [DateTextInputFormatter()],
              keyboardType: TextInputType.text,
              onChanged: _updateStartDate,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endDateController,
              decoration: const InputDecoration(
                labelText: 'End Date',
                hintText: 'dd/MMM/yyyy (e.g., 22/Jun/2023)',
              ),
              inputFormatters: [DateTextInputFormatter()],
              keyboardType: TextInputType.datetime,
              onChanged: _updateEndDate,
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
                  onPressed: () {
                    if (_endDate.isBefore(_startDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('End date must be after start date')),
                      );
                    } else {
                      Navigator.of(context)
                          .pop(DateTimeRange(start: _startDate, end: _endDate));
                    }
                  },
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
