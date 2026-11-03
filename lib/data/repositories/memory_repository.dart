import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/util/vectors.dart';
import '../local/app_database.dart';
import '../models/entities.dart';

/// Satu recall hasil pencarian vektor (chunk/episode + skor).
class Recall {
  const Recall(this.text, this.score, this.source);
  final String text;
  final double score;
  final String source; // "chunk:kind" | "episode"
}

/// Gerbang ke memori jangka panjang: Person, Episode, Reflection, MemoryChunk.
/// Recall memakai cosine similarity manual di Dart (blok RECALL context builder).
class MemoryRepository {
  MemoryRepository(this._db);

  final AppDatabase _db;
  Database get _c => _db.db;

  // --- Person (fakta user) ---

  Future<void> upsertPerson(Person p) => _c.insert('persons', p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Person>> allPersons() async =>
      (await _c.query('persons', orderBy: 'updated_at DESC'))
          .map(Person.fromMap)
          .toList();

  // --- Episode ---

  Future<void> addEpisode(Episode e) => _c.insert('episodes', e.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Episode>> recentEpisodes({int limit = 14}) async =>
      (await _c.query('episodes', orderBy: 'date DESC', limit: limit))
          .map(Episode.fromMap)
          .toList();

  Future<Episode?> lastEpisode() async {
    final rows = await _c.query('episodes', orderBy: 'date DESC', limit: 1);
    return rows.isEmpty ? null : Episode.fromMap(rows.first);
  }

  // --- Reflection ---

  Future<void> upsertReflection(Reflection r) => _c.insert(
      'reflections', r.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Reflection>> topReflections({String? about, int limit = 3}) async {
    final rows = await _c.query(
      'reflections',
      where: about != null ? 'about = ?' : null,
      whereArgs: about != null ? [about] : null,
      orderBy: 'weight DESC, created_at DESC',
      limit: limit,
    );
    return rows.map(Reflection.fromMap).toList();
  }

  // --- MemoryChunk ---

  Future<void> addChunk(MemoryChunk chunk) => _c.insert('memory_chunks',
      chunk.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  // --- Recall (vector search lokal) ---

  /// Ambil [topK] memori paling relevan dengan [queryEmbedding].
  /// Menggabungkan MemoryChunk + Episode, diranking cosine similarity.
  /// [minScore] menyaring hasil yang terlalu lemah agar tidak menyuntik noise.
  Future<List<Recall>> recall(
    List<double> queryEmbedding, {
    int topK = 3,
    double minScore = 0.6,
  }) async {
    if (queryEmbedding.isEmpty) return const [];

    final results = <Recall>[];

    final chunks = await _c.query('memory_chunks');
    for (final row in chunks) {
      final c = MemoryChunk.fromMap(row);
      final score = Vectors.cosine(queryEmbedding, c.embedding);
      if (score >= minScore) {
        results.add(Recall(c.text, score, 'chunk:${c.kind.wire}'));
      }
    }

    final episodes = await _c.query('episodes', orderBy: 'date DESC', limit: 60);
    for (final row in episodes) {
      final e = Episode.fromMap(row);
      final score = Vectors.cosine(queryEmbedding, e.embedding);
      if (score >= minScore) {
        results.add(Recall(e.summary, score, 'episode'));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(topK).toList();
  }
}
