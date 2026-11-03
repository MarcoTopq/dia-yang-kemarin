import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'chat_controller.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(chatControllerProvider.notifier).send(text);
    _scrollToBottomSoon();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider, (_, _) => _scrollToBottomSoon());

    final itemCount = state.messages.length + (state.diaTyping ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const _BridgeGlow(),
      ),
      body: Column(
        children: [
          if (state.notice != BridgeNotice.none) _NoticeBanner(notice: state.notice),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty && !state.diaTyping
                    ? const _EmptyState()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: itemCount,
                        itemBuilder: (context, i) {
                          if (i >= state.messages.length) {
                            return const TypingBubble();
                          }
                          return MessageBubble(message: state.messages[i]);
                        },
                      ),
          ),
          _Composer(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

class _BridgeGlow extends StatelessWidget {
  const _BridgeGlow();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.glow,
            boxShadow: [
              BoxShadow(
                color: AppTheme.glow.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text('dia'),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'jembatannya terbuka.\nsapa dia.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textLo, height: 1.6),
        ),
      ),
    );
  }
}

class _NoticeBanner extends ConsumerWidget {
  const _NoticeBanner({required this.notice});
  final BridgeNotice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (text, icon) = switch (notice) {
      BridgeNotice.thin => (
          'sinyal jembatannya lagi tipis. lanjut bentar lagi ya — dia nggak ke mana-mana kok.',
          Icons.blur_on,
        ),
      BridgeNotice.needsKey => (
          'jembatan belum tersambung. atur kunci koneksi di pengaturan.',
          Icons.link_off,
        ),
      BridgeNotice.none => ('', Icons.circle),
    };

    return Material(
      color: AppTheme.bubbleDia,
      child: InkWell(
        onTap: () => ref.read(chatControllerProvider.notifier).dismissNotice(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.glowAlt),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: const TextStyle(color: AppTheme.textLo, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(color: AppTheme.textHi),
                decoration: InputDecoration(
                  hintText: 'ketik...',
                  hintStyle: const TextStyle(color: AppTheme.textLo),
                  filled: true,
                  fillColor: AppTheme.bubbleUser,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.arrow_upward),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.glow,
                foregroundColor: AppTheme.background,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
