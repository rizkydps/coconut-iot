import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiKey;
  final String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  OpenRouterService({required this.apiKey});

  Future<Map<String, dynamic>> getPlantRecommendations(Map<String, dynamic> soilData) async {
  try {
    // Prepare the soil data for the prompt
    String soilDataString = soilData.entries
        .map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}')
        .join(', ');

    // Create the prompt
    String prompt = '''
      Berdasarkan parameter tanah berikut, rekomendasikan tanaman yang cocok dan dapat tumbuh dengan baik:
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

    // Prepare the API request
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': '', // Optional. Site URL for rankings on openrouter.ai.
        'X-Title': '', // Optional. Site title for rankings on openrouter.ai.
      },
      body: jsonEncode({
        'model': 'deepseek/deepseek-r1:free', // or whichever model you prefer
        'messages': [
          {'role': 'system', 'content': 'You are a plant and agriculture expert.'},
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      print('Raw API Response: ${response.body}'); // Log the raw response
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['choices'][0]['message']['content'];

      // Extract the JSON part from the response
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
    throw Exception('Kami tidak dapat memberikan rekomendasi tanaman saat ini. Silakan coba lagi nanti.  $e');
  }
}
}