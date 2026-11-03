import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penjaga semua rahasia. TIDAK ADA rahasia yang boleh hidup di luar sini
/// (tidak di SharedPreferences, tidak di source, tidak di DB yang tidak
/// terenkripsi). Dua rahasia inti:
///   1. API key provider LLM (dimasukkan user / diinject BE nanti).
///   2. Kunci enkripsi database (di-generate sekali, lalu dipakai buka DB).
///
/// Disimpan di Keystore (Android) / Keychain (iOS) / Credential Store (Windows)
/// lewat flutter_secure_storage.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // Android: data otomatis pakai cipher terenkripsi (Keystore).
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _kApiKey = 'llm_api_key';
  static const _kDbKey = 'db_encryption_key';

  // --- API key ---

  Future<void> setApiKey(String key) => _storage.write(key: _kApiKey, value: key);

  Future<String?> getApiKey() => _storage.read(key: _kApiKey);

  Future<bool> hasApiKey() async => (await getApiKey())?.isNotEmpty ?? false;

  Future<void> clearApiKey() => _storage.delete(key: _kApiKey);

  // --- DB encryption key ---

  /// Mengembalikan kunci enkripsi DB, meng-generate sekali jika belum ada.
  /// Kunci = 32 byte acak (dari Random.secure) → base64url tanpa padding,
  /// aman untuk disuntik ke `PRAGMA key` (tidak mengandung kutip/spasi).
  Future<String> getOrCreateDbKey() async {
    final existing = await _storage.read(key: _kDbKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final key = _generateKey();
    await _storage.write(key: _kDbKey, value: key);
    return key;
  }

  static String _generateKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Hapus segalanya. Dipakai saat "uninstall logis" / reset penuh.
  /// (Uninstall app sebenarnya = dia benar-benar hilang, sesuai janji privasi.)
  Future<void> wipe() => _storage.deleteAll();
}
