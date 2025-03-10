import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({Key? key}) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  // Data contoh untuk hasil prediksi dan rekomendasi
  final Map<String, dynamic> _predictionResult = {
    'harvestDate': 'April 15, 2025',
    'predictedYield': 85.2, // dalam persen dari hasil maksimal
    'healthStatus': 'Baik',
    'threatLevel': 'Rendah',
    'recommendations': [
      {
        'title': 'Pemupukan',
        'description': 'Tambahkan pupuk NPK dengan rasio 10-5-10 sebanyak 50kg/ha',
        'priority': 'Tinggi'
      },
      {
        'title': 'Pengairan',
        'description': 'Pertahankan kelembaban tanah antara 60-70%',
        'priority': 'Sedang'
      },
      {
        'title': 'Kontrol Hama',
        'description': 'Periksa adanya serangan kutu dan serangga pemakan daun',
        'priority': 'Rendah'
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prediction Summary Card
                Card(
                  color: const Color(0xFF2A2D3E),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Ringkasan Prediksi',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Yield Indicator
                        SizedBox(
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: CircularProgressIndicator(
                                  value: _predictionResult['predictedYield'] / 100,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey.shade800,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getYieldColor(_predictionResult['predictedYield']),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_predictionResult['predictedYield']}%',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: _getYieldColor(_predictionResult['predictedYield']),
                                    ),
                                  ),
                                  Text(
                                    'Hasil Prediksi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Prediction Details
                        _buildDetailRow('Status Tanaman', _predictionResult['healthStatus'], 
                          _getHealthColor(_predictionResult['healthStatus'])),
                        const SizedBox(height: 8),
                        _buildDetailRow('Tanggal Panen', _predictionResult['harvestDate'], Colors.white),
                        const SizedBox(height: 8),
                        _buildDetailRow('Level Ancaman', _predictionResult['threatLevel'], 
                          _getThreatColor(_predictionResult['threatLevel'])),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Recommendations Section
                Text(
                  'Rekomendasi',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Recommendations List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _predictionResult['recommendations'].length,
                  itemBuilder: (context, index) {
                    final item = _predictionResult['recommendations'][index];
                    return Card(
                      color: const Color(0xFF2A2D3E),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(item['priority']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getPriorityIcon(item['priority']),
                                color: _getPriorityColor(item['priority']),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(item['priority']).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          item['priority'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _getPriorityColor(item['priority']),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['description'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                // Last updated section
                Center(
                  child: Text(
                    'Last updated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                // Add extra padding at the bottom to prevent content from being hidden by navigation bar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for styling
  Color _getYieldColor(double yield) {
    if (yield >= 80) {
      return Colors.green;
    } else if (yield >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getHealthColor(String healthStatus) {
    switch (healthStatus) {
      case 'Baik':
        return Colors.green;
      case 'Sedang':
        return Colors.orange;
      case 'Buruk':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  Color _getThreatColor(String threatLevel) {
    switch (threatLevel) {
      case 'Rendah':
        return Colors.green;
      case 'Sedang':
        return Colors.orange;
      case 'Tinggi':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Tinggi':
        return Colors.red;
      case 'Sedang':
        return Colors.orange;
      case 'Rendah':
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Tinggi':
        return Icons.warning;
      case 'Sedang':
        return Icons.info;
      case 'Rendah':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}