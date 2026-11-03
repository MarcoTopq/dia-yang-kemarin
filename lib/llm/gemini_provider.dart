import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/result/failure.dart';
import '../core/security/secure_store.dart';
import 'chat_turn.dart';
import 'llm_provider.dart';

/// Implementasi pertama: Google Generative Language API (Gemini).
///
/// API key dibaca dari [SecureStore] setiap request — TIDAK di-cache di memori
/// lebih lama dari perlu, TIDAK pernah di-log. Kegagalan dipetakan ke [Failure]
/// yang bermakna agar lapisan atas bisa memutuskan "diam & retry" vs tampilkan.
class GeminiProvider implements LlmProvider {
  GeminiProvider({
    required SecureStore secureStore,
    http.Client? client,
  })  : _secure = secureStore,
        _client = client ?? http.Client();

  final SecureStore _secure;
  final http.Client _client;

  static const _maxRetries = 3;
  static const _baseBackoff = Duration(milliseconds: 800);

  @override
  Future<String> chat({
    required String system,
    required List<ChatTurn> turns,
    double temperature = AppConfig.chatTemperature,
    int maxTokens = AppConfig.chatMaxTokens,
  }) {
    return _generate(
      model: AppConfig.geminiChatModel,
      system: system,
      contents: turns.map(_turnToContent).toList(),
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  @override
  Future<String> task({
    required String instruction,
    required String input,
    double temperature = AppConfig.taskTemperature,
    int maxTokens = AppConfig.taskMaxTokens,
  }) {
    return _generate(
      model: AppConfig.geminiChatModel,
      system: instruction,
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': input}
          ],
        }
      ],
      temperature: temperature,
      maxTokens: maxTokens,
      // Ekstraksi/refleksi harus JSON yang bisa diparse.
      responseMimeType: 'application/json',
    );
  }

  @override
  Future<String> chatWithSearch({
    required String system,
    required List<ChatTurn> turns,
    double temperature = AppConfig.chatTemperature,
    int maxTokens = AppConfig.chatMaxTokens,
  }) {
    return _generate(
      model: AppConfig.geminiChatModel,
      system: system,
      contents: turns.map(_turnToContent).toList(),
      temperature: temperature,
      maxTokens: maxTokens,
      tools: [
        {'google_search': <String, dynamic>{}}
      ],
    );
  }

  @override
  Future<List<double>> embed(String text) async {
    final key = await _requireKey();
    final uri = _uri('${AppConfig.geminiEmbedModel}:embedContent', key);
    final body = jsonEncode({
      'model': 'models/${AppConfig.geminiEmbedModel}',
      'content': {
        'parts': [
          {'text': text}
        ]
      },
    });

    final res = await _send(uri, body);
    final json = _decode(res);
    final values = json['embedding']?['values'];
    if (values is! List) {
      throw const ProviderFailure('Respons embedding tidak valid.');
    }
    return values.map((e) => (e as num).toDouble()).toList();
  }

  // --- internals ---

  Future<String> _generate({
    required String model,
    required String system,
    required List<Map<String, dynamic>> contents,
    required double temperature,
    required int maxTokens,
    String? responseMimeType,
    List<Map<String, dynamic>>? tools,
  }) async {
    final key = await _requireKey();
    final uri = _uri('$model:generateContent', key);

    final payload = <String, dynamic>{
      'system_instruction': {
        'parts': [
          {'text': system}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
        'responseMimeType': ?responseMimeType,
      },
      'tools': ?tools,
      // Safety settings dibiarkan default provider; filter konten SEBENARNYA
      // ditegakkan oleh Konstitusi di lapis prompt, bukan diserahkan ke provider.
    };

    final res = await _send(uri, jsonEncode(payload));
    final json = _decode(res);
    return _extractText(json);
  }

  Map<String, dynamic> _turnToContent(ChatTurn t) => {
        'role': t.role == ChatRole.user ? 'user' : 'model',
        'parts': [
          {'text': t.text}
        ],
      };

  Uri _uri(String path, String key) =>
      Uri.parse('${AppConfig.geminiBaseUrl}/models/$path?key=$key');

  Future<String> _requireKey() async {
    final key = await _secure.getApiKey();
    if (key == null || key.isEmpty) throw const MissingApiKeyFailure();
    return key;
  }

  /// POST dengan retry + exponential backoff untuk 429/5xx.
  Future<http.Response> _send(Uri uri, String body) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final res = await _client
            .post(uri,
                headers: const {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 30));

        if (res.statusCode == 200) return res;

        if (res.statusCode == 429) {
          if (attempt >= _maxRetries) {
            throw RateLimitFailure(
              'Rate limit provider.',
              retryAfter: _parseRetryAfter(res),
            );
          }
          await Future.delayed(_backoff(attempt));
          continue;
        }

        if (res.statusCode >= 500) {
          if (attempt >= _maxRetries) {
            throw ProviderFailure('Server provider error.',
                statusCode: res.statusCode);
          }
          await Future.delayed(_backoff(attempt));
          continue;
        }

        // 4xx lain (400/403/404) — tidak layak retry.
        throw ProviderFailure(
          _safeErrorMessage(res),
          statusCode: res.statusCode,
        );
      } on TimeoutException catch (e) {
        if (attempt >= _maxRetries) {
          throw NetworkFailure('Timeout menghubungi provider.', cause: e);
        }
        await Future.delayed(_backoff(attempt));
      } on http.ClientException catch (e) {
        if (attempt >= _maxRetries) {
          throw NetworkFailure('Gagal menghubungi provider.', cause: e);
        }
        await Future.delayed(_backoff(attempt));
      }
    }
  }

  Duration _backoff(int attempt) =>
      _baseBackoff * (1 << (attempt - 1)); // 800ms, 1.6s, 3.2s

  Duration? _parseRetryAfter(http.Response res) {
    final h = res.headers['retry-after'];
    if (h == null) return null;
    final secs = int.tryParse(h);
    return secs != null ? Duration(seconds: secs) : null;
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw ProviderFailure('Respons bukan JSON valid.', cause: e);
    }
  }

  String _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      // Bisa jadi diblokir safety → perlakukan sebagai provider failure,
      // lapisan atas akan membuat "dia" diam, bukan menampilkan error.
      throw const ProviderFailure('Tidak ada kandidat respons.');
    }
    final parts = candidates.first?['content']?['parts'];
    if (parts is! List || parts.isEmpty) {
      throw const ProviderFailure('Respons kosong.');
    }
    final buffer = StringBuffer();
    for (final p in parts) {
      final t = p?['text'];
      if (t is String) buffer.write(t);
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) throw const ProviderFailure('Respons kosong.');
    return text;
  }

  /// Pesan error yang aman di-log — TIDAK memuat body mentah (bisa berisi key
  /// atau data). Hanya ambil field message dari struktur error Google.
  String _safeErrorMessage(http.Response res) {
    try {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = j['error']?['message'];
      if (msg is String) return msg;
    } catch (_) {}
    return 'HTTP ${res.statusCode}';
  }

  void dispose() => _client.close();
}
