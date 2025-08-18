import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static Database? _db;
  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'app.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE messages(
          id TEXT PRIMARY KEY,
          fromId TEXT NOT NULL,
          toId TEXT NOT NULL,
          text TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    });
    return _db!;
  }
}
