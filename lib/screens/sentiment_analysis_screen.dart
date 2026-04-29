import 'package:flutter/material.dart';

class SentimentAnalysisScreen extends StatefulWidget {
  const SentimentAnalysisScreen({super.key});

  @override
  State<SentimentAnalysisScreen> createState() => _SentimentAnalysisScreenState();
}

class _SentimentAnalysisScreenState extends State<SentimentAnalysisScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _resultLabel = "Belum ada analisis";
  Color _resultColor = Colors.grey;
  IconData _resultIcon = Icons.sentiment_neutral;

  // Kamus kata kunci sederhana (Simulasi Model ML)
  final List<String> _positiveWords = ['bagus', 'puas', 'mantap', 'keren', 'bersih', 'nyaman', 'rekomendasi', 'murah', 'ramah', 'juara'];
  final List<String> _negativeWords = ['jelek', 'kotor', 'mahal', 'kecewa', 'panas', 'rusak', 'kasar', 'lambat', 'buruk', 'nyesel'];

  void _analyzeSentiment() {
    String text = _inputController.text.toLowerCase();
    if (text.isEmpty) return;

    int score = 0;
    
    // Logika perhitungan skor
    for (var word in _positiveWords) {
      if (text.contains(word)) score++;
    }
    for (var word in _negativeWords) {
      if (text.contains(word)) score--;
    }

    setState(() {
      if (score > 0) {
        _resultLabel = "SENTIMEN POSITIF\n(User Puas)";
        _resultColor = Colors.green;
        _resultIcon = Icons.sentiment_very_satisfied;
      } else if (score < 0) {
        _resultLabel = "SENTIMEN NEGATIF\n(User Kecewa)";
        _resultColor = Colors.red;
        _resultIcon = Icons.sentiment_very_dissatisfied;
      } else {
        _resultLabel = "SENTIMEN NETRAL\n(Ulasan Standar)";
        _resultColor = Colors.orange;
        _resultIcon = Icons.sentiment_neutral;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Sentimen ML'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Analisis Kepuasan Pengguna",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Masukkan ulasan lapangan untuk mendeteksi emosi pengguna secara otomatis.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Input Field
            TextField(
              controller: _inputController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Contoh: Lapangannya bagus dan bersih banget, saya puas!",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.purple[50],
              ),
            ),
            const SizedBox(height: 20),
            
            // Tombol Analisis
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _analyzeSentiment,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text("MULAI ANALISIS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Hasil Analisis
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: _resultColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _resultColor, width: 2),
              ),
              child: Column(
                children: [
                  Icon(_resultIcon, size: 80, color: _resultColor),
                  const SizedBox(height: 15),
                  Text(
                    _resultLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _resultColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}