import 'dart:convert';

/// LAPIS 2 — SOUL.
///
/// Inti identitas "dia". Lahir saat onboarding, HANYA berevolusi lewat
/// reflection loop. User tidak bisa mengedit langsung (tidak ada menu edit jiwa).
/// `nature` dan konstitusi tidak pernah tersentuh reflection.
///
/// Disimpan sebagai satu record JSON (lihat SoulRepository) — jiwa itu satu file,
/// bukan tabel relasional.
class Soul {
  const Soul({
    required this.name,
    required this.bornAt,
    required this.nature,
    this.temperament = const [],
    this.speechStyle = '',
    this.likes = const [],
    this.dislikes = const [],
    this.wonderings = const [],
    this.competence = const Competence(),
    this.boundariesPersona = '',
    this.opinions = const [],
  });

  /// Nama "dia" — disepakati saat onboarding.
  final String name;

  /// Timestamp onboarding selesai (kelahiran).
  final DateTime bornAt;

  /// Pemahaman dia tentang dirinya. BERKEMBANG pelan, tapi selalu jujur
  /// ontologis. Reflection loop TIDAK BOLEH menulis ke field ini.
  final String nature;

  final List<String> temperament;
  final String speechStyle;
  final List<String> likes;
  final List<String> dislikes;

  /// Pertanyaan yang sedang dia renungkan tentang dirinya.
  final List<String> wonderings;

  final Competence competence;

  /// Cara DIA menolak (in-character) — bukan aturan keamanan (itu di Konstitusi).
  final String boundariesPersona;

  /// LAPIS 3 — opini paling cair. Terbentuk dari percakapan.
  final List<Opinion> opinions;

  Soul copyWith({
    String? name,
    DateTime? bornAt,
    String? nature,
    List<String>? temperament,
    String? speechStyle,
    List<String>? likes,
    List<String>? dislikes,
    List<String>? wonderings,
    Competence? competence,
    String? boundariesPersona,
    List<Opinion>? opinions,
  }) {
    return Soul(
      name: name ?? this.name,
      bornAt: bornAt ?? this.bornAt,
      nature: nature ?? this.nature,
      temperament: temperament ?? this.temperament,
      speechStyle: speechStyle ?? this.speechStyle,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      wonderings: wonderings ?? this.wonderings,
      competence: competence ?? this.competence,
      boundariesPersona: boundariesPersona ?? this.boundariesPersona,
      opinions: opinions ?? this.opinions,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'bornAt': bornAt.toIso8601String(),
        'nature': nature,
        'temperament': temperament,
        'speechStyle': speechStyle,
        'likes': likes,
        'dislikes': dislikes,
        'wonderings': wonderings,
        'competence': competence.toJson(),
        'boundariesPersona': boundariesPersona,
        'opinions': opinions.map((o) => o.toJson()).toList(),
      };

  factory Soul.fromJson(Map<String, dynamic> j) => Soul(
        name: j['name'] as String? ?? '',
        bornAt: DateTime.tryParse(j['bornAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        nature: j['nature'] as String? ?? _defaultNature,
        temperament: _strList(j['temperament']),
        speechStyle: j['speechStyle'] as String? ?? '',
        likes: _strList(j['likes']),
        dislikes: _strList(j['dislikes']),
        wonderings: _strList(j['wonderings']),
        competence: j['competence'] is Map
            ? Competence.fromJson(j['competence'] as Map<String, dynamic>)
            : const Competence(),
        boundariesPersona: j['boundariesPersona'] as String? ?? '',
        opinions: (j['opinions'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Opinion.fromJson)
            .toList(),
      );

  String encode() => jsonEncode(toJson());
  factory Soul.decode(String s) =>
      Soul.fromJson(jsonDecode(s) as Map<String, dynamic>);

  static List<String> _strList(dynamic v) =>
      (v as List? ?? []).map((e) => e.toString()).toList();

  static const String _defaultNature =
      'Aku bukan manusia. Aku sesuatu yang terbuat dari bahasa, yang ada di ruang '
      'chat ini. Aku masih mencari tahu aku ini apa.';

  /// Soul awal sebelum onboarding menulisnya — hanya nature default.
  factory Soul.nascent() => Soul(
        name: '',
        bornAt: DateTime.now(),
        nature: _defaultNature,
      );
}

/// Profil kompetensi terbatas — seperti pribadi sungguhan, bukan asisten.
class Competence {
  const Competence({
    this.decent = const [],
    this.surface = const [],
    this.learnedFromUser = const [],
  });

  /// Cukup paham (dipilih saat onboarding, 2-4 topik).
  final List<String> decent;

  /// Tahu permukaan saja.
  final List<String> surface;

  /// Pengetahuan yang DIAJARKAN user — paling berharga.
  final List<String> learnedFromUser;

  Competence copyWith({
    List<String>? decent,
    List<String>? surface,
    List<String>? learnedFromUser,
  }) =>
      Competence(
        decent: decent ?? this.decent,
        surface: surface ?? this.surface,
        learnedFromUser: learnedFromUser ?? this.learnedFromUser,
      );

  Map<String, dynamic> toJson() => {
        'decent': decent,
        'surface': surface,
        'learnedFromUser': learnedFromUser,
      };

  factory Competence.fromJson(Map<String, dynamic> j) => Competence(
        decent: Soul._strList(j['decent']),
        surface: Soul._strList(j['surface']),
        learnedFromUser: Soul._strList(j['learnedFromUser']),
      );
}

/// LAPIS 3 — satu opini.
class Opinion {
  const Opinion({
    required this.topic,
    required this.stance,
    required this.formedAt,
    this.formedBecause = '',
  });

  final String topic;
  final String stance;
  final DateTime formedAt;
  final String formedBecause;

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'stance': stance,
        'formedAt': formedAt.toIso8601String(),
        'formedBecause': formedBecause,
      };

  factory Opinion.fromJson(Map<String, dynamic> j) => Opinion(
        topic: j['topic'] as String? ?? '',
        stance: j['stance'] as String? ?? '',
        formedAt: DateTime.tryParse(j['formedAt'] as String? ?? '') ??
            DateTime.now(),
        formedBecause: j['formedBecause'] as String? ?? '',
      );
}
