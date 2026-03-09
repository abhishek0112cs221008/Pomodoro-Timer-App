import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pomodoro.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            mode TEXT
          )
        ''');
      },
    );
  }

  // Settings helpers
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  // Session helpers
  Future<void> addSession(String date, String mode) async {
    final db = await database;
    await db.insert('sessions', {'date': date, 'mode': mode});
  }

  Future<List<String>> getCompletedDates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      columns: ['date'],
      where: "mode = 'focus'",
      distinct: true,
    );
    return List.generate(maps.length, (i) => maps[i]['date'] as String);
  }

  Future<int> getTotalSessions() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM sessions WHERE mode = ?',
      ['focus'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
