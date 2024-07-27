// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:excel/excel.dart';
// import 'package:external_path/external_path.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:io';
// import '../models/account_transaction.dart';
// import '../models/student.dart';
// import 'package:week7_institute_project_2/custom_date_range_picker.dart';

// class StudentFeeCollectionReport extends StatefulWidget {
//   const StudentFeeCollectionReport({super.key});

//   @override
//   _StudentFeeCollectionReportState createState() =>
//       _StudentFeeCollectionReportState();
// }

// class _StudentFeeCollectionReportState
//     extends State<StudentFeeCollectionReport> {
//   DateTimeRange? _selectedDateRange;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         title: const Text('Fee Collection Report'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.file_download),
//             onPressed: _exportToExcel,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildDateFilter(),
//           Expanded(
//             child: FutureBuilder(
//               future: _prepareData(),
//               builder: (context,
//                   AsyncSnapshot<Map<String, Map<String, double>>> snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (snapshot.hasError) {
//                   return const Center(child: Text('Error loading data'));
//                 } else {
//                   return _buildDataTable(snapshot.data!);
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDateFilter() {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           ElevatedButton(
//             onPressed: () async {
//               DateTimeRange? picked = await showDialog<DateTimeRange>(
//                 context: context,
//                 builder: (BuildContext context) {
//                   return CustomDateRangePicker(
//                     initialDateRange: _selectedDateRange,
//                   );
//                 },
//               );

//               if (picked != null) {
//                 setState(() {
//                   _selectedDateRange = picked;
//                 });
//               }
//             },
//             child: const Text('Select Date Range'),
//           ),
//           if (_selectedDateRange != null)
//             Column(
//               children: [
//                 Text(
//                   '${DateFormat('dd/MMM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MMM/yyyy').format(_selectedDateRange!.end)}',
//                   style: const TextStyle(fontSize: 16),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () {
//                     setState(() {
//                       _selectedDateRange = null;
//                     });
//                   },
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   Future<Map<String, Map<String, double>>> _prepareData() async {
//     QuerySnapshot transactionSnapshot = await FirebaseFirestore.instance
//         .collection('transactions')
//         .where('category', isEqualTo: 'Incomes')
//         .where('mainCategory', isEqualTo: 'Student Fee')
//         .get();

//     QuerySnapshot studentSnapshot =
//         await FirebaseFirestore.instance.collection('students').get();

//     Map<String, Map<String, double>> data = {};

//     for (var studentDoc in studentSnapshot.docs) {
//       var student = Student.fromFirestore(studentDoc);
//       for (var transactionDoc in transactionSnapshot.docs) {
//         var transaction = AccountTransaction.fromFirestore(transactionDoc);
//         if (transaction.studentId != student.admNumber) {
//           continue;
//         }
//         if (_selectedDateRange != null &&
//             (transaction.entryDate.isBefore(_selectedDateRange!.start
//                     .subtract(const Duration(days: 1))) ||
//                 transaction.entryDate.isAfter(
//                     _selectedDateRange!.end.add(const Duration(days: 1))))) {
//           continue;
//         }
//         String month = DateFormat('MMM yyyy').format(transaction.entryDate);
//         if (!data.containsKey(student.name)) {
//           data[student.name] = {};
//         }
//         if (!data[student.name]!.containsKey(month)) {
//           data[student.name]![month] = 0;
//         }
//         data[student.name]![month] =
//             data[student.name]![month]! + transaction.amount;
//       }
//     }

//     return data;
//   }

//   Widget _buildDataTable(Map<String, Map<String, double>> data) {
//     List<String> months = data.values
//         .expand((monthlyData) => monthlyData.keys)
//         .toSet()
//         .toList()
//       ..sort((a, b) => DateFormat('MMM yyyy')
//           .parse(a)
//           .compareTo(DateFormat('MMM yyyy').parse(b)));

//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: DataTable(
//         columns: [
//           const DataColumn(label: Text('Student Name')),
//           ...months.map((month) => DataColumn(label: Text(month))),
//         ],
//         rows: data.keys.map((studentName) {
//           return DataRow(
//             cells: [
//               DataCell(Text(studentName)),
//               ...months.map((month) {
//                 double? amount = data[studentName]?[month];
//                 return DataCell(
//                     Text(amount != null ? amount.toInt().toString() : ''));
//               }),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Future<void> _exportToExcel() async {
//     final data = await _prepareData();

//     var excel = Excel.createExcel();
//     Sheet sheetObject = excel['Fee Collection'];

//     List<String> months = data.values
//         .expand((monthlyData) => monthlyData.keys)
//         .toSet()
//         .toList()
//       ..sort((a, b) => DateFormat('MMM yyyy')
//           .parse(a)
//           .compareTo(DateFormat('MMM yyyy').parse(b)));

//     List<Data> header =
//         ['Student Name', ...months].map((e) => Data(value: e)).toList();
//     sheetObject.appendRow(header);

//     data.forEach((studentName, monthlyData) {
//       List<Data> row = [
//         Data(value: studentName),
//         ...months.map((month) {
//           double? amount = monthlyData[month];
//           return Data(value: amount != null ? amount.toInt().toString() : '');
//         })
//       ];
//       sheetObject.appendRow(row);
//     });

//     if (Platform.isAndroid) {
//       final String directory =
//           await ExternalPath.getExternalStoragePublicDirectory(
//               ExternalPath.DIRECTORY_DOWNLOADS);
//       final String filePath = '$directory/Fee_Collection_Report.xlsx';
//       final File file = File(filePath);
//       await file.writeAsBytes(excel.encode()!);

//       if (!mounted) return;
//       ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
//         SnackBar(content: Text('Report saved to $filePath')),
//       );
//     } else if (Platform.isWindows) {
//       String? outputFile = await FilePicker.platform.saveFile(
//         dialogTitle: 'Save Excel File',
//         fileName: 'Fee_Collection_Report.xlsx',
//         type: FileType.custom,
//         allowedExtensions: ['xlsx'],
//       );

//       if (outputFile != null) {
//         final File file = File(outputFile);
//         await file.writeAsBytes(excel.encode()!);

//         if (!mounted) return;
//         ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
//           SnackBar(content: Text('Report saved to $outputFile')),
//         );
//       } else {
//         if (!mounted) return;
//         ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
//           const SnackBar(content: Text('Save cancelled')),
//         );
//       }
//     }
//   }
// }
