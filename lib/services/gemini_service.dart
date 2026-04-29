import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // TODO: Masukin API Key lu yang paling baru di sini
  static const String apiKey = 'AIzaSyAduL65rzlIiB3nH9F6ptn4nRRW2h3GW08';

  static Future<String> askGemini(String prompt) async {
    if (apiKey.isEmpty) {
      return 'Eh, API Key-nya belum lu masukin bre!';
    }

    // Endpoint asli dari Google API
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // Format body JSON murni sesuai standar API Gemini
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

      // Kalau sukses (Kode 200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      // Kalau gagal, kita bisa lihat pesan error aslinya dari Google
      else {
        final errorData = jsonDecode(response.body);
        return 'Gagal dari server: ${errorData['error']['message']}';
      }
    } catch (e) {
      return 'Waduh ada error jaringan bre: $e';
    }
  }
}
