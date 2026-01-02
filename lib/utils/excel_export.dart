import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/task.dart';

class ExcelExport {
  static Future<void> exportAllData(
    DatabaseHelper dbHelper,
    Map<int, Task> tasksMap,
  ) async {
    // Create Excel workbook
    var excel = Excel.createExcel();

    // Get all tasks
    final tasks = tasksMap.values.toList();

    // Create a sheet for each task
    for (var task in tasks) {
      final entries = await dbHelper.getEntriesForTask(task.id!);
      
      // Only create sheet if there's data
      if (entries.isEmpty) continue;

      // Create sheet for this task (sanitize name for Excel compatibility)
      final sheetName = _sanitizeSheetName(task.name);
      var sheet = excel[sheetName];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Date');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Start Time');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('End Time');
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Hours');
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Description');
      
      // Style headers
      _styleCell(sheet.cell(CellIndex.indexByString('A1')));
      _styleCell(sheet.cell(CellIndex.indexByString('B1')));
      _styleCell(sheet.cell(CellIndex.indexByString('C1')));
      _styleCell(sheet.cell(CellIndex.indexByString('D1')));
      _styleCell(sheet.cell(CellIndex.indexByString('E1')));

      // Add data rows
      int rowIndex = 2;
      
      for (var entry in entries) {
        // Use date object for Excel date formatting
        final dateObj = DateTime.parse(entry.date);
        final hours = entry.getDuration().inMinutes / 60;
        
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value = 
            DateCellValue(year: dateObj.year, month: dateObj.month, day: dateObj.day);
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value = 
            TextCellValue(DateFormat('HH:mm').format(entry.startTime));
        sheet.cell(CellIndex.indexByString('C$rowIndex')).value = 
            TextCellValue(entry.endTime != null ? DateFormat('HH:mm').format(entry.endTime!) : '-');
        sheet.cell(CellIndex.indexByString('D$rowIndex')).value = 
            DoubleCellValue(double.parse(hours.toStringAsFixed(2)));
        sheet.cell(CellIndex.indexByString('E$rowIndex')).value = 
            TextCellValue(entry.description ?? '');
        
        rowIndex++;
      }

      // Add total row
      sheet.cell(CellIndex.indexByString('A$rowIndex')).value = 
          TextCellValue('Total');
      final totalDuration = entries.fold<Duration>(
        Duration.zero,
        (sum, entry) => sum + entry.getDuration(),
      );
      final totalHours = totalDuration.inMinutes / 60;
      sheet.cell(CellIndex.indexByString('D$rowIndex')).value = 
          DoubleCellValue(double.parse(totalHours.toStringAsFixed(2)));
      
      _styleCell(sheet.cell(CellIndex.indexByString('A$rowIndex')));
      _styleCell(sheet.cell(CellIndex.indexByString('D$rowIndex')));

      // Auto-size columns
      sheet.setColumnWidth(0, 20.0); // Date
      sheet.setColumnWidth(1, 12.0); // Start Time
      sheet.setColumnWidth(2, 12.0); // End Time
      sheet.setColumnWidth(3, 12.0); // Hours
      sheet.setColumnWidth(4, 40.0); // Description
    }

    // Create summary sheet
    await _createSummarySheet(excel, dbHelper, tasksMap);

    // Remove default Sheet1 if it still exists
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Save and share file
    await _saveAndShareExcel(excel);
  }

  static Future<void> _createSummarySheet(
    Excel excel,
    DatabaseHelper dbHelper,
    Map<int, Task> tasksMap,
  ) async {
    var sheet = excel['Summary'];

    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Task');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Total Hours');
    
    _styleCell(sheet.cell(CellIndex.indexByString('A1')));
    _styleCell(sheet.cell(CellIndex.indexByString('B1')));

    int rowIndex = 2;
    Duration grandTotal = Duration.zero;

    for (var task in tasksMap.values) {
      final entries = await dbHelper.getEntriesForTask(task.id!);
      final totalDuration = entries.fold<Duration>(
        Duration.zero,
        (sum, entry) => sum + entry.getDuration(),
      );

      if (totalDuration > Duration.zero) {
        final hours = totalDuration.inMinutes / 60;
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value = 
            TextCellValue(task.name);
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value = 
            DoubleCellValue(double.parse(hours.toStringAsFixed(2)));
        
        grandTotal += totalDuration;
        rowIndex++;
      }
    }

    // Grand total
    if (rowIndex > 2) {
      sheet.cell(CellIndex.indexByString('A$rowIndex')).value = 
          TextCellValue('Grand Total');
      final totalHours = grandTotal.inMinutes / 60;
      sheet.cell(CellIndex.indexByString('B$rowIndex')).value = 
          DoubleCellValue(double.parse(totalHours.toStringAsFixed(2)));
      
      _styleCell(sheet.cell(CellIndex.indexByString('A$rowIndex')));
      _styleCell(sheet.cell(CellIndex.indexByString('B$rowIndex')));
    }

    sheet.setColumnWidth(0, 25.0);
    sheet.setColumnWidth(1, 15.0);
  }

  static void _styleCell(Data cell) {
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
    );
  }

  static String _sanitizeSheetName(String name) {
    // Excel sheet names can't contain: \ / ? * [ ]
    // and must be <= 31 characters
    String sanitized = name
        .replaceAll(RegExp(r'[\\/?*\[\]]'), '_')
        .trim();
    
    if (sanitized.length > 31) {
      sanitized = sanitized.substring(0, 31);
    }
    
    return sanitized.isEmpty ? 'Task' : sanitized;
  }

  static Future<void> _saveAndShareExcel(Excel excel) async {
    // Get temporary directory
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/WorkTimer_Export_$timestamp.xlsx';

    // Save file
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'WorkTimer Export',
        text: 'Time tracking data exported from WorkTimer',
      );
    }
  }
}
