import 'package:flutter/material.dart';
import '../controllers/sentiment_controller.dart';
import '../theme/app_theme.dart';

class SentimentAnalysisScreen extends StatefulWidget {
  const SentimentAnalysisScreen({super.key});

  @override
  State<SentimentAnalysisScreen> createState() => _SentimentAnalysisScreenState();
}

class _SentimentAnalysisScreenState extends State<SentimentAnalysisScreen> {
  final _inputController = TextEditingController();
  final _controller = SentimentController();
  SentimentResult? _result;

  void _analyzeSentiment() {
    final text = _inputController.text;
    if (text.isEmpty) return;
    setState(() => _result = _controller.analyze(text));
  }

  Color get _resultColor {
    if (_result == null) return AppColors.textSecondary;
    switch (_result!.type) {
      case SentimentType.positive: return AppColors.success;
      case SentimentType.negative: return Colors.red;
      case SentimentType.neutral: return Colors.orange;
    }
  }

  IconData get _resultIcon {
    if (_result == null) return Icons.sentiment_neutral_rounded;
    switch (_result!.type) {
      case SentimentType.positive: return Icons.sentiment_very_satisfied_rounded;
      case SentimentType.negative: return Icons.sentiment_very_dissatisfied_rounded;
      case SentimentType.neutral: return Icons.sentiment_neutral_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analisis Sentimen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Analisis Kepuasan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(height: 3),
                        Text('Deteksi sentimen ulasan lapangan secara otomatis', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Masukkan Ulasan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            TextField(
              controller: _inputController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Contoh: Lapangannya bagus dan bersih banget, saya puas!',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _analyzeSentiment,
                icon: const Icon(Icons.search_rounded, size: 20),
                label: const Text('Analisis Sekarang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),

            const SizedBox(height: 28),

            // Result
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _resultColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _resultColor.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(_resultIcon, size: 72, color: _resultColor),
                  const SizedBox(height: 14),
                  Text(
                    _result?.label ?? 'Belum ada analisis',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _resultColor, height: 1.4),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Skor: ${_result!.score > 0 ? '+' : ''}${_result!.score}',
                      style: TextStyle(color: _resultColor.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
