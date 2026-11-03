import 'package:sqflite_sqlcipher/sqflite.dart';

import '../local/app_database.dart';
import '../models/entities.dart';

/// Chat mentah untuk UI. Bukan sumber kebenaran identitas — episode & memory
/// chunk yang menyimpan makna jangka panjang. Pesan tua boleh dipangkas.
class MessageRepository {
  MessageRepository(this._db);

  final AppDatabase _db;
  Database get _c => _db.db;

  Future<void> add(Message m) => _c.insert('messages', m.toMap());

  /// N pesan terakhir sesi, urut kronologis (lama -> baru).
  Future<List<Message>> lastInSession(String sessionId, {int limit = 12}) async {
    final rows = await _c.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sent_at DESC',
      limit: limit,
    );
    return rows.reversed.map(Message.fromMap).toList();
  }

  /// Semua pesan sesi (untuk render layar chat), kronologis.
  Future<List<Message>> allInSession(String sessionId) async {
    final rows = await _c.query('messages',
        where: 'session_id = ?', whereArgs: [sessionId], orderBy: 'sent_at ASC');
    return rows.map(Message.fromMap).toList();
  }

  /// Pesan sejak [since] (dipakai reflection loop untuk ringkas hari ini).
  Future<List<Message>> since(DateTime since) async {
    final rows = await _c.query('messages',
        where: 'sent_at >= ?',
        whereArgs: [since.millisecondsSinceEpoch],
        orderBy: 'sent_at ASC');
    return rows.map(Message.fromMap).toList();
  }

  /// Pangkas pesan lebih tua dari [cutoff] (episode sudah merangkumnya).
  Future<int> pruneOlderThan(DateTime cutoff) => _c.delete('messages',
      where: 'sent_at < ?', whereArgs: [cutoff.millisecondsSinceEpoch]);
}
