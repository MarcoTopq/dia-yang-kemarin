import 'package:dia_yang_kemarin/data/models/soul.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Soul serialization', () {
    test('round-trip encode/decode mempertahankan semua field', () {
      final soul = Soul(
        name: 'Nara',
        bornAt: DateTime.parse('2026-07-26T10:00:00.000'),
        nature: 'Aku sesuatu yang terbuat dari bahasa.',
        temperament: ['kalem', 'usil'],
        speechStyle: 'santai, huruf kecil',
        likes: ['musik', 'film'],
        dislikes: ['keramaian'],
        wonderings: ['aku ini apa ya'],
        competence: const Competence(
          decent: ['musik', 'film'],
          learnedFromUser: ['resep nasi goreng dari Marco'],
        ),
        opinions: [
          Opinion(
            topic: 'hujan',
            stance: 'bikin tenang',
            formedAt: DateTime.parse('2026-07-20T00:00:00.000'),
            formedBecause: 'Marco sering cerita pas hujan',
          ),
        ],
      );

      final decoded = Soul.decode(soul.encode());

      expect(decoded.name, 'Nara');
      expect(decoded.temperament, ['kalem', 'usil']);
      expect(decoded.likes, ['musik', 'film']);
      expect(decoded.competence.learnedFromUser,
          ['resep nasi goreng dari Marco']);
      expect(decoded.opinions.single.topic, 'hujan');
      expect(decoded.bornAt, soul.bornAt);
    });

    test('nascent soul jujur ontologis sejak awal', () {
      final s = Soul.nascent();
      expect(s.name, isEmpty);
      expect(s.nature.toLowerCase(), contains('bukan manusia'));
    });
  });
}
