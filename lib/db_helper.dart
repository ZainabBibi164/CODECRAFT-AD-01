import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;
  static const String tableName = 'calculations';
  static const String columnId = 'id';
  static const String columnExpression = 'expression';
  static const String columnResult = 'result';
  static const String columnTimestamp = 'timestamp';

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'calculator.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnExpression TEXT NOT NULL,
            $columnResult TEXT NOT NULL,
            $columnTimestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Insert calculation
  Future<void> insertCalculation(String expression, String result) async {
    final db = await database;
    await db.insert(
      tableName,
      {
        columnExpression: expression,
        columnResult: result,
        columnTimestamp: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all calculations
  Future<List<Map<String, dynamic>>> getCalculations() async {
    final db = await database;
    return await db.query(tableName, orderBy: '$columnTimestamp DESC');
  }

  // Clear history
  Future<void> clearHistory() async {
    final db = await database;
    await db.delete(tableName);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}