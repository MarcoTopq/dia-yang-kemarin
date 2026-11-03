import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/secure_store.dart';
import '../data/local/app_database.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/soul_repository.dart';
import '../llm/gemini_provider.dart';
import '../llm/llm_provider.dart';
import '../soul_engine/context_builder.dart';

/// Kumpulan servis yang sudah dibootstrap (DB terenkripsi sudah terbuka).
/// Dirakit sekali oleh [appServicesProvider].
class AppServices {
  AppServices({
    required this.secureStore,
    required this.db,
    required this.soulRepo,
    required this.memoryRepo,
    required this.messageRepo,
    required this.llm,
    required this.contextBuilder,
  });

  final SecureStore secureStore;
  final AppDatabase db;
  final SoulRepository soulRepo;
  final MemoryRepository memoryRepo;
  final MessageRepository messageRepo;
  final LlmProvider llm;
  final ContextBuilder contextBuilder;
}

/// SecureStore boleh berdiri sendiri (dibutuhkan sebelum DB dibuka).
final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

/// Nama variabel di `.env` yang memuat API key Gemini.
const _envApiKeyName = 'GEMINI_API_KEY';

/// Menyalin key dari `.env` ke secure storage sekali (dev). Idempoten & aman:
/// - tidak menimpa key yang sudah ada di secure storage
/// - diam saja kalau .env tidak dimuat / key kosong
Future<void> _seedApiKeyFromEnv(SecureStore secure) async {
  if (!dotenv.isInitialized) return;
  final fromEnv = dotenv.maybeGet(_envApiKeyName)?.trim();
  if (fromEnv == null || fromEnv.isEmpty) return;
  if (await secure.hasApiKey()) return;
  await secure.setApiKey(fromEnv);
}

/// Bootstrap: ambil kunci enkripsi -> buka DB terenkripsi -> rakit repos & engine.
/// UI menunggu future ini sebelum masuk onboarding/chat.
final appServicesProvider = FutureProvider<AppServices>((ref) async {
  final secure = ref.watch(secureStoreProvider);

  // Semai API key dari .env (dev) ke secure storage HANYA jika belum ada.
  // Secure storage tetap satu-satunya sumber runtime; .env cuma seeder dev.
  await _seedApiKeyFromEnv(secure);

  final dbKey = await secure.getOrCreateDbKey();
  final db = await AppDatabase.open(dbKey);
  ref.onDispose(db.close);

  final llm = GeminiProvider(secureStore: secure);
  ref.onDispose(llm.dispose);

  final soulRepo = SoulRepository(db);
  final memoryRepo = MemoryRepository(db);
  final messageRepo = MessageRepository(db);

  final contextBuilder = ContextBuilder(
    soulRepo: soulRepo,
    memoryRepo: memoryRepo,
    messageRepo: messageRepo,
    provider: llm,
  );

  return AppServices(
    secureStore: secure,
    db: db,
    soulRepo: soulRepo,
    memoryRepo: memoryRepo,
    messageRepo: messageRepo,
    llm: llm,
    contextBuilder: contextBuilder,
  );
});

/// Apakah "dia" sudah lahir? Menentukan rute awal (onboarding vs chat).
final soulExistsProvider = FutureProvider<bool>((ref) async {
  final services = await ref.watch(appServicesProvider.future);
  return services.soulRepo.exists();
});

/// Apakah API key sudah diset? (gate onboarding).
final hasApiKeyProvider = FutureProvider<bool>((ref) async {
  final secure = ref.watch(secureStoreProvider);
  return secure.hasApiKey();
});
