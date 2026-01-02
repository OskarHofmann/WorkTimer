import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/time_entry.dart';
import '../database/database_helper.dart';

class TimerScreen extends StatefulWidget {
  final Task task;

  const TimerScreen({super.key, required this.task});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _descriptionController = TextEditingController();
  TimeEntry? _currentEntry;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  Duration _todayTotal = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeTimer() async {
    // Check if there's already a running entry for this task
    final runningEntry = await _dbHelper.getRunningEntry(widget.task.id!);
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayDuration = await _dbHelper.getTotalDurationForTaskOnDate(
      widget.task.id!,
      today,
    );

    if (runningEntry != null) {
      // Continue existing timer
      _descriptionController.text = runningEntry.description ?? '';
      setState(() {
        _currentEntry = runningEntry;
        _elapsedTime = runningEntry.getDuration();
        _todayTotal = todayDuration;
        _isLoading = false;
      });
    } else {
      // Start new timer
      final now = DateTime.now();
      final newEntry = TimeEntry(
        taskId: widget.task.id!,
        startTime: now,
        date: today,
      );
      
      final savedEntry = await _dbHelper.createTimeEntry(newEntry);
      
      setState(() {
        _currentEntry = savedEntry;
        _elapsedTime = Duration.zero;
        _todayTotal = todayDuration;
        _isLoading = false;
      });
    }

    // Start UI update timer
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentEntry != null) {
        setState(() {
          _elapsedTime = _currentEntry!.getDuration();
        });
      }
    });
  }

  Future<void> _stopTimer() async {
    if (_currentEntry == null) return;

    _timer?.cancel();

    // Update entry with end time and description
    final updatedEntry = _currentEntry!.copyWith(
      endTime: DateTime.now(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
    );

    await _dbHelper.updateTimeEntry(updatedEntry);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.task.name),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final taskColor = _getColorFromString(widget.task.color);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _stopTimer();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.task.name),
          backgroundColor: taskColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _stopTimer,
          ),
        ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              taskColor.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Task name
                Text(
                  widget.task.name,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: taskColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Current session time
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Current Session',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_elapsedTime),
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: taskColor,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Additional info
                if (_currentEntry != null) ...[
                  Text(
                    'Started: ${_formatTime(_currentEntry!.startTime)}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Today Total: ${_formatDuration(_todayTotal + _elapsedTime)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Description input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Add description (optional)...',
                      border: InputBorder.none,
                      icon: Icon(Icons.description, color: taskColor),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stop button
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton.icon(
                    onPressed: _stopTimer,
                    icon: const Icon(Icons.stop, size: 32),
                    label: const Text(
                      'STOP',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ), // Scaffold
    ); // PopScope
  }
}