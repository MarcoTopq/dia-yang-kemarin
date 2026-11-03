import 'package:sqflite_sqlcipher/sqflite.dart';

import '../local/app_database.dart';
import '../models/soul.dart';

/// Gerbang tunggal ke SOUL (Lapis 2) & OPINI (Lapis 3).
///
/// Jiwa disimpan sebagai satu record JSON di `app_kv` — jiwa itu satu file,
/// bukan tabel relasional. HANYA onboarding & reflection loop yang menulis;
/// tidak ada UI edit jiwa. Konstitusi (Lapis 1) TIDAK ada di sini — itu
/// hard-coded di app.
class SoulRepository {
  SoulRepository(this._db);

  final AppDatabase _db;
  static const _key = 'soul';

  Database get _c => _db.db;

  /// Apakah "dia" sudah lahir (onboarding selesai)?
  Future<bool> exists() async {
    final rows = await _c.query('app_kv',
        columns: ['value'], where: 'key = ?', whereArgs: [_key], limit: 1);
    return rows.isNotEmpty;
  }

  Future<Soul?> load() async {
    final rows = await _c.query('app_kv',
        columns: ['value'], where: 'key = ?', whereArgs: [_key], limit: 1);
    if (rows.isEmpty) return null;
    return Soul.decode(rows.first['value'] as String);
  }

  /// Menulis jiwa. Dipakai onboarding (kelahiran) & reflection loop (evolusi).
  /// Pemanggil bertanggung jawab menegakkan guard evolusi (nature tak tersentuh,
  /// maks perubahan per malam) — lihat reflection loop.
  Future<void> save(Soul soul) async {
    await _c.insert(
      'app_kv',
      {'key': _key, 'value': soul.encode()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
