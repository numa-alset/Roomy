import 'package:sqflite/sqflite.dart';
import '../../../../core/storage/local_db.dart';
import '../models/message_model.dart';

class ChatLocalDs {
  Future<void> upsert(MessageModel m) async {
    final db = await LocalDb.instance;
    await db.insert('messages', m.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MessageModel>> listAll() async {
    final db = await LocalDb.instance;
    final rows = await db.query('messages', orderBy: 'datetime(createdAt) ASC');
    return rows.map(MessageModel.fromRow).toList();
  }
}
