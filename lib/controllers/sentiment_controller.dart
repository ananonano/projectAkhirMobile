/// Mengelola logika analisis sentimen teks ulasan lapangan
class SentimentController {
  static const List<String> _positiveWords = [
    'bagus', 'puas', 'mantap', 'keren', 'bersih', 'nyaman',
    'rekomendasi', 'murah', 'ramah', 'juara', 'oke', 'suka',
    'senang', 'memuaskan', 'terbaik', 'luar biasa',
  ];

  static const List<String> _negativeWords = [
    'jelek', 'kotor', 'mahal', 'kecewa', 'panas', 'rusak',
    'kasar', 'lambat', 'buruk', 'nyesel', 'parah', 'bau',
    'sempit', 'gelap', 'bocor', 'mengecewakan',
  ];

  // Hasil analisis sentimen
  SentimentResult analyze(String text) {
    if (text.trim().isEmpty) {
      return SentimentResult(
        label: 'Belum ada analisis',
        type: SentimentType.neutral,
        score: 0,
      );
    }

    final lowerText = text.toLowerCase();
    int score = 0;

    for (final word in _positiveWords) {
      if (lowerText.contains(word)) score++;
    }
    for (final word in _negativeWords) {
      if (lowerText.contains(word)) score--;
    }

    if (score > 0) {
      return SentimentResult(
        label: 'SENTIMEN POSITIF\n(User Puas)',
        type: SentimentType.positive,
        score: score,
      );
    } else if (score < 0) {
      return SentimentResult(
        label: 'SENTIMEN NEGATIF\n(User Kecewa)',
        type: SentimentType.negative,
        score: score,
      );
    } else {
      return SentimentResult(
        label: 'SENTIMEN NETRAL\n(Ulasan Standar)',
        type: SentimentType.neutral,
        score: score,
      );
    }
  }
}

enum SentimentType { positive, negative, neutral }

class SentimentResult {
  final String label;
  final SentimentType type;
  final int score;

  const SentimentResult({
    required this.label,
    required this.type,
    required this.score,
  });
}
