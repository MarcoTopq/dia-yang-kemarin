/// Tipe kegagalan berjenjang. Dipakai untuk membedakan error yang boleh
/// ditampilkan halus vs error yang membuat "dia" diam saja (retry di background).
sealed class Failure implements Exception {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

/// API key belum diset — perlu onboarding/settings.
class MissingApiKeyFailure extends Failure {
  const MissingApiKeyFailure() : super('API key belum diset.');
}

/// Jaringan gagal / timeout. Sebaiknya retry diam-diam di background.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

/// Kuota / rate limit provider habis. "Jembatan lagi tipis."
class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message, {super.cause, this.retryAfter});
  final Duration? retryAfter;
}

/// Respons provider tidak valid / tidak bisa diparse.
class ProviderFailure extends Failure {
  const ProviderFailure(super.message, {super.cause, this.statusCode});
  final int? statusCode;
}

/// Kegagalan penyimpanan lokal (DB/secure storage).
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}
