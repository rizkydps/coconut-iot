import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'ml_service.dart';
import 'result_page.dart';
import 'auth_service.dart';
import 'main_page.dart';



class AnalyzePage extends StatefulWidget {
  const AnalyzePage({Key? key}) : super(key: key);

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _logger = Logger('AnalysisPage');
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _hasError = false;

  String _errorMessage = '';
  List<Map<String, dynamic>> _sensorData = [];
  Map<String, double> _averageData = {};
  List<LatLng> _locations = [];
  List<LatLng> _convexHull = []; // Keep this for convex hull storage
  int? _activePopup; // Add this for tracking which marker popup is active
  OpenRouterService? _openRouterService;
  bool _isLoadingRecommendations = false;
  bool _isButtonClicked = false; 


  @override
  void initState() {
    super.initState();
    _fetchSensorData();

    _openRouterService = OpenRouterService(apiKey: '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');
  }

    Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
  
  // Method to handle delete action
  // Method to handle delete action permanently
  Future<void> _deleteSensorDataById(String id, BuildContext context) async {
    try {
      String? userId = _authService.getCurrentUser()?.uid;
      if (userId == null) throw Exception('User belum login');

      DatabaseReference ref = _database.child('users').child(userId).child('sensors').child(id);
      DataSnapshot snapshot = await ref.get();

      if (!snapshot.exists) {
        throw Exception('Data dengan ID $id tidak ditemukan.');
      }

      await ref.remove();

      setState(() {
        _sensorData.removeWhere((data) => data['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchSensorData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // Fungsi untuk menentukan orientasi tiga titik
  int orientation(LatLng p, LatLng q, LatLng r) {
    double val = (q.longitude - p.longitude) * (r.latitude - q.latitude) -
        (q.latitude - p.latitude) * (r.longitude - q.longitude);

    if (val == 0) return 0; // colinear
    return (val > 0) ? 1 : 2; // clock or counterclock wise
  }

  // Fungsi untuk membuat convex hull
  List<LatLng> _createConvexHull(List<LatLng> points) {
      if (points.length < 3) return points;

      int lowestIndex = 0;
      for (int i = 1; i < points.length; i++) {
        if (points[i].latitude < points[lowestIndex].latitude ||
            (points[i].latitude == points[lowestIndex].latitude &&
                points[i].longitude < points[lowestIndex].longitude)) {
          lowestIndex = i;
        }
      }

      LatLng p0 = points[lowestIndex];
      points[lowestIndex] = points[0];
      points[0] = p0;

      points = [p0, ...points.sublist(1)..sort((a, b) {
        double cross = (a.longitude - p0.longitude) * (b.latitude - p0.latitude) -
                      (a.latitude - p0.latitude) * (b.longitude - p0.longitude);

        if (cross == 0) {
          double distA = (a.longitude - p0.longitude) * (a.longitude - p0.longitude) +
                        (a.latitude - p0.latitude) * (a.latitude - p0.latitude);
          double distB = (b.longitude - p0.longitude) * (b.longitude - p0.longitude) +
                        (b.latitude - p0.latitude) * (b.latitude - p0.latitude);
          return distA.compareTo(distB);
        }

        return cross > 0 ? -1 : 1;
      })];

      List<LatLng> hull = [];
      for (int i = 0; i < math.min(3, points.length); i++) {
        hull.add(points[i]);
      }

      for (int i = 3; i < points.length; i++) {
        while (hull.length > 1 &&
              !_isCounterClockwise(hull[hull.length - 2], hull[hull.length - 1], points[i])) {
          hull.removeLast();
        }
        hull.add(points[i]);
      }

      if (hull.first != hull.last) {
        hull.add(hull.first); // Menutup poligon
      }

      return hull;
  }


  bool _isCounterClockwise(LatLng a, LatLng b, LatLng c) {
    return (b.longitude - a.longitude) * (c.latitude - a.latitude) -
           (b.latitude - a.latitude) * (c.longitude - a.longitude) > 0;
  }

  // Fungsi untuk menghitung luas area polygon
  double calculatePolygonArea(List<LatLng> points) {
    double area = 0.0;
    int n = points.length;
    if (n < 3) return 0.0; // Tidak bisa membentuk polygon

    for (int i = 0; i < n; i++) {
      LatLng p1 = points[i];
      LatLng p2 = points[(i + 1) % n];
      area += (p1.longitude + p2.longitude) * (p1.latitude - p2.latitude);
    }
    return area.abs() / 2.0;
  }

  // Fungsi untuk menampilkan detail polygon
 

  Future<void> _fetchSensorData() async {
  if (!mounted) return;

  // Mulai loading
  setState(() {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    _activePopup = null; // Reset active popup ketika mengambil data baru
  });

  try {
    print('Mencoba mengambil data dari Firebase');

    // Dapatkan ID user yang sedang login
    String? userId = _authService.getCurrentUser()?.uid;

    if (userId == null) {
      throw Exception('User belum login');
    }

    // Coba ambil data dari path baru (users/$userId/sensors)
    DatabaseReference userSensorRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('sensors');

    DataSnapshot snapshot = await userSensorRef.get().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('Koneksi ke Firebase timeout'),
    );

    if (snapshot.exists && snapshot.value != null) {
      print('Data ditemukan di path baru (users/$userId/sensors)');

      // Proses data sensor
      if (snapshot.value is Map) {
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        print('Jumlah data sensor: ${values.length}');

        _sensorData = [];
        _locations = [];

        values.forEach((key, value) {
          try {
            if (value is Map) {
              Map<String, dynamic> data = {'id': key};
              value.forEach((k, v) => data[k.toString()] = v);
              _sensorData.add(data);

              // Validasi dan tambahkan lokasi
              if (data.containsKey('latitude') && data.containsKey('longitude')) {
                try {
                  double lat = double.parse(data['latitude'].toString());
                  double lng = double.parse(data['longitude'].toString());

                  if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                    _locations.add(LatLng(lat, lng));
                    print('Lokasi ditambahkan: $lat, $lng');
                  } else {
                    print('Koordinat tidak valid untuk key: $key');
                  }
                } catch (e) {
                  print('Error parsing koordinat: $e');
                }
              } else {
                print('Data tidak memiliki koordinat latitude/longitude');
              }
            } else {
              print('Data untuk key $key bukan Map: ${value.runtimeType}');
            }
          } catch (e) {
            print('Error memproses data untuk key $key: $e');
          }
        });

        // Hapus lokasi duplikat
        _locations = _locations.toSet().toList();
        print('Total data yang diproses: ${_sensorData.length}');
        print('Total lokasi yang diekstrak: ${_locations.length}');
      } else {
        throw FormatException('Data di path "sensors" bukan Map: ${snapshot.value.runtimeType}');
      }
    } else {
      print('Tidak ada data di path "users/$userId/sensors" atau data null');

      // Fallback ke path lama (sensors)
      print('Mencoba mengambil data dari path lama (sensors)');
      DatabaseReference oldSensorRef = FirebaseDatabase.instance.ref().child('sensors');
      DataSnapshot oldSnapshot = await oldSensorRef.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Koneksi ke Firebase timeout'),
      );

      if (oldSnapshot.exists && oldSnapshot.value != null) {
        print('Data ditemukan di path lama (sensors)');

        // Proses data sensor dari path lama
        if (oldSnapshot.value is Map) {
          Map<dynamic, dynamic> values = oldSnapshot.value as Map<dynamic, dynamic>;
          print('Jumlah data sensor: ${values.length}');

          _sensorData = [];
          _locations = [];

          values.forEach((key, value) {
            try {
              if (value is Map) {
                Map<String, dynamic> data = {'id': key};
                value.forEach((k, v) => data[k.toString()] = v);
                _sensorData.add(data);

                // Validasi dan tambahkan lokasi
                if (data.containsKey('latitude') && data.containsKey('longitude')) {
                  try {
                    double lat = double.parse(data['latitude'].toString());
                    double lng = double.parse(data['longitude'].toString());

                    if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
                      _locations.add(LatLng(lat, lng));
                      print('Lokasi ditambahkan: $lat, $lng');
                    } else {
                      print('Koordinat tidak valid untuk key: $key');
                    }
                  } catch (e) {
                    print('Error parsing koordinat: $e');
                  }
                } else {
                  print('Data tidak memiliki koordinat latitude/longitude');
                }
              } else {
                print('Data untuk key $key bukan Map: ${value.runtimeType}');
              }
            } catch (e) {
              print('Error memproses data untuk key $key: $e');
            }
          });

          // Hapus lokasi duplikat
          _locations = _locations.toSet().toList();
          print('Total data yang diproses: ${_sensorData.length}');
          print('Total lokasi yang diekstrak: ${_locations.length}');
        } else {
          throw FormatException('Data di path "sensors" bukan Map: ${oldSnapshot.value.runtimeType}');
        }
      } else {
        print('Tidak ada data di path lama "sensors" atau data null');
      }
    }

    // Hitung rata-rata jika ada data sensor
    if (_sensorData.isNotEmpty) {
      _calculateAverages();
    } else {
      _averageData = {
        'Nitrogen': 0,
        'Phosphorus': 0,
        'Potassium': 0,
        'pH': 0,
        'EC': 0,
        'Temperature': 0,
        'Humidity': 0,
      };
    }

    // Update convex hull
    if (_locations.length >= 3) {
      _convexHull = _createConvexHull(List.from(_locations));
      print('Convex Hull created with ${_convexHull.length} points');
    } else {
      _convexHull = _locations;
      print('Not enough points for convex hull, using original locations');
    }
  } catch (e, stackTrace) {
    print('Error saat mengambil data: $e');
    print('Stack trace: $stackTrace');

    _hasError = true;

    if (e is TimeoutException) {
      _errorMessage = 'Koneksi ke database timeout. Periksa koneksi internet Anda dan coba lagi.';
    } else if (e is FirebaseException) {
      _errorMessage = 'Error Firebase: ${e.message}';
    } else if (e is Exception && e.toString().contains('User belum login')) {
      _errorMessage = 'Anda belum login. Silakan login terlebih dahulu.';
    } else {
      _errorMessage = 'Terjadi kesalahan: $e';
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  void _onTapMarker(int index) {
    setState(() {
      _activePopup = index;
    });
  }

  Card buildMapCard(BuildContext context, List<LatLng> convexHull, List<LatLng> locations, List<Map<String, dynamic>> sensorData, int activePopup, Function(int) onTapMarker) {
    return Card(
      color: const Color(0xFF2A2D3E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          
          child: FlutterMap(
            options: MapOptions(
              // Updated from 'center' to 'initialCenter'
              initialCenter: convexHull.isNotEmpty 
                  ? convexHull.first 
                  : const LatLng(0, 0),
              // Updated from 'zoom' to 'initialZoom'
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),

              // Polygon Layer
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: convexHull,
                    color: const Color.fromRGBO(255, 0, 0, 0.4),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 3.0,
                  ),
                ],
              ),

              // Polyline Layer
              if (locations.length >= 3)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [...convexHull, convexHull.isNotEmpty ? convexHull.first : const LatLng(0, 0)],
                      color: const Color.fromARGB(255, 22, 89, 236),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),

              // Marker Layer
              MarkerLayer(
                markers: locations.asMap().entries.map(
                  (entry) {
                    int index = entry.key;
                    LatLng point = entry.value;
                    String name = sensorData.isNotEmpty && index < sensorData.length
                        ? (sensorData[index]['name'] ?? 'Unnamed')
                        : 'Unnamed';

                    return Marker(
                      point: point,
                      width: 80,
                      height: 80,
                      // Changed from 'builder' to 'child' to fix the undefined parameter
                      child: GestureDetector(
                        onTap: () {
                          onTapMarker(index);
                        },
                        child: Column(
                          children: [
                            if (activePopup == index)
                              Flexible(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 50,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        // Replaced withOpacity with withValues
                                        color: Colors.black.withValues(alpha: 51), // 0.2 * 255 = 51
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),

                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _calculateAverages() {
    print('Menghitung rata-rata...');

    // Initialize average map
    _averageData = {
      'Nitrogen': 0,
      'Phosphorus': 0,
      'Potassium': 0,
      'pH': 0,
      'EC': 0,
      'Temperature': 0,
      'Humidity': 0,
    };

    if (_sensorData.isEmpty) return;

    // Track counts for each parameter
    Map<String, int> counts = {
      'Nitrogen': 0,
      'Phosphorus': 0,
      'Potassium': 0,
      'pH': 0,
      'EC': 0,
      'Temperature': 0,
      'Humidity': 0,
    };

    // Sum all values
    for (var data in _sensorData) {
      _averageData.forEach((key, _) {
        if (data.containsKey(key)) {
          try {
            var value = data[key];
            double numValue;

            if (value is num) {
              numValue = value.toDouble();
            } else if (value is String) {
              numValue = double.parse(value);
            } else if (value == null) {
              print('Warning: $key is null in a data entry');
              return;
            } else {
              print('Warning: $key has unexpected type: ${value.runtimeType}');
              return;
            }

            _averageData[key] = _averageData[key]! + numValue;
            counts[key] = counts[key]! + 1;
          } catch (e) {
            print('Error parsing $key value (${data[key]}): $e');
          }
        }
      });
    }

    // Divide by count to get average
    _averageData.forEach((key, value) {
      if (counts[key]! > 0) {
        _averageData[key] = value / counts[key]!;
        print('Rata-rata $key: ${_averageData[key]} (dari ${counts[key]} data)');
      } else {
        _averageData[key] = 0;
        print('Tidak ada data valid untuk $key');
      }
    });
  }

  Future<void> _resetData() async {
    try {
      await _database.child('sensors').remove();
      setState(() {
        _sensorData = [];
        _averageData = {
          'Nitrogen': 0,
          'Phosphorus': 0,
          'Potassium': 0,
          'pH': 0,
          'EC': 0,
          'Temperature': 0,
          'Humidity': 0,
        };
        _locations = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data telah dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // api ai
Future<void> _getPlantRecommendations(BuildContext context) async {
  if (_averageData.isEmpty) {
    // Close the analyzing dialog if it's open
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No soil data available for recommendations'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Set loading state and button clicked state
  setState(() {
    _isLoadingRecommendations = true;
    _isButtonClicked = true;
  });

  try {
    // Find the MainPage state
    final mainPageState = context.findAncestorStateOfType<MainPageState>();

    // If inside MainPage, update the ResultPage with loading state
    if (mainPageState != null) {
      mainPageState.updateResultsPage(
        recommendations: [],
        soilParameters: _averageData,
        isLoading: true,
        isButtonClicked: true,
      );
    }

    // Call the OpenAI API for recommendations
    final response = await _openRouterService!.getPlantRecommendations(_averageData);

    // Parse the recommendations
    final List<PlantRecommendationResult> recommendations = [];

    if (response.containsKey('recommendations') && response['recommendations'] is List) {
      for (var item in response['recommendations']) {
        recommendations.add(PlantRecommendationResult.fromJson(item));
      }
    }

    // Sort recommendations by compatibility score (highest first)
    recommendations.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

    // Update the ResultPage with the actual results
    if (mainPageState != null) {
      mainPageState.updateResultsPage(
        recommendations: recommendations,
        soilParameters: _averageData,
        isLoading: false,
        isButtonClicked: true,
      );
      
      // After data is loaded, automatically navigate to the ResultPage
      mainPageState.navigateToResultPage();
    }
  } catch (e) {
    print('Error getting plant recommendations: $e');
    
    // Close the analyzing dialog if it's open
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    // Show error on the ResultPage
    final mainPageState = context.findAncestorStateOfType<MainPageState>();
    if (mainPageState != null) {
      mainPageState.updateResultsPage(
        recommendations: [],
        soilParameters: _averageData,
        errorMessage: 'Failed to get plant recommendations: $e',
        isLoading: false,
        isButtonClicked: true,
      );
      
      // Still navigate to result page to show error
      mainPageState.navigateToResultPage();
    } else {
      // Show error in a snackbar if MainPage state is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get plant recommendations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    // Ensure loading state is reset
    if (mounted) {
      setState(() {
        _isLoadingRecommendations = false;
      });
    }
  }
}

  

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF1E1E2C),
    appBar: AppBar(
      backgroundColor: const Color(0xFF2A2D3E),
      centerTitle: true,
      title: Text(
        'Analysis',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.blue),
          onPressed: _fetchSensorData,
          tooltip: 'Refresh Data',
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: _resetData,
          tooltip: 'Reset Data',
        ),
      ],
    ),
    body: _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading data...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          )
        : _hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
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
                        _errorMessage,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchSensorData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              )
            : _sensorData.isEmpty
                ? Center(
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
                            'Tambahkan pengukuran baru pada halaman utama',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchSensorData,
                    backgroundColor: const Color(0xFF2A2D3E),
                    color: Colors.blue,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Map section
                            Text(
                              'Lokasi Sample',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Map
                            if (_locations.isEmpty)
                              Card(
                                color: const Color(0xFF2A2D3E),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.location_off,
                                          color: Colors.white70,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Tidak ada data lokasi',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              buildMapCard(
                                context,
                                _convexHull,
                                _locations,
                                _sensorData,
                                _activePopup ?? -1,
                                _onTapMarker,
                              ),
                              
                            // Reduced spacing between sections
                            const SizedBox(height: 16),
                            
                            // Recorded measurements
                            Text(
                              'Sample Tersimpan',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                              // List of measurements
                            ListView.separated(
                              separatorBuilder: (context, index) => const SizedBox(height: 12), // Reduced spacing
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _sensorData.length,
                              itemBuilder: (context, index) {
                                final data = _sensorData[index];
                                final name = data['name'] ?? 'Unnamed';
                                
                                // Handle timestamp safely
                                DateTime timestamp;
                                try {
                                  if (data['timestamp'] is int) {
                                    timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
                                  } else if (data['timestamp'] is String) {
                                    timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(data['timestamp']));
                                  } else {
                                    timestamp = DateTime.now();
                                  }
                                } catch (e) {
                                  print('Error parsing timestamp: $e');
                                  timestamp = DateTime.now();
                                }
                                
                                // Handle coordinates safely
                                String locationText = 'Tidak ada data lokasi';
                                if (data.containsKey('latitude') && data.containsKey('longitude')) {
                                  locationText = '${data['latitude']}, ${data['longitude']}';
                                }
                                
                                final formattedDate = DateFormat('dd MMM yyyy').format(timestamp);
                                final formattedTime = DateFormat('HH:mm').format(timestamp);
                                
                                return Card(
                                  color: const Color(0xFF2A2D3E),
                                  elevation: 4,
                                  margin: EdgeInsets.zero, // Remove default margin to use separator
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
                                            color: Colors.blue.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.sensors,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'Tanggal: $formattedDate, $formattedTime',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
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
                                            _buildDetailRow('Lokasi', locationText, Colors.blue),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Nitrogen', '${data['Nitrogen'] ?? 'N/A'}%', Colors.green),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Phosphorus', '${data['Phosphorus'] ?? 'N/A'}%', Colors.orange),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Potassium', '${data['Potassium'] ?? 'N/A'}%', Colors.purple),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('pH', '${data['pH'] ?? 'N/A'}', Colors.red),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('EC', '${data['EC'] ?? 'N/A'} µS/cm', Colors.teal),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Temperature', '${data['Temperature'] ?? 'N/A'}°C', Colors.amber),
                                            const SizedBox(height: 8),
                                            _buildDetailRow('Humidity', '${data['Humidity'] ?? 'N/A'}%', Colors.lightBlue),
                                            const SizedBox(height: 12),
                                            const Divider(color: Colors.grey),
                                            const SizedBox(height: 8),
                                            
                                            // Tombol Delete
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  // Ambil ID dari data saat ini
                                                  final dataId = _sensorData[index]['id'];

                                                  // Panggil metode untuk menghapus data berdasarkan ID
                                                  await _deleteSensorDataById(dataId, context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                ),
                                                child: Text(
                                                  'Hapus',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
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

                            // Reduced spacing between sections
                            const SizedBox(height: 0),
                            const Divider(color: Colors.grey),
                            const SizedBox(height: 8), // Reduced spacing after divider

                            // Parameter Tanah Rata-rata Section
                            Text(
                              'Data Rata-rata Tanah',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Berdasarkan 7 Pengukuran',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12), // Reduced spacing

                            // Parameters Grid
                            SingleChildScrollView(
                              child: Column(
                                children: _averageData.keys.map((key) {
                                  double value = _averageData[key]!;

                                  final Map<String, Map<String, dynamic>> sensorInfo = {
                                    'Nitrogen': {'color': Colors.green, 'unit': '%'},
                                    'Phosphorus': {'color': Colors.orange, 'unit': '%'},
                                    'Potassium': {'color': Colors.purple, 'unit': '%'},
                                    'pH': {'color': Colors.red, 'unit': ''},
                                    'EC': {'color': Colors.yellow, 'unit': 'mS/cm'},
                                    'Temperature': {'color': Colors.red, 'unit': '°C'},
                                    'Humidity': {'color': Colors.blue, 'unit': '%'},
                                  };

                                  Color color = (sensorInfo[key]?['color'] as Color?) ?? Colors.grey;
                                  String unit = (sensorInfo[key]?['unit'] as String?) ?? '';

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2A2D3E),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            key,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            '${value.toStringAsFixed(1)}$unit',
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 22), // Reduced spacing between sections

                            // Plant Recommendations Card
                            if (_sensorData.isNotEmpty)
                              Card(
                                color: const Color(0xFF2A2D3E),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: EdgeInsets.zero, // Remove default margin
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title and Icon
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.eco,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'AI Analisis Tanaman',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12), // Reduced spacing

                                      // Description
                                      Text(
                                        'Menggunakan AI untuk dapatkan saran tanaman yang akan tumbuh baik di tanah Anda berdasarkan data anda.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 16), // Reduced spacing

                                      // Button - Modified to show dialog when pressed
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _isLoadingRecommendations
                                              ? null // Disable button when loading
                                              : () {
                                                  // Show the analyzing dialog
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        backgroundColor: const Color(0xFF2A2D3E),
                                                        content: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const CircularProgressIndicator(
                                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                                            ),
                                                            const SizedBox(height: 16),
                                                            Text(
                                                              'Sedang Menganalisis...',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w500,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 8),
                                                            Text(
                                                              'Mohon tunggu sementara kami menganalisis data tanah Anda',
                                                              textAlign: TextAlign.center,
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                color: Colors.white70,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                  
                                                  // Call the plant recommendations function
                                                  _getPlantRecommendations(context).then((_) {
                                                    // Close the dialog when finished (if it's still showing)
                                                    if (Navigator.canPop(context)) {
                                                      Navigator.of(context).pop();
                                                    }
                                                  });
                                                },
                                          icon: const Icon(Icons.recommend),
                                          label: Text(
                                            'Analisis Data',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),  

                            const SizedBox(height: 20),
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

}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}