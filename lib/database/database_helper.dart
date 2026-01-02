import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/time_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('worktimer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add short_name column to existing tasks table
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN short_name TEXT
      ''');
      
      // Update existing tasks to generate short names
      final tasks = await db.query('tasks');
      for (var task in tasks) {
        final name = task['name'] as String;
        final shortName = name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
        await db.update(
          'tasks',
          {'short_name': shortName},
          where: 'id = ?',
          whereArgs: [task['id']],
        );
      }
    }
    
    if (oldVersion < 3) {
      // Add description column to time_entries table
      await db.execute('''
        ALTER TABLE time_entries ADD COLUMN description TEXT
      ''');
    }
    
    if (oldVersion < 4) {
      // Add order_index column to tasks table
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN order_index INTEGER NOT NULL DEFAULT 0
      ''');
      
      // Set order_index based on current order (by name)
      final tasks = await db.query('tasks', orderBy: 'name ASC');
      for (int i = 0; i < tasks.length; i++) {
        await db.update(
          'tasks',
          {'order_index': i},
          where: 'id = ?',
          whereArgs: [tasks[i]['id']],
        );
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        short_name TEXT NOT NULL,
        color TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        order_index INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Time entries table
    await db.execute('''
      CREATE TABLE time_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        date TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_time_entries_date ON time_entries(date)
    ''');

    await db.execute('''
      CREATE INDEX idx_time_entries_task_id ON time_entries(task_id)
    ''');
  }

  // Task CRUD operations
  Future<Task> createTask(Task task) async {
    final db = await database;
    
    // Get the max order_index and add 1 for the new task
    final result = await db.rawQuery('SELECT MAX(order_index) as max_order FROM tasks');
    final maxOrder = result.first['max_order'] as int? ?? -1;
    
    final taskWithOrder = task.copyWith(orderIndex: maxOrder + 1);
    final id = await db.insert('tasks', taskWithOrder.toMap());
    return taskWithOrder.copyWith(id: id);
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'order_index ASC',
    );
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<Task?> getTask(int id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> updateTaskOrder(List<Task> tasks) async {
    final db = await database;
    final batch = db.batch();
    
    for (int i = 0; i < tasks.length; i++) {
      batch.update(
        'tasks',
        {'order_index': i},
        where: 'id = ?',
        whereArgs: [tasks[i].id],
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    // Soft delete - mark as inactive
    return db.update(
      'tasks',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Time Entry operations
  Future<TimeEntry> createTimeEntry(TimeEntry entry) async {
    final db = await database;
    final id = await db.insert('time_entries', entry.toMap());
    return entry.copyWith(id: id);
  }

  Future<int> updateTimeEntry(TimeEntry entry) async {
    final db = await database;
    return db.update(
      'time_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<TimeEntry?> getRunningEntry(int taskId) async {
    final db = await database;
    final maps = await db.query(
      'time_entries',
      where: 'task_id = ? AND end_time IS NULL',
      whereArgs: [taskId],
    );
    if (maps.isNotEmpty) {
      return TimeEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<TimeEntry>> getEntriesForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'time_entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'start_time ASC',
    );
    return result.map((map) => TimeEntry.fromMap(map)).toList();
  }

  Future<List<TimeEntry>> getEntriesForTask(int taskId) async {
    final db = await database;
    final result = await db.query(
      'time_entries',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'date ASC, start_time ASC',
    );
    return result.map((map) => TimeEntry.fromMap(map)).toList();
  }

  Future<List<TimeEntry>> getAllEntries() async {
    final db = await database;
    final result = await db.query(
      'time_entries',
      orderBy: 'date DESC, start_time DESC',
    );
    return result.map((map) => TimeEntry.fromMap(map)).toList();
  }

  // Get total duration for a task on a specific date
  Future<Duration> getTotalDurationForTaskOnDate(int taskId, String date) async {
    final entries = await getEntriesForDate(date);
    final taskEntries = entries.where((e) => e.taskId == taskId);
    
    Duration total = Duration.zero;
    for (var entry in taskEntries) {
      total += entry.getDuration();
    }
    return total;
  }

  // Get all dates that have time entries
  Future<List<String>> getAllDatesWithEntries() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT date 
      FROM time_entries 
      ORDER BY date DESC
    ''');
    return result.map((row) => row['date'] as String).toList();
  }

  // Get summary for a specific date
  Future<Map<int, Duration>> getSummaryForDate(String date) async {
    final entries = await getEntriesForDate(date);
    final Map<int, Duration> summary = {};
    
    for (var entry in entries) {
      if (!summary.containsKey(entry.taskId)) {
        summary[entry.taskId] = Duration.zero;
      }
      summary[entry.taskId] = summary[entry.taskId]! + entry.getDuration();
    }
    
    return summary;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
