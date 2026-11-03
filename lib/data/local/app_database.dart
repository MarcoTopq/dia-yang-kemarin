import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/config/app_config.dart';

/// Database lokal TERENKRIPSI (SQLCipher via sqflite_sqlcipher).
///
/// SEMUA memori & identitas "dia" hidup di sini — tidak pernah keluar device.
/// Dibuka dengan passphrase dari SecureStore (Keystore/Keychain). File DB di
/// direktori privat app; isinya terenkripsi at-rest oleh SQLCipher (AES-256).
///
/// Tidak ada codegen — skema didefinisikan eksplisit di [_onCreate] agar
/// transparan dan mudah diaudit.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const _schemaVersion = 1;

  /// Buka (atau buat) DB terenkripsi dengan [encryptionKey].
  static Future<AppDatabase> open(String encryptionKey) async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, AppConfig.dbFileName);

    final db = await openDatabase(
      path,
      password: encryptionKey, // <- SQLCipher: seluruh file terenkripsi.
      version: _schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
    );

    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Singleton JSON (soul, rhythm, quota state).
    batch.execute('''
      CREATE TABLE app_kv (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Fakta tentang user.
    batch.execute('''
      CREATE TABLE persons (
        id         TEXT PRIMARY KEY,
        key        TEXT NOT NULL,
        value      TEXT NOT NULL,
        confidence REAL NOT NULL DEFAULT 0.5,
        learned_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        source     TEXT
      );
    ''');
    batch.execute('CREATE INDEX idx_persons_key ON persons(key);');

    // Ringkasan harian — bahan refleksi.
    batch.execute('''
      CREATE TABLE episodes (
        id         TEXT PRIMARY KEY,
        date       INTEGER NOT NULL,
        summary    TEXT NOT NULL,
        mood       TEXT,
        highlights TEXT NOT NULL DEFAULT '[]',
        embedding  TEXT NOT NULL DEFAULT '[]'
      );
    ''');
    batch.execute('CREATE INDEX idx_episodes_date ON episodes(date DESC);');

    // Hasil renungan — "perkembangan".
    batch.execute('''
      CREATE TABLE reflections (
        id         TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        about      TEXT NOT NULL,
        insight    TEXT NOT NULL,
        evidence   TEXT NOT NULL DEFAULT '[]',
        weight     REAL NOT NULL DEFAULT 1.0
      );
    ''');
    batch.execute(
        'CREATE INDEX idx_reflections_weight ON reflections(weight DESC);');

    // Potongan percakapan penting untuk recall.
    batch.execute('''
      CREATE TABLE memory_chunks (
        id         TEXT PRIMARY KEY,
        content    TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        embedding  TEXT NOT NULL DEFAULT '[]',
        kind       TEXT NOT NULL
      );
    ''');

    // Chat mentah (untuk UI). Dipangkas oleh reflection loop.
    batch.execute('''
      CREATE TABLE messages (
        id         TEXT PRIMARY KEY,
        role       TEXT NOT NULL,
        content    TEXT NOT NULL,
        sent_at    INTEGER NOT NULL,
        session_id TEXT NOT NULL
      );
    ''');
    batch.execute('CREATE INDEX idx_messages_sent ON messages(sent_at DESC);');

    await batch.commit(noResult: true);
  }

  Future<void> close() => db.close();
}
