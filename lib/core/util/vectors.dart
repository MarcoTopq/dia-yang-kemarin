import 'dart:math';

/// Utilitas vektor untuk recall lokal. Cosine similarity manual — cukup cepat
/// untuk <50k memori tanpa index vektor khusus.
class Vectors {
  const Vectors._();

  /// Cosine similarity dua vektor. 0 jika dimensi beda / salah satu kosong.
  static double cosine(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;
    var dot = 0.0, na = 0.0, nb = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (sqrt(na) * sqrt(nb));
  }
}
