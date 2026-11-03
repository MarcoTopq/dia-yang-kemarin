import 'package:dia_yang_kemarin/core/util/vectors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vectors.cosine', () {
    test('identical vectors -> 1.0', () {
      expect(Vectors.cosine([1, 2, 3], [1, 2, 3]), closeTo(1.0, 1e-9));
    });

    test('orthogonal vectors -> 0.0', () {
      expect(Vectors.cosine([1, 0], [0, 1]), closeTo(0.0, 1e-9));
    });

    test('opposite vectors -> -1.0', () {
      expect(Vectors.cosine([1, 1], [-1, -1]), closeTo(-1.0, 1e-9));
    });

    test('empty or mismatched dims -> 0.0', () {
      expect(Vectors.cosine([], [1, 2]), 0.0);
      expect(Vectors.cosine([1, 2, 3], [1, 2]), 0.0);
    });

    test('zero vector -> 0.0 (no NaN)', () {
      expect(Vectors.cosine([0, 0], [1, 1]), 0.0);
    });
  });
}
