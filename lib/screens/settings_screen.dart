import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _reorderTasks(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final task = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, task);
    });
    
    // Update order in database
    await _dbHelper.updateTaskOrder(_tasks);
  }

  void _showAddTaskDialog() {
    final nameController = TextEditingController();
    final shortNameController = TextEditingController();
    String selectedColor = 'blue';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Task Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    // Auto-generate short name from first 3 characters
                    if (value.isNotEmpty && shortNameController.text.isEmpty) {
                      setDialogState(() {
                        shortNameController.text = value.length >= 3 
                            ? value.substring(0, 3).toUpperCase() 
                            : value.toUpperCase();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: shortNameController,
                  decoration: const InputDecoration(
                    labelText: 'Short Name (3 chars)',
                    border: OutlineInputBorder(),
                    helperText: 'Shown in history view',
                  ),
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                const Text('Choose Color:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    'blue', 'green', 'orange', 'red', 'purple',
                    'teal', 'pink', 'amber', 'indigo', 'cyan',
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getColorFromString(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  final newTask = Task(
                    name: nameController.text.trim(),
                    shortName: shortNameController.text.trim().isNotEmpty 
                        ? shortNameController.text.trim().toUpperCase()
                        : null,
                    color: selectedColor,
                  );
                  await _dbHelper.createTask(newTask);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTasks();
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    final nameController = TextEditingController(text: task.name);
    final shortNameController = TextEditingController(text: task.shortName);
    String selectedColor = task.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Task Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: shortNameController,
                  decoration: const InputDecoration(
                    labelText: 'Short Name (3 chars)',
                    border: OutlineInputBorder(),
                    helperText: 'Shown in history view',
                  ),
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                const Text('Choose Color:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    'blue', 'green', 'orange', 'red', 'purple',
                    'teal', 'pink', 'amber', 'indigo', 'cyan',
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getColorFromString(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                          color: selectedColor == color
                              ? Colors.black
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  final updatedTask = task.copyWith(
                    name: nameController.text.trim(),
                    shortName: shortNameController.text.trim().isNotEmpty 
                        ? shortNameController.text.trim().toUpperCase()
                        : (nameController.text.trim().length >= 3 
                            ? nameController.text.trim().substring(0, 3).toUpperCase()
                            : nameController.text.trim().toUpperCase()),
                    color: selectedColor,
                  );
                  await _dbHelper.updateTask(updatedTask);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadTasks();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${task.name}"?\n\nThe task will be hidden but historical data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbHelper.deleteTask(task.id!);
              if (mounted) {
                Navigator.pop(context);
                _loadTasks();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tasks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_alt, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No tasks yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddTaskDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Task'),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _tasks.length,
                  onReorder: _reorderTasks,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Card(
                      key: ValueKey(task.id),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.drag_handle, color: Colors.grey),
                            const SizedBox(width: 8),
                            CircleAvatar(
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
                          ],
                        ),
                        title: Text(
                          task.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Color: ${task.color}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditTaskDialog(task),
                              color: Colors.blue,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _showDeleteConfirmation(task),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}
