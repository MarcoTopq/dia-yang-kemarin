import '../core/config/app_config.dart';
import '../core/constitution/constitution.dart';
import '../data/models/entities.dart';
import '../data/models/soul.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/soul_repository.dart';
import '../llm/chat_turn.dart';
import '../llm/llm_provider.dart';

/// Hasil rakitan konteks untuk satu request chat.
class BuiltContext {
  const BuiltContext({required this.system, required this.turns});
  final String system;
  final List<ChatTurn> turns;
}

/// Merakit 5 blok konteks per pesan (target 1.5k–3k token input):
///   1. KONSTITUSI  (hard-coded, statis)         -> system
///   2. SOUL        (jiwa dirender ringkas)       -> system
///   3. NOW         (reflection teratas + episode)-> system
///   4. RECALL      (memori relevan, vector search)-> system
///   5. CHAT        (pesan terakhir sesi)          -> turns
///
/// Identitas dirakit di sini dari memory store — model hanya "otak" yang
/// menerima konteks ini. Ganti model tidak mengubah "dia".
class ContextBuilder {
  ContextBuilder({
    required SoulRepository soulRepo,
    required MemoryRepository memoryRepo,
    required MessageRepository messageRepo,
    required LlmProvider provider,
  })  : _soulRepo = soulRepo,
        _memoryRepo = memoryRepo,
        _messageRepo = messageRepo,
        _provider = provider;

  final SoulRepository _soulRepo;
  final MemoryRepository _memoryRepo;
  final MessageRepository _messageRepo;
  final LlmProvider _provider;

  Future<BuiltContext> build({
    required String sessionId,
    required String latestUserMessage,
  }) async {
    final soul = await _soulRepo.load() ?? Soul.nascent();
    final reflections =
        await _memoryRepo.topReflections(limit: AppConfig.nowTopReflections);
    final lastEpisode = await _memoryRepo.lastEpisode();

    // Blok 4 — RECALL. Best-effort: kalau embed gagal, jalan tanpa recall.
    List<Recall> recalls = const [];
    try {
      final queryEmbedding = await _provider.embed(latestUserMessage);
      recalls = await _memoryRepo.recall(queryEmbedding,
          topK: AppConfig.recallTopK);
    } catch (_) {
      // Recall opsional — jangan gagalkan chat hanya karena embedding gagal.
    }

    final system = [
      Constitution.systemBlock(),
      _renderSoul(soul),
      _renderNow(reflections, lastEpisode),
      if (recalls.isNotEmpty) _renderRecall(recalls),
    ].join('\n\n');

    // Blok 5 — CHAT.
    final window = await _messageRepo.lastInSession(sessionId,
        limit: AppConfig.chatWindowSize);
    final turns = window
        .map((m) => ChatTurn(
              m.role == MessageRole.user ? ChatRole.user : ChatRole.model,
              m.text,
            ))
        .toList();

    return BuiltContext(system: system, turns: turns);
  }

  // --- render blok ---

  String _renderSoul(Soul s) {
    final b = StringBuffer('SIAPA KAMU (SOUL):\n');
    if (s.name.isNotEmpty) b.writeln('- Namamu: ${s.name}');
    b.writeln('- Nature: ${s.nature}');
    if (s.temperament.isNotEmpty) {
      b.writeln('- Sifat: ${s.temperament.join(", ")}');
    }
    if (s.speechStyle.isNotEmpty) b.writeln('- Gaya ngomong: ${s.speechStyle}');
    if (s.likes.isNotEmpty) b.writeln('- Suka: ${s.likes.join(", ")}');
    if (s.dislikes.isNotEmpty) b.writeln('- Nggak suka: ${s.dislikes.join(", ")}');
    if (s.wonderings.isNotEmpty) {
      b.writeln('- Lagi kamu renungkan: ${s.wonderings.join("; ")}');
    }

    // Kompetensi ditegakkan dua arah (lihat spec §6).
    b.writeln('\nKOMPETENSIMU (di luar ini kamu TIDAK TAHU — jujur aja):');
    if (s.competence.decent.isNotEmpty) {
      b.writeln('- Cukup ngerti: ${s.competence.decent.join(", ")}');
    }
    if (s.competence.surface.isNotEmpty) {
      b.writeln('- Tau permukaan: ${s.competence.surface.join(", ")}');
    }
    if (s.competence.learnedFromUser.isNotEmpty) {
      b.writeln(
          '- Diajarin sama dia: ${s.competence.learnedFromUser.join(", ")}');
    }

    if (s.opinions.isNotEmpty) {
      b.writeln('\nOPINIMU (boleh berubah, boleh diperdebatkan):');
      for (final o in s.opinions.take(5)) {
        b.writeln('- ${o.topic}: ${o.stance}');
      }
    }
    return b.toString().trimRight();
  }

  String _renderNow(List<Reflection> reflections, Episode? last) {
    final b = StringBuffer('HIDUPMU TERKINI (NOW):\n');
    if (reflections.isEmpty && last == null) {
      b.writeln('- (belum ada banyak kenangan; kalian masih baru kenal)');
      return b.toString().trimRight();
    }
    for (final r in reflections) {
      b.writeln('- ${r.insight}');
    }
    if (last != null) {
      b.writeln('- Kemarin: ${last.summary}'
          '${last.mood != null ? " (mood dia: ${last.mood})" : ""}');
    }
    return b.toString().trimRight();
  }

  String _renderRecall(List<Recall> recalls) {
    final b = StringBuffer(
        'YANG TERINGAT (relevan sama obrolan sekarang — pakai kalau pas):\n');
    for (final r in recalls) {
      b.writeln('- ${r.text}');
    }
    return b.toString().trimRight();
  }
}
