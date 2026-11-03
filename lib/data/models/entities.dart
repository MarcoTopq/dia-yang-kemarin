import 'dart:convert';

/// Entitas domain untuk memory store. Setiap kelas tahu cara memetakan
/// dirinya ke/dari baris SQLite (Map). Tanggal disimpan sebagai epoch millis.

enum MessageRole { user, model }

class Message {
  const Message({
    required this.id,
    required this.role,
    required this.text,
    required this.sentAt,
    required this.sessionId,
  });

  final String id;
  final MessageRole role;
  final String text;
  final DateTime sentAt;
  final String sessionId;

  Map<String, Object?> toMap() => {
        'id': id,
        'role': role.name,
        'content': text,
        'sent_at': sentAt.millisecondsSinceEpoch,
        'session_id': sessionId,
      };

  factory Message.fromMap(Map<String, Object?> m) => Message(
        id: m['id'] as String,
        role: (m['role'] as String) == 'user'
            ? MessageRole.user
            : MessageRole.model,
        text: m['content'] as String,
        sentAt:
            DateTime.fromMillisecondsSinceEpoch(m['sent_at'] as int),
        sessionId: m['session_id'] as String,
      );
}

class Person {
  const Person({
    required this.id,
    required this.key,
    required this.value,
    this.confidence = 0.5,
    required this.learnedAt,
    required this.updatedAt,
    this.source,
  });

  final String id;
  final String key;
  final String value;
  final double confidence;
  final DateTime learnedAt;
  final DateTime updatedAt;
  final String? source;

  Map<String, Object?> toMap() => {
        'id': id,
        'key': key,
        'value': value,
        'confidence': confidence,
        'learned_at': learnedAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'source': source,
      };

  factory Person.fromMap(Map<String, Object?> m) => Person(
        id: m['id'] as String,
        key: m['key'] as String,
        value: m['value'] as String,
        confidence: (m['confidence'] as num).toDouble(),
        learnedAt:
            DateTime.fromMillisecondsSinceEpoch(m['learned_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
        source: m['source'] as String?,
      );
}

class Episode {
  const Episode({
    required this.id,
    required this.date,
    required this.summary,
    this.mood,
    this.highlights = const [],
    this.embedding = const [],
  });

  final String id;
  final DateTime date;
  final String summary;
  final String? mood;
  final List<String> highlights;
  final List<double> embedding;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date.millisecondsSinceEpoch,
        'summary': summary,
        'mood': mood,
        'highlights': jsonEncode(highlights),
        'embedding': jsonEncode(embedding),
      };

  factory Episode.fromMap(Map<String, Object?> m) => Episode(
        id: m['id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        summary: m['summary'] as String,
        mood: m['mood'] as String?,
        highlights: _strList(m['highlights']),
        embedding: _dblList(m['embedding']),
      );
}

class Reflection {
  const Reflection({
    required this.id,
    required this.createdAt,
    required this.about, // "user" | "self" | "us"
    required this.insight,
    this.evidence = const [],
    this.weight = 1.0,
  });

  final String id;
  final DateTime createdAt;
  final String about;
  final String insight;
  final List<String> evidence;
  final double weight;

  Map<String, Object?> toMap() => {
        'id': id,
        'created_at': createdAt.millisecondsSinceEpoch,
        'about': about,
        'insight': insight,
        'evidence': jsonEncode(evidence),
        'weight': weight,
      };

  factory Reflection.fromMap(Map<String, Object?> m) => Reflection(
        id: m['id'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        about: m['about'] as String,
        insight: m['insight'] as String,
        evidence: _strList(m['evidence']),
        weight: (m['weight'] as num).toDouble(),
      );
}

enum ChunkKind { userStory, taughtKnowledge, moment }

extension ChunkKindX on ChunkKind {
  String get wire => switch (this) {
        ChunkKind.userStory => 'user_story',
        ChunkKind.taughtKnowledge => 'taught_knowledge',
        ChunkKind.moment => 'moment',
      };
  static ChunkKind parse(String s) => switch (s) {
        'taught_knowledge' => ChunkKind.taughtKnowledge,
        'moment' => ChunkKind.moment,
        _ => ChunkKind.userStory,
      };
}

class MemoryChunk {
  const MemoryChunk({
    required this.id,
    required this.text,
    required this.createdAt,
    this.embedding = const [],
    required this.kind,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final List<double> embedding;
  final ChunkKind kind;

  Map<String, Object?> toMap() => {
        'id': id,
        'content': text,
        'created_at': createdAt.millisecondsSinceEpoch,
        'embedding': jsonEncode(embedding),
        'kind': kind.wire,
      };

  factory MemoryChunk.fromMap(Map<String, Object?> m) => MemoryChunk(
        id: m['id'] as String,
        text: m['content'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        embedding: _dblList(m['embedding']),
        kind: ChunkKindX.parse(m['kind'] as String),
      );
}

List<String> _strList(Object? raw) {
  if (raw is! String || raw.isEmpty) return const [];
  return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
}

List<double> _dblList(Object? raw) {
  if (raw is! String || raw.isEmpty) return const [];
  return (jsonDecode(raw) as List).map((e) => (e as num).toDouble()).toList();
}
