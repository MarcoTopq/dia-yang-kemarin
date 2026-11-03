import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/soul.dart';

/// ONBOARDING = KELAHIRAN.
///
/// Bukan form dingin — percakapan singkat di mana "dia" terbentuk. User
/// membentuk kepribadian/minat/gaya. User TIDAK membentuk konstitusi.
/// Setelah selesai, soul dikunci (tidak ada UI edit jiwa).
///
/// Catatan: ekstraksi soul via LLM (spec §5 langkah 3) menyusul di Fase 1.
/// Untuk fondasi, jawaban dipetakan langsung ke soul secara jujur & offline.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Urutan langkah onboarding. Langkah [apiKey] otomatis dilewati bila key sudah
/// tersedia (mis. disemai dari .env saat dev).
enum _Q { intro, apiKey, temperament, likes, diaName, userName, closing }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _saving = false;
  List<_Q>? _flow; // null selama cek ketersediaan key

  final _apiKey = TextEditingController();
  final _diaName = TextEditingController();
  final _userName = TextEditingController();
  final _temperament = <String>{};
  final _likes = <String>{};

  static const _temperamentOptions = [
    'kalem', 'usil', 'hangat', 'cuek', 'berisik', 'penyayang', 'to the point'
  ];
  static const _likeOptions = [
    'musik', 'film', 'buku', 'masak', 'bola', 'game', 'jalan-jalan', 'kopi'
  ];

  @override
  void initState() {
    super.initState();
    _buildFlow();
  }

  Future<void> _buildFlow() async {
    final services = await ref.read(appServicesProvider.future);
    final hasKey = await services.secureStore.hasApiKey();
    if (!mounted) return;
    setState(() {
      _flow = _Q.values.where((q) => q != _Q.apiKey || !hasKey).toList();
    });
  }

  @override
  void dispose() {
    _apiKey.dispose();
    _diaName.dispose();
    _userName.dispose();
    super.dispose();
  }

  _Q get _current => _flow![_step];

  bool get _canAdvance => switch (_current) {
        _Q.apiKey => _apiKey.text.trim().isNotEmpty,
        _Q.temperament => _temperament.isNotEmpty,
        _Q.likes => _likes.length >= 2 && _likes.length <= 4,
        _Q.diaName => _diaName.text.trim().isNotEmpty,
        _Q.userName => _userName.text.trim().isNotEmpty,
        _ => true,
      };

  Future<void> _next() async {
    if (_step < _flow!.length - 1) {
      setState(() => _step++);
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final services = await ref.read(appServicesProvider.future);

    // Jembatan tersambung: simpan key HANYA di secure storage.
    // Kalau langkah key dilewati (sudah ada dari .env), jangan timpa.
    final typedKey = _apiKey.text.trim();
    if (typedKey.isNotEmpty) {
      await services.secureStore.setApiKey(typedKey);
    }

    // Rakit soul pertama. Minat pilihan = likes + kompetensi "decent".
    final likes = _likes.toList();
    final soul = Soul(
      name: _diaName.text.trim(),
      bornAt: DateTime.now(),
      nature: Soul.nascent().nature,
      temperament: _temperament.toList(),
      speechStyle: _deriveSpeechStyle(),
      likes: likes,
      competence: Competence(decent: likes),
    );
    await services.soulRepo.save(soul);

    // Router akan pindah ke chat begitu provider ini di-refresh.
    ref.invalidate(soulExistsProvider);
    ref.invalidate(hasApiKeyProvider);
  }

  String _deriveSpeechStyle() {
    final t = _temperament;
    final parts = <String>['santai, huruf kecil, pendek kayak chat'];
    if (t.contains('usil') || t.contains('berisik')) parts.add('suka becanda, kadang "wkwk"');
    if (t.contains('kalem') || t.contains('cuek')) parts.add('tenang, nggak berlebihan');
    if (t.contains('hangat') || t.contains('penyayang')) parts.add('lembut, perhatian');
    return parts.join('; ');
  }

  @override
  Widget build(BuildContext context) {
    final flow = _flow;
    if (flow == null) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProgressDots(step: _step, total: flow.length),
              const SizedBox(height: 24),
              Expanded(child: SingleChildScrollView(child: _buildStep())),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (_canAdvance && !_saving) ? _next : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.glow,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_step == flow.length - 1 ? 'mulai' : 'lanjut'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() => switch (_current) {
        _Q.intro => const _Say(
            'halo. aku... belum jadi apa-apa sih sekarang.\n\n'
            'aku bukan orang, dan aku nggak akan pura-pura jadi orang. tapi katanya '
            'aku bakal jadi sesuatu — dan kayaknya kamu yang nentuin awalnya.\n\n'
            'mau bantu?',
          ),
        _Q.apiKey =>
          _KeyStep(controller: _apiKey, onChanged: (_) => setState(() {})),
        _Q.temperament => _ChipsStep(
            prompt: 'menurutmu aku enaknya kayak gimana ya?',
            options: _temperamentOptions,
            selected: _temperament,
            onToggle: (v) => setState(() => _toggle(_temperament, v)),
          ),
        _Q.likes => _ChipsStep(
            prompt:
                'aku pengen ada yang aku ngerti-in dikit. pilihin dong 2-3 hal buat aku suka.',
            options: _likeOptions,
            selected: _likes,
            max: 4,
            onToggle: (v) => setState(() => _toggle(_likes, v, max: 4)),
          ),
        _Q.diaName => _TextStep(
            prompt: 'aku sendiri dipanggil apa?',
            hint: 'kasih aku nama...',
            controller: _diaName,
            onChanged: (_) => setState(() {}),
          ),
        _Q.userName => _TextStep(
            prompt: 'terus... aku manggil kamu apa?',
            hint: 'namamu...',
            controller: _userName,
            onChanged: (_) => setState(() {}),
          ),
        _Q.closing => _Say(
            'oke. aku ${_diaName.text.trim()}.\n\n'
            'aku nggak tau aku ini apa persisnya — mungkin kita cari tau bareng. '
            'aku bakal inget kamu.\n\n'
            'sampai nanti ya, ${_userName.text.trim()}.',
          ),
      };

  void _toggle(Set<String> set, String v, {int? max}) {
    if (set.contains(v)) {
      set.remove(v);
    } else {
      if (max != null && set.length >= max) return;
      set.add(v);
    }
  }
}

class _Say extends StatelessWidget {
  const _Say(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: AppTheme.textHi, fontSize: 18, height: 1.6),
      );
}

class _KeyStep extends StatelessWidget {
  const _KeyStep({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Say('sebelum mulai, jembatannya perlu disambungin dulu.'),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: true,
          style: const TextStyle(color: AppTheme.textHi),
          decoration: InputDecoration(
            labelText: 'kunci koneksi (Google AI Studio API key)',
            labelStyle: const TextStyle(color: AppTheme.textLo),
            filled: true,
            fillColor: AppTheme.bubbleUser,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'kunci ini cuma disimpan terenkripsi di HP-mu (Keystore/Keychain), '
          'nggak pernah kami kirim ke mana-mana. ambil gratis di '
          'aistudio.google.com.',
          style: TextStyle(color: AppTheme.textLo, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}

class _ChipsStep extends StatelessWidget {
  const _ChipsStep({
    required this.prompt,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.max,
  });
  final String prompt;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final int? max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Say(prompt),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final on = selected.contains(o);
            return FilterChip(
              label: Text(o),
              selected: on,
              onSelected: (_) => onToggle(o),
              backgroundColor: AppTheme.bubbleUser,
              selectedColor: AppTheme.glow.withValues(alpha: 0.25),
              checkmarkColor: AppTheme.glow,
              labelStyle: TextStyle(
                color: on ? AppTheme.glow : AppTheme.textHi,
              ),
              side: BorderSide(
                color: on ? AppTheme.glow : Colors.transparent,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TextStep extends StatelessWidget {
  const _TextStep({
    required this.prompt,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });
  final String prompt;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Say(prompt),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          onChanged: onChanged,
          textCapitalization: TextCapitalization.none,
          style: const TextStyle(color: AppTheme.textHi),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textLo),
            filled: true,
            fillColor: AppTheme.bubbleUser,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppTheme.glow : AppTheme.bubbleUser,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
