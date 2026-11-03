import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/di.dart';
import '../../core/result/failure.dart';
import '../../data/models/entities.dart';
import '../../llm/llm_provider.dart';

/// Status "jembatan" untuk hint ambient di UI — TANPA drama, tanpa angka panik.
enum BridgeNotice { none, thin, needsKey }

class ChatState {
  const ChatState({
    this.messages = const [],
    this.diaTyping = false,
    this.notice = BridgeNotice.none,
    this.loading = true,
  });

  final List<Message> messages;
  final bool diaTyping;
  final BridgeNotice notice;
  final bool loading;

  ChatState copyWith({
    List<Message>? messages,
    bool? diaTyping,
    BridgeNotice? notice,
    bool? loading,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        diaTyping: diaTyping ?? this.diaTyping,
        notice: notice ?? this.notice,
        loading: loading ?? this.loading,
      );
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._ref) : super(const ChatState()) {
    _load();
  }

  final Ref _ref;
  final _uuid = const Uuid();

  AppServices get _svc => _ref.read(appServicesProvider).requireValue;

  /// Satu sesi = satu hari kalender. Kontinuitas lintas hari dijamin oleh
  /// episode + recall + NOW, bukan oleh window sesi.
  String get _sessionId {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final msgs = await _svc.messageRepo.allInSession(_sessionId);
    state = state.copyWith(messages: msgs, loading: false);
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.diaTyping) return;

    final userMsg = Message(
      id: _uuid.v4(),
      role: MessageRole.user,
      text: trimmed,
      sentAt: DateTime.now(),
      sessionId: _sessionId,
    );

    await _svc.messageRepo.add(userMsg);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      diaTyping: true,
      notice: BridgeNotice.none,
    );

    try {
      final ctx = await _svc.contextBuilder.build(
        sessionId: _sessionId,
        latestUserMessage: trimmed,
      );

      final reply = await _svc.llm.chat(
        system: ctx.system,
        turns: ctx.turns,
        temperature: LlmDefaults.chatTemperature,
        maxTokens: LlmDefaults.chatMaxTokens,
      );

      final diaMsg = Message(
        id: _uuid.v4(),
        role: MessageRole.model,
        text: reply,
        sentAt: DateTime.now(),
        sessionId: _sessionId,
      );
      await _svc.messageRepo.add(diaMsg);
      state = state.copyWith(
        messages: [...state.messages, diaMsg],
        diaTyping: false,
      );
    } on Failure catch (e) {
      // "Dia" tidak pernah mengeluarkan pesan error robotik ke chat.
      // Kegagalan disampaikan sebagai hint ambient jembatan — tenang, tanpa drama.
      state = state.copyWith(diaTyping: false, notice: _noticeFor(e));
    } catch (_) {
      state = state.copyWith(diaTyping: false, notice: BridgeNotice.thin);
    }
  }

  BridgeNotice _noticeFor(Failure e) => switch (e) {
        MissingApiKeyFailure() => BridgeNotice.needsKey,
        RateLimitFailure() => BridgeNotice.thin,
        NetworkFailure() => BridgeNotice.thin,
        ProviderFailure() => BridgeNotice.thin,
        StorageFailure() => BridgeNotice.thin,
      };

  void dismissNotice() => state = state.copyWith(notice: BridgeNotice.none);
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>(
  (ref) => ChatController(ref),
);
