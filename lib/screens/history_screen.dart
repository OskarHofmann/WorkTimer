import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../utils/excel_export.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  Map<int, Duration> _daySummary = {};
  Map<int, Task> _tasksMap = {};
  bool _isLoading = true;
  Set<DateTime> _datesWithData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load all tasks
    final tasks = await _dbHelper.getAllTasks();
    final tasksMap = {for (var task in tasks) task.id!: task};

    // Load dates with entries
    final dates = await _dbHelper.getAllDatesWithEntries();
    final datesSet = dates.map((dateStr) => DateTime.parse(dateStr)).toSet();

    // Load summary for selected date
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final summary = await _dbHelper.getSummaryForDate(dateStr);

    setState(() {
      _tasksMap = tasksMap;
      _datesWithData = datesSet;
      _daySummary = summary;
      _isLoading = false;
    });
  }

  Future<void> _loadSummaryForDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final summary = await _dbHelper.getSummaryForDate(dateStr);
    
    setState(() {
      _selectedDate = date;
      _daySummary = summary;
    });
  }

  Future<void> _showTaskDetails(Task task) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final entries = await _dbHelper.getEntriesForDate(dateStr);
    final taskEntries = entries.where((e) => e.taskId == task.id).toList();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...taskEntries.map((entry) {
                final startTime = DateFormat('HH:mm').format(entry.startTime);
                final endTime = entry.endTime != null 
                    ? DateFormat('HH:mm').format(entry.endTime!) 
                    : 'Running';
                final duration = _formatDuration(entry.getDuration());
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$startTime - $endTime',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            duration,
                            style: TextStyle(
                              color: _getColorFromString(task.color),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (entry.description != null && entry.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text(
                          entry.description!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDurationDetailed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours}h ${minutes}m ${seconds}s';
  }

  Duration _getTotalForDay() {
    return _daySummary.values.fold(
      Duration.zero,
      (sum, duration) => sum + duration,
    );
  }

  Color _getColorFromString(String colorString) {
    switch (colorString) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'pink':
        return Colors.pink;
      case 'amber':
        return Colors.amber;
      case 'indigo':
        return Colors.indigo;
      case 'cyan':
        return Colors.cyan;
      default:
        return Colors.blue;
    }
  }

  Future<void> _exportToExcel() async {
    try {
      await ExcelExport.exportAllData(_dbHelper, _tasksMap);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel file exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: TableCalendar(
                      firstDay: DateTime(2020, 1, 1),
                      lastDay: DateTime(2030, 12, 31),
                      focusedDay: _focusedDate,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDate, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _focusedDate = focusedDay;
                        });
                        _loadSummaryForDate(selectedDay);
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      eventLoader: (day) {
                        // Show marker for dates with data
                        final hasData = _datesWithData.any(
                          (date) => isSameDay(date, day),
                        );
                        return hasData ? [1] : [];
                      },
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ),
                  
                  // Selected date summary
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_daySummary.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No time tracked on this day',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          // Task list
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _daySummary.length,
                            itemBuilder: (context, index) {
                              final taskId = _daySummary.keys.elementAt(index);
                              final duration = _daySummary[taskId]!;
                              final task = _tasksMap[taskId];
                              
                              if (task == null) return const SizedBox.shrink();
                              
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getColorFromString(task.color),
                                    child: Text(
                                      task.shortName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    task.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () => _showTaskDetails(task),
                                ),
                              );
                            },
                          ),
                          
                          const Divider(height: 32),
                          
                          // Total
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatDurationDetailed(_getTotalForDay()),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
