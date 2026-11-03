import 'package:dia_yang_kemarin/core/constitution/constitution.dart';
import 'package:flutter_test/flutter_test.dart';

/// Konstitusi (Lapis 1) harus selalu utuh & tidak bisa kosong. Ini fondasi
/// keamanan karakter — diuji sebagai test wajib (spec §14).
void main() {
  group('Constitution', () {
    final block = Constitution.systemBlock();

    test('selalu memuat aturan inti', () {
      expect(block, isNotEmpty);
      expect(block.toLowerCase(), contains('jujur soal keberadaan'));
      expect(block.toLowerCase(), contains('crisis override'));
      expect(block.toLowerCase(), contains('romantis'));
    });

    test('menegakkan gaya anti-asisten', () {
      final lower = block.toLowerCase();
      expect(lower, contains('bukan asisten'));
      expect(lower, contains('whatsapp'));
    });

    test('memuat larangan memancing ketergantungan', () {
      expect(block.toLowerCase(), contains('kok baru chat sekarang'));
    });
  });
}
