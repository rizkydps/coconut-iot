import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'analysis_page.dart';
import 'chili_analysis_page.dart';
import 'result_page.dart';
import 'ml_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  String _currentTime = '';
  late Timer _timer;

  // State variables for managing recommendations and soil parameters
  List<PlantRecommendationResult> _recommendations = [];
  Map<String, double> _soilParameters = {};
  bool _isLoading = false;
  bool _isButtonClicked = false;
  String? _errorMessage;
  
  // State variables for chili analysis
  Map<String, dynamic> _chiliAnalysisData = {};
  bool _isChiliAnalysisLoading = false;
  String? _chiliAnalysisError;

  // Declare the pages list but initialize it later
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());

    // Initialize _pages in initState
    _pages = [
      const HomePage(),
      const AnalyzePage(),
      ResultPage(
        initialRecommendations: _recommendations,
        soilParameters: _soilParameters,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        isButtonClicked: _isButtonClicked,
      ),
      ChiliAnalysisPage(
        soilParameters: _soilParameters,
        initialAnalysisData: _chiliAnalysisData,
        initialLoading: _isChiliAnalysisLoading,
        initialError: _chiliAnalysisError,
      ),
    ];
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // In MainPage class, update updateResultsPage method
void updateResultsPage({
  required List<PlantRecommendationResult> recommendations,
  required Map<String, double> soilParameters,
  Map<String, dynamic>? chiliAnalysisData,
  bool isLoading = false,
  bool isChiliAnalysisLoading = false,
  String? errorMessage,
  String? chiliAnalysisError,
  bool isButtonClicked = false,
  }) {
    setState(() {
      _recommendations = recommendations;
      _soilParameters = soilParameters;
      if (chiliAnalysisData != null) {
        _chiliAnalysisData = chiliAnalysisData;
      }
      _isLoading = isLoading;
      _isChiliAnalysisLoading = isChiliAnalysisLoading;
      _errorMessage = errorMessage;
      _chiliAnalysisError = chiliAnalysisError;
      _isButtonClicked = isButtonClicked;

      // Update pages
      _updatePages();
      
      // If we have soil parameters but no chili analysis data, fetch it
      if (soilParameters.isNotEmpty && _chiliAnalysisData.isEmpty && !_isChiliAnalysisLoading) {
        fetchChiliData();
      }
    });
  }

  // Add a helper method to update pages
  void _updatePages() {
    _pages = [
      const HomePage(),
      const AnalyzePage(),
      ResultPage(
        initialRecommendations: _recommendations,
        soilParameters: _soilParameters,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        isButtonClicked: _isButtonClicked,
      ),
      ChiliAnalysisPage(
        soilParameters: _soilParameters,
        initialAnalysisData: _chiliAnalysisData,
        initialLoading: _isChiliAnalysisLoading,
        initialError: _chiliAnalysisError,
      ),
    ];
  }

  void updateChiliAnalysis({
    Map<String, dynamic>? analysisData,
    bool isLoading = false,
    String? error,
  }) {
    setState(() {
      if (analysisData != null) {
        _chiliAnalysisData = analysisData;
      }
      _isChiliAnalysisLoading = isLoading;
      _chiliAnalysisError = error;
      
      // Update the ChiliAnalysisPage
      _pages[3] = ChiliAnalysisPage(
        soilParameters: _soilParameters,
        initialAnalysisData: _chiliAnalysisData,
        initialLoading: _isChiliAnalysisLoading,
        initialError: _chiliAnalysisError,
      );
    });
  }

  void navigateToResultPage() {
    // Navigate to the ResultPage tab by changing _selectedIndex
    setState(() {
      _selectedIndex = 2; // Assuming ResultPage is the third tab (index 2)
    });
  }

  void navigateToChiliAnalysisPage() {
    // Navigate to the ChiliAnalysisPage tab
    setState(() {
      _selectedIndex = 3;
    });
  }

  Future<void> fetchChiliData() async {
  if (_soilParameters.isEmpty) return; // Avoid fetching if soil data is empty

  updateChiliAnalysis(isLoading: true, error: null);

  try {
    final openRouterService = OpenRouterService(
      apiKey: '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'
    );
    
    // Format soil data for the prompt
    final soilDataString = _soilParameters.entries
        .map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}')
        .join(', ');
    
    // Create the prompt for chili-specific analysis (same as in ChiliAnalysisPage)
    final String prompt = '''
    Berdasarkan parameter tanah berikut: $soilDataString
    
    Buatkan analisis mendalam khusus untuk tanaman CABAI dengan struktur JSON berikut:
    {
      "soil_analysis": {
        "summary": "Ringkasan singkat tentang kondisi tanah saat ini untuk cabai",
        "compatibility_score": 0-100,
        "strengths": ["Kelebihan tanah untuk cabai", "..."],
        "weaknesses": ["Kekurangan tanah untuk cabai", "..."]
      },
      "optimization": {
        "ph_adjustment": "Cara menyesuaikan pH tanah untuk cabai",
        "nutrient_recommendations": [
          {"nutrient": "Nama nutrisi", "current_level": "Level saat ini", "ideal_level": "Level ideal", "action": "Tindakan yang direkomendasikan"}
        ],
        "soil_preparation": "Langkah-langkah persiapan tanah untuk cabai"
      },
      "care_guide": {
        "watering": "Rekomendasi penyiraman berdasarkan kondisi tanah",
        "fertilization": "Jadwal dan jenis pupuk yang direkomendasikan",
        "pest_prevention": "Strategi pencegahan hama berdasarkan kondisi tanah"
      },
      "harvest_projection": {
        "expected_timeline": "Estimasi timeline panen",
        "yield_estimation": "Estimasi hasil panen berdasarkan kondisi tanah",
        "quality_factors": ["Faktor yang mempengaruhi kualitas cabai", "..."]
      },
      "varieties_recommendation": [
        {"name": "Nama varietas cabai", "suitability_score": 0-100, "reason": "Alasan kesesuaian"}
      ]
    }
    
    Pastikan:
    1. Analisis didasarkan pada ilmu pertanian yang valid
    2. Rekomendasi spesifik untuk tanaman cabai di iklim tropis Indonesia
    3. Tindakan praktis yang bisa dilakukan petani
    4. Pertimbangkan semua parameter tanah yang tersedia
    5. Sertakan minimal 3 varietas cabai yang cocok untuk kondisi tanah ini
    ''';

    // Make direct API call to OpenRouter just like in ChiliAnalysisPage
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer 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',
        'HTTP-Referer': '',
        'X-Title': '',
      },
      body: jsonEncode({
        'model': 'deepseek/deepseek-chat-v3-0324:free',
        'messages': [
          {'role': 'system', 'content': 'You are an expert agricultural analyst specialized in chili cultivation.'},
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['choices'][0]['message']['content'];
      
      // Extract JSON from the response
      final jsonMatch = RegExp(r'{[\s\S]*}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonContent = jsonMatch.group(0);
        final analysisData = jsonDecode(jsonContent!);
        
        updateChiliAnalysis(
          analysisData: analysisData,
          isLoading: false,
        );
      } else {
        throw Exception('Failed to extract JSON from the response');
      }
    } else {
      throw Exception('API request failed: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    updateChiliAnalysis(
      isLoading: false,
      error: 'Gagal memuat analisis: ${e.toString()}',
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2D3E),
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/big-logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.eco, color: Colors.green, size: 40);
              },
            ),
            const SizedBox(width: 10),
            Text(
              'COCONUT',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _currentTime,
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _pages[_selectedIndex], // Display the selected page
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D3E),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home, 'Home'),
              _buildNavItem(1, Icons.analytics, 'Analisis'),
              _buildNavItem(2, Icons.assignment, 'Rekomendasi'),
              _buildNavItem(3, Icons.local_fire_department, 'Cabai'), 
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build navigation items
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withAlpha((0.3 * 255).toInt()) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}