import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../utils/excel_export.dart';
import 'timer_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _dbHelper.getAllTasks();
    
    // If no tasks exist, create some default ones
    if (tasks.isEmpty) {
      await _createDefaultTasks();
      final newTasks = await _dbHelper.getAllTasks();
      setState(() {
        _tasks = newTasks;
        _isLoading = false;
      });
    } else {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultTasks() async {
    final defaultTasks = [
      Task(name: 'Project A', color: 'blue'),
      Task(name: 'Project B', color: 'green'),
      Task(name: 'Project C', color: 'orange'),
    ];
    
    for (var task in defaultTasks) {
      await _dbHelper.createTask(task);
    }
  }

  void _navigateToTimer(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerScreen(task: task),
      ),
    );
    
    // Reload tasks when returning from timer screen
    if (result == true) {
      _loadTasks();
    }
  }

  void _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
    _loadTasks();
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      // Get all tasks as a map
      final tasksMap = {for (var task in _tasks) task.id!: task};
      
      await ExcelExport.exportAllData(_dbHelper, tasksMap);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel file exported successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkTimer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No tasks yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _navigateToSettings,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Task'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        elevation: 4,
                        child: InkWell(
                          onTap: () => _navigateToTimer(task),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  _getColorFromString(task.color),
                                  _getColorFromString(task.color).withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  task.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _navigateToHistory,
                icon: const Icon(Icons.calendar_today),
                label: const Text('History'),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: _exportToExcel,
                icon: const Icon(Icons.file_upload),
                label: const Text('Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
