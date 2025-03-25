import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'analysis_page.dart';


class PlantRecommendationResult {
  final String plantName;
  final String description;
  final int compatibilityScore;
  final String reasons;
  final String careTips;
  final String? imageUrl; // Optional image URL

  PlantRecommendationResult({
    required this.plantName,
    required this.description,
    required this.compatibilityScore,
    required this.reasons,
    required this.careTips,
    this.imageUrl,
  });

  factory PlantRecommendationResult.fromJson(Map<String, dynamic> json) {
    return PlantRecommendationResult(
      plantName: json['plant_name'] ?? 'Unknown Plant',
      description: json['description'] ?? 'No description available',
      compatibilityScore: json['compatibility_score'] ?? 0,
      reasons: json['reasons'] ?? 'No compatibility information available',
      careTips: json['care_tips'] ?? 'No care tips available',
      imageUrl: json['image_url'],
    );
  }
}

class ResultPage extends StatelessWidget {
  final List<PlantRecommendationResult> recommendations;
  final Map<String, double> soilParameters;
  final bool isLoading;
  final String? errorMessage;
  final bool isButtonClicked;

  const ResultPage({
    Key? key,
    required this.recommendations,
    required this.soilParameters,
    this.isLoading = false,
    this.errorMessage,
    this.isButtonClicked = false,
  }) : super(key: key);



   @override
  Widget build(BuildContext context) {
    // Check if no data is available
    final bool noDataAvailable = recommendations.isEmpty && soilParameters.isEmpty;

    Widget body;

    if (!isButtonClicked) {
      // Jika tombol belum diklik
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 64),
            const SizedBox(height: 16),
            Text(
              'Data Belum Ada',
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
                'Silakan klik tombol "Analisis Data" pada halaman analysis',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else if (isLoading) {
      // Loading state (only when fetching data)
      body = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Menganalisis data tanah dan menghasilkan rekomendasi...',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (errorMessage != null) {
      // Error state
      body = Center(
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
                errorMessage!,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
              // ElevatedButton.icon(
              //   onPressed: () => Navigator.push(
              //     context,
              //     MaterialPageRoute(builder: (context) => const AnalyzePage()),
              //   ),
              //   icon: const Icon(Icons.analytics),
              //   label: const Text('Go to Analysis'),
              //   style: ElevatedButton.styleFrom(
              //     foregroundColor: Colors.white,
              //     backgroundColor: Colors.blue,
              //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              //   ),
              // ),

          ],
        ),
      );
    } else if (noDataAvailable) {
      // No data available state
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 64),
            const SizedBox(height: 16),
            Text(
              'Belum ada pengukuran tersimpan',
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
                'Tambahkan pengukuran baru pada halaman analysis',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else {
      // Data available state
      body = _buildResultsView(context);
    }

    // Check if we're directly navigated to this page or part of the MainPage tabs
    final bool isDirectNavigation = ModalRoute.of(context)?.settings.name == '/result';

    // If directly navigated, wrap with Scaffold
    if (isDirectNavigation) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A2D3E),
          centerTitle: true,
          title: Text(
            'Rekomendasi Tanaman',
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

  Widget _buildResultsView(BuildContext context) {
    return SingleChildScrollView(
      child: Padding( 
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Soil Parameters Summary
            Card(
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
                        const Icon(
                          Icons.landscape,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hasil Analisis Tanah',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 8.0,
                      children: soilParameters.entries.map((entry) {
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
                                 entry.key == 'Potassium') unit = '%';
                        else if (entry.key == 'EC') unit = 'mS/cm';

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
            ),
            const SizedBox(height: 24),
            
            // Recommendations Title
            Row(
              children: [
                const Icon(
                  Icons.eco,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rekomendasi Tanaman',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Berdasarkan analisis tanah Anda, tanaman berikut paling cocok:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            
            // Plant Recommendations
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return Card(
                  color: const Color(0xFF2A2D3E),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(16),
                    childrenPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            recommendation.plantName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
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
                            color: _getScoreColor(recommendation.compatibilityScore),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${recommendation.compatibilityScore}%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        recommendation.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    children: [
                      if (recommendation.imageUrl != null)
                        Image.network(
                          recommendation.imageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey.shade800,
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey.shade400,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      _buildInfoSection(
                        'Alasan Kompatibilitas',
                        recommendation.reasons,
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        'Tips Perawatan',
                        recommendation.careTips,
                        Icons.tips_and_updates,
                        Colors.amber,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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


  
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}