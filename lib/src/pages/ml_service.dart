import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiKey;
  final String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  OpenRouterService({required this.apiKey});

  Future<Map<String, dynamic>> getPlantRecommendations(Map<String, dynamic> soilData) async {
    try {
      // Existing implementation remains the same
      String soilDataString = soilData.entries
          .map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}')
          .join(', ');

      String prompt = '''
      Berdasarkan parameter tanah berikut, rekomendasikan tanaman yang paling cocok dan dapat tumbuh dengan baik:
      $soilDataString
      Berikan respons JSON dengan struktur berikut:
      {
        "recommendations": [
          {
            "plant_name": "Nama Tanaman",
            "description": "Deskripsi singkat tentang tanaman",
            "compatibility_score": 85,
            "reasons": "Mengapa tanaman ini cocok untuk parameter tanah yang diberikan",
            "care_tips": "Tips perawatan dasar untuk tanaman ini"
          }
        ]
      }
      Berikan setidaknya 10 rekomendasi tanaman dengan skor kompatibilitas antara 0-100.
      ''';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': '',
          'X-Title': '',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-chat-v3-0324:free',
          'messages': [
            {'role': 'system', 'content': 'You are a plant and agriculture expert.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        print('Raw API Response: ${response.body}');
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];

        final jsonMatch = RegExp(r'{[\s\S]*}').firstMatch(content);
        if (jsonMatch != null) {
          final jsonContent = jsonMatch.group(0);
          return jsonDecode(jsonContent!);
        } else {
          throw Exception('Gagal mendapatkan data rekomendasi. Silakan coba lagi.');
        }
      } else {
        throw Exception('API request failed: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error getting plant recommendations: $e');
      throw Exception('Kami tidak dapat memberikan rekomendasi tanaman saat ini. Silakan coba lagi nanti. $e');
    }
  }

  Future<Map<String, dynamic>> getSpecificPlantRecommendation(
      String plantName,
      Map<String, dynamic> soilData,
      ) async {
    try {
      // Prepare the soil data for the prompt
      String soilDataString = soilData.entries
          .map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}')
          .join(', ');

      // Create the prompt
      String prompt = '''
    Saya ingin menanam $plantName. Berdasarkan parameter tanah berikut:
    $soilDataString
    
    Bagaimana kompatibilitas tanaman ini dengan kondisi tanah saya?
    Berikan analisis detail dan tips perawatan khusus untuk tanaman ini dalam kondisi tanah saya.
    
    Berikan respons JSON dengan struktur berikut:
    {
      "recommendations": [
        {
          "plant_name": "$plantName",
          "description": "Deskripsi singkat tentang tanaman",
          "compatibility_score": 85,
          "reasons": "Analisis kompatibilitas dengan parameter tanah yang diberikan",
          "care_tips": "Tips perawatan khusus untuk tanaman ini dalam kondisi tanah Anda",
          
        }
      ]
    }
    Berikan 2 tanaman lain sejenis yang memiliki compatibility score lebih baik
    Pastikan untuk menghasilkan respons JSON yang valid.
    ''';

      // Prepare the API request
      // "image_url": "URL gambar tanaman (opsional)"
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': '',
          'X-Title': '',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-chat-v3-0324:free',
          'messages': [
            {'role': 'system', 'content': 'You are a plant and agriculture expert. Always respond with a valid JSON structure.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];

        // Print the raw content for debugging
        print('Raw Specific Plant Recommendation: $content');

        // More robust JSON extraction
        final jsonPatterns = [
          r'```json\s*(\{[\s\S]*?\})\s*```',  // Markdown code block
          r'\{[^{}]*"recommendations":[^{}]*\}',  // JSON-like structure
          r'(\{(?:[^{}]|(?R))*\})',  // Nested JSON
        ];

        for (var pattern in jsonPatterns) {
          final jsonMatch = RegExp(pattern, multiLine: true, dotAll: true).firstMatch(content);

          if (jsonMatch != null) {
            try {
              // Try extracting and parsing JSON
              final jsonContent = jsonMatch.group(1) ?? jsonMatch.group(0);
              if (jsonContent != null) {
                // Explicitly convert to Map<String, dynamic>
                final parsedJson = Map<String, dynamic>.from(jsonDecode(jsonContent));

                // Validate the parsed JSON structure
                if (parsedJson.containsKey('recommendations') &&
                    parsedJson['recommendations'] is List) {
                  return parsedJson;
                }
              }
            } catch (parseError) {
              print('JSON Parsing Attempt Failed: $parseError');
              continue;  // Try next pattern
            }
          }
        }

        // If no valid JSON found
        throw Exception('Tidak dapat menemukan struktur JSON yang valid dalam respons.');
      } else {
        throw Exception('Permintaan API gagal: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error mendapatkan analisis tanaman: $e');
      throw Exception('Kami tidak dapat menganalisis tanaman saat ini. Silakan coba lagi nanti. $e');
    }
  }
}