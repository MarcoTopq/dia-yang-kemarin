/// Konstanta konfigurasi aplikasi. Tidak ada rahasia di sini — hanya parameter
/// perilaku. API key TIDAK PERNAH di sini (lihat SecureStore).
class AppConfig {
  const AppConfig._();

  // --- LLM ---
  /// Base URL Google Generative Language API.
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Model untuk chat harian & task (ekstraksi/refleksi). Tier flash = murah.
  /// Verifikasi model terbaru saat implementasi produksi.
  static const String geminiChatModel = 'gemini-2.5-flash';

  /// Model embedding untuk recall (vector search lokal).
  static const String geminiEmbedModel = 'text-embedding-004';

  // --- Context budget (token, perkiraan) ---
  static const int targetInputTokenMin = 1500;
  static const int targetInputTokenMax = 3000;

  /// Jumlah pesan terakhir sesi yang dimasukkan ke blok CHAT.
  static const int chatWindowSize = 12;

  /// Jumlah MemoryChunk/Episode relevan yang di-recall (blok RECALL).
  static const int recallTopK = 3;

  /// Jumlah reflection teratas yang dimasukkan ke blok NOW.
  static const int nowTopReflections = 3;

  // --- Generation params ---
  static const double chatTemperature = 0.9;
  static const int chatMaxTokens = 400;
  static const double taskTemperature = 0.2;
  static const int taskMaxTokens = 1500;

  // --- Lookup ("disuruh nyari") ---
  static const int lookupMaxPerDay = 3;

  // --- Proactive messaging quota ---
  static const int proactiveMaxPerDay = 1;
  static const int proactiveMaxPerWeek = 4;

  /// Jarak minimum (jam) dari interaksi terakhir sebelum boleh nyapa duluan.
  static const int proactiveMinGapHours = 20;

  // --- Reflection ---
  /// Maks field soul yang boleh berubah per malam (guard evolusi pelan).
  static const int soulMaxChangesPerNight = 2;

  /// Umur maksimum Message mentah (hari) sebelum dipangkas.
  static const int rawMessageRetentionDays = 30;

  // --- DB ---
  static const String dbFileName = 'dia.db';
}
