import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ml_service.dart';
import 'main_page.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class ChiliAnalysisPage extends StatefulWidget {
  final Map<String, double> soilParameters;
  final Map<String, dynamic>? initialAnalysisData; // Tambahkan parameter ini
  final bool initialLoading; // Tambahkan parameter ini
  final String? initialError; // Tambahkan parameter ini
  
  const ChiliAnalysisPage({
    Key? key,
    required this.soilParameters,
    this.initialAnalysisData,
    this.initialLoading = false,
    this.initialError,
  }) : super(key: key);

  @override
  State<ChiliAnalysisPage> createState() => _ChiliAnalysisPageState();
}

class _ChiliAnalysisPageState extends State<ChiliAnalysisPage> 
    with AutomaticKeepAliveClientMixin { // Tambahkan mixin ini
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _analysisData = {};
  
  @override
  bool get wantKeepAlive => true; // Pertahankan state widget


  @override
  void initState() {
    super.initState();
    
    // Use initial data when available
    if (widget.initialAnalysisData != null) {
      _analysisData = widget.initialAnalysisData!;
      _isLoading = widget.initialLoading;
      _errorMessage = widget.initialError;
    } 
    // Only fetch if there's no data but we have soil parameters
    else if (widget.soilParameters.isNotEmpty && _analysisData.isEmpty) {
      _fetchChiliAnalysis();
    }
  }
  
  Future<void> _fetchChiliAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final openRouterService = OpenRouterService(
        apiKey: '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'
      );
      
      // Create the prompt for chili-specific analysis
      final soilDataString = widget.soilParameters.entries
          .map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}')
          .join(', ');
      
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
          _analysisData = jsonDecode(jsonContent!);
        } else {
          throw Exception('Failed to extract JSON from the response');
        }
      } else {
        throw Exception('API request failed: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're directly navigated to this page or part of the MainPage tabs
    final bool isDirectNavigation = ModalRoute.of(context)?.settings.name == '/chili_analysis';

    Widget body = _buildBody();

    // If directly navigated, wrap with Scaffold
    if (isDirectNavigation) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A2D3E),
          centerTitle: true,
          title: Text(
            'Analisis Cabai',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: body,
      );
    }

    // If part of the MainPage tabs, just return the body
    return body;
  }

  Widget _buildBody() {
    if (widget.soilParameters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 64),
            const SizedBox(height: 16),
            Text(
              'Data Tanah Belum Ada',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Silakan input data tanah pada halaman analisis terlebih dahulu',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Menganalisis tanah untuk tanaman cabai...',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Start loading locally
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                
                // If we're part of MainPage, use that to handle the update
                if (context.findAncestorStateOfType<MainPageState>() != null) {
                  context.findAncestorStateOfType<MainPageState>()!.fetchChiliData();
                } else {
                  // Direct fetch if used standalone
                  _fetchChiliAnalysis();
                }
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'Analisis Ulang',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_analysisData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 64),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Analisis',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Terjadi kesalahan saat menganalisis data',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchChiliAnalysis,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Analisis Ulang',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with soil parameters
          _buildSoilParametersCard(),
          const SizedBox(height: 24),

          // Soil Analysis
          if (_analysisData.containsKey('soil_analysis'))
            _buildSoilAnalysisCard(),
          const SizedBox(height: 16),

          // Optimization
          if (_analysisData.containsKey('optimization'))
            _buildOptimizationCard(),
          const SizedBox(height: 16),

          // Care Guide
          if (_analysisData.containsKey('care_guide'))
            _buildCareGuideCard(),
          const SizedBox(height: 16),

          // Harvest Projection
          if (_analysisData.containsKey('harvest_projection'))
            _buildHarvestProjectionCard(),
          const SizedBox(height: 16),

          // Varieties Recommendation
          if (_analysisData.containsKey('varieties_recommendation'))
            _buildVarietiesRecommendationCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSoilParametersCard() {
    return Card(
      color: const Color(0xFF2A2D3E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/chili.png',
                  height: 32,
                  width: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.local_fire_department,
                      color: Colors.red,
                      size: 32,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Analisis Mendalam Tanaman Cabai',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Parameter Tanah',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12.0,
              runSpacing: 8.0,
              children: widget.soilParameters.entries.map((entry) {
                Color paramColor;
                switch (entry.key) {
                  case 'Nitrogen':
                    paramColor = Colors.green;
                    break;
                  case 'Phosphorus':
                    paramColor = Colors.orange;
                    break;
                  case 'Potassium':
                    paramColor = Colors.purple;
                    break;
                  case 'pH':
                    paramColor = Colors.red;
                    break;
                  case 'EC':
                    paramColor = Colors.teal;
                    break;
                  case 'Temperature':
                    paramColor = Colors.amber;
                    break;
                  case 'Humidity':
                    paramColor = Colors.lightBlue;
                    break;
                  default:
                    paramColor = Colors.grey;
                }

                String unit = '';
                if (entry.key == 'Temperature') {
                  unit = '°C';
                } else if (entry.key == 'Humidity' ||
                    entry.key == 'Nitrogen' ||
                    entry.key == 'Phosphorus' ||
                    entry.key == 'Potassium') {
                  unit = '%';
                } else if (entry.key == 'EC') {
                  unit = 'mS/cm';
                }

                return Chip(
                  backgroundColor: paramColor.withOpacity(0.2),
                  label: Text(
                    '${entry.key}: ${entry.value.toStringAsFixed(2)}$unit',
                    style: TextStyle(
                      color: paramColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: paramColor,
                    radius: 12,
                    child: Text(
                      entry.key[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilAnalysisCard() {
    final soilAnalysis = _analysisData['soil_analysis'];
    final compatibilityScore = soilAnalysis['compatibility_score'] ?? 0;
    
    return Card(
      color: const Color(0xFF2A2D3E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Analisis Tanah',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(compatibilityScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$compatibilityScore%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              soilAnalysis['summary'] ?? 'Tidak ada ringkasan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Strengths
            if (soilAnalysis.containsKey('strengths') && soilAnalysis['strengths'] is List) ...[
              Text(
                'Kelebihan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (soilAnalysis['strengths'] as List).map<Widget>((strength) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strength.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // Weaknesses
            if (soilAnalysis.containsKey('weaknesses') && soilAnalysis['weaknesses'] is List) ...[
              Text(
                'Kekurangan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (soilAnalysis['weaknesses'] as List).map<Widget>((weakness) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            weakness.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationCard() {
    final optimization = _analysisData['optimization'];
    
    return Card(
      color: const Color(0xFF2A2D3E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Optimalisasi Tanah',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // pH Adjustment
            if (optimization.containsKey('ph_adjustment')) ...[
              Text(
                'Penyesuaian pH',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                optimization['ph_adjustment'] ?? 'Tidak ada rekomendasi penyesuaian pH',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Nutrient Recommendations
            if (optimization.containsKey('nutrient_recommendations') && 
                optimization['nutrient_recommendations'] is List &&
                (optimization['nutrient_recommendations'] as List).isNotEmpty) ...[
              Text(
                'Rekomendasi Nutrisi',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (optimization['nutrient_recommendations'] as List).length,
                itemBuilder: (context, index) {
                  final nutrient = (optimization['nutrient_recommendations'] as List)[index];
                  return Card(
                    color: const Color(0xFF3A3D4E),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nutrient['nutrient'] ?? 'Nutrisi',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Level Saat Ini: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                nutrient['current_level'] ?? 'Tidak diketahui',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Level Ideal: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                nutrient['ideal_level'] ?? 'Tidak diketahui',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tindakan: ${nutrient['action'] ?? 'Tidak ada tindakan yang direkomendasikan'}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Soil Preparation
            if (optimization.containsKey('soil_preparation')) ...[
              Text(
                'Persiapan Tanah',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                optimization['soil_preparation'] ?? 'Tidak ada informasi persiapan tanah',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCareGuideCard() {
    final careGuide = _analysisData['care_guide'];
    
    return Card(
      color: const Color(0xFF2A2D3E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Panduan Perawatan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Watering
            if (careGuide.containsKey('watering')) ...[
              _buildCareSection(
                'Penyiraman',
                careGuide['watering'] ?? 'Tidak ada informasi penyiraman',
                Icons.water_drop,
                Colors.blue,
              ),
              const SizedBox(height: 16),
            ],
            
            // Fertilization
            if (careGuide.containsKey('fertilization')) ...[
              _buildCareSection(
                'Pemupukan',
                careGuide['fertilization'] ?? 'Tidak ada informasi pemupukan',
                Icons.grass,
                Colors.green,
              ),
              const SizedBox(height: 16),
            ],
            
            // Pest Prevention
            if (careGuide.containsKey('pest_prevention')) ...[
              _buildCareSection(
                'Pencegahan Hama',
                careGuide['pest_prevention'] ?? 'Tidak ada informasi pencegahan hama',
                Icons.bug_report,
                Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCareSection(String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHarvestProjectionCard() {
    final harvestProjection = _analysisData['harvest_projection'];
    
    return Card(
      color: const Color(0xFF2A2D3E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color.fromARGB(255, 224, 195, 6), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Proyeksi Panen',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Expected Timeline
            if (harvestProjection.containsKey('expected_timeline')) ...[
              Text(
                'Estimasi Timeline',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 224, 195, 6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                harvestProjection['expected_timeline'] ?? 'Tidak ada informasi timeline',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Yield Estimation
            if (harvestProjection.containsKey('yield_estimation')) ...[
              Text(
                'Estimasi Hasil Panen',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 224, 195, 6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                harvestProjection['yield_estimation'] ?? 'Tidak ada informasi estimasi panen',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Quality Factors
            if (harvestProjection.containsKey('quality_factors') && 
                harvestProjection['quality_factors'] is List &&
                (harvestProjection['quality_factors'] as List).isNotEmpty) ...[
              Text(
                'Faktor Kualitas Panen',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 224, 195, 6),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (harvestProjection['quality_factors'] as List).map<Widget>((factor) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            factor.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVarietiesRecommendationCard() {
    final varietiesRecommendation = _analysisData['varieties_recommendation'];
    
    return Card(
      color: const Color(0xFF2A2D3E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grass, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Rekomendasi Varietas Cabai',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (varietiesRecommendation is List && varietiesRecommendation.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: varietiesRecommendation.length,
                itemBuilder: (context, index) {
                  final variety = varietiesRecommendation[index];
                  final suitabilityScore = variety['suitability_score'] ?? 0;
                  
                  return Card(
                    color: const Color(0xFF3A3D4E),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_florist, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  variety['name'] ?? 'Varietas tidak disebutkan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getScoreColor(suitabilityScore),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$suitabilityScore%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Alasan: ${variety['reason'] ?? 'Tidak ada informasi'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Text(
                'Tidak ada rekomendasi varietas cabai yang tersedia',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  
}