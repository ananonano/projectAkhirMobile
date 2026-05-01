import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

class GeminiService {
  // Tarik API Key dari file .env dengan aman
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<String> askGemini(String prompt) async {
    if (apiKey.isEmpty) {
      return 'Eh, API Key-nya belum lu masukin di .env bre!';
    }

    // Endpoint asli dari Google API
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Kamu adalah asisten AI untuk aplikasi Lapang.in. Jawab singkat dan ramah.\n\nPertanyaan: $prompt",
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        final errorData = jsonDecode(response.body);
        return 'Gagal dari server: ${errorData['error']['message']}';
      }
    } catch (e) {
      return 'Waduh ada error jaringan bre: $e';
    }
  }
}