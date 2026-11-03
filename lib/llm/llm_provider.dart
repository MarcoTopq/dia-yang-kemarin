import '../core/config/app_config.dart';
import 'chat_turn.dart';

/// Abstraksi otak. Identitas "dia" hidup di memory store, BUKAN di sini —
/// maka provider bisa diganti kapan saja tanpa dia berubah.
///
/// Tiga kemampuan:
///   - [chat]   : percakapan (temperature tinggi, output pendek).
///   - [task]   : ekstraksi/refleksi (temperature rendah, output JSON).
///   - [embed]  : vektor untuk recall lokal.
///   - [chatWithSearch] : lookup "disuruh nyari" (grounding). Opsional.
abstract interface class LlmProvider {
  Future<String> chat({
    required String system,
    required List<ChatTurn> turns,
    double temperature,
    int maxTokens,
  });

  Future<String> task({
    required String instruction,
    required String input,
    double temperature,
    int maxTokens,
  });

  Future<List<double>> embed(String text);

  /// Lookup dengan grounding (Google Search). Boleh dilempar
  /// [UnsupportedError] oleh provider yang tidak mendukungnya.
  Future<String> chatWithSearch({
    required String system,
    required List<ChatTurn> turns,
    double temperature,
    int maxTokens,
  });
}

/// Nilai default parameter — dipusatkan agar konsisten lintas provider.
class LlmDefaults {
  const LlmDefaults._();
  static const double chatTemperature = AppConfig.chatTemperature;
  static const int chatMaxTokens = AppConfig.chatMaxTokens;
  static const double taskTemperature = AppConfig.taskTemperature;
  static const int taskMaxTokens = AppConfig.taskMaxTokens;
}
