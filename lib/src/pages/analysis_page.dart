import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // Data contoh untuk analisis tanah
  final List<Map<String, dynamic>> _analysisData = [
    {
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'nitrogen': 50.2,
      'phosphorus': 25.7,
      'potassium': 70.3,
      'ph': 6.8,
      'status': 'Optimal',
      'recommendation': 'Pertahankan kondisi tanah saat ini.'
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'nitrogen': 46.5,
      'phosphorus': 24.1,
      'potassium': 68.9,
      'ph': 6.6,
      'status': 'Good',
      'recommendation': 'Tambahkan sedikit pupuk potasium untuk hasil yang lebih baik.'
    },
    {
      'date': DateTime.now(),
      'nitrogen': 45.8,
      'phosphorus': 23.4,
      'potassium': 67.2,
      'ph': 6.5,
      'status': 'Good',
      'recommendation': 'Tambahkan pupuk NPK dengan rasio 10:5:10 untuk meningkatkan kandungan nitrogen.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2D3E),
        elevation: 0,
        title: Text(
          'Analisis Tanah',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
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
                        Text(
                          'Ringkasan Analisis',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryItem(
                          'Status Tanah', 
                          _analysisData.last['status'], 
                          _getStatusColor(_analysisData.last['status'])
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryItem(
                          'Rekomendasi', 
                          _analysisData.last['recommendation'], 
                          Colors.white70
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Analysis History Title
                Text(
                  'Riwayat Analisis',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Analysis History List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _analysisData.length,
                  itemBuilder: (context, index) {
                    final item = _analysisData[index];
                    final date = item['date'] as DateTime;
                    final formattedDate = DateFormat('dd MMM yyyy').format(date);
                    
                    return Card(
                      color: const Color(0xFF2A2D3E),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item['status']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.analytics,
                                color: _getStatusColor(item['status']),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Status: ${item['status']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: _getStatusColor(item['status']),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: Colors.grey),
                                const SizedBox(height: 8),
                                _buildDetailRow('Nitrogen', '${item['nitrogen']}%', Colors.green),
                                const SizedBox(height: 8),
                                _buildDetailRow('Phosphorus', '${item['phosphorus']}%', Colors.orange),
                                const SizedBox(height: 8),
                                _buildDetailRow('Potassium', '${item['potassium']}%', Colors.purple),
                                const SizedBox(height: 8),
                                _buildDetailRow('pH', '${item['ph']}', Colors.red),
                                const SizedBox(height: 12),
                                const Divider(color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'Rekomendasi:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['recommendation'],
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
                    );
                  },
                ),
                
                // Extra space for the floating navigation bar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper untuk membangun item ringkasan
  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label + ':',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper untuk membangun baris detail
  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
  
  // Helper untuk mendapatkan warna berdasarkan status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Optimal':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      case 'Warning':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}