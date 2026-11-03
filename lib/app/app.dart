import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/chat/chat_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'di.dart';

class DiaApp extends StatelessWidget {
  const DiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dia yang Kemarin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _Gate(),
    );
  }
}

/// Menentukan rute awal: bootstrap DB -> cek apakah "dia" sudah lahir.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(appServicesProvider);

    return services.when(
      loading: () => const _Splash(),
      error: (e, _) => _ErrorScreen(message: '$e'),
      data: (_) {
        final born = ref.watch(soulExistsProvider);
        return born.when(
          loading: () => const _Splash(),
          error: (e, _) => _ErrorScreen(message: '$e'),
          data: (exists) =>
              exists ? const ChatScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
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
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'ada yang nggak beres pas menyiapkan ruang dia.\n\n$message',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textLo, height: 1.6),
          ),
        ),
      ),
    );
  }
}
