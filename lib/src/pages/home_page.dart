import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Assuming you have an AuthService class
import 'auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Services and Controllers
  final AuthService _authService = AuthService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _nameController = TextEditingController();

  // Utilities
  static const Uuid _uuid = Uuid();

  // State Variables
  bool _deviceStatus = false;
  bool _isSaving = false;
  bool _isLoading = true;

  // ThingsBoard API Configuration
  static const String _tbApiUrl = 'http://iot.politanisamarinda.ac.id:8080';
  static const String _deviceId = 'f6269e80-7fbc-11ef-b7a6-352fc94f82a8';
  String _accessToken = 'p9RlhxzeH4SyFzyZOhQ5';

  // Sensor data to be fetched from ThingsBoard
  Map<String, double> _sensorData = {
    'Nitrogen': 0.0,
    'Phosphorus': 0.0,
    'Potassium': 0.0,
    'pH': 0.0,
    'EC': 0.0,
    'Temperature': 0.0,
    'Humidity': 0.0,
  };

  // Coordinates data
  String _latitude = '-7.7931';
  String _longitude = '110.3695';

  // Error handling
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loginAndFetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _latitude = position.latitude.toStringAsFixed(6);
        _longitude = position.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loginToThingsBoard() async {
    try {
      final response = await http.post(
        Uri.parse('$_tbApiUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': 'imron@politanisamarinda.ac.id',
          'password': 'politani123'
        }),
      );

      if (response.statusCode == 200) {
        final loginData = json.decode(response.body);
        _accessToken = loginData['token'];
        return;
      }
      throw Exception('Login failed');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to login to ThingsBoard';
      });
      print('ThingsBoard Login Error: $e');
      throw Exception('Could not log in to ThingsBoard');
    }
  }

  Future<void> _fetchSensorData() async {
    try {
      final response = await http.get(
        Uri.parse('$_tbApiUrl/api/plugins/telemetry/DEVICE/$_deviceId/values/timeseries?keys=conductivity,humidity,nitrogen,pH,phosporus,potassium,temperature'),
        headers: {
          'Content-Type': 'application/json',
          'X-Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _sensorData['Nitrogen'] = double.tryParse(data['nitrogen']?[0]?['value'] ?? '0.0') ?? 0.0;
          _sensorData['Phosphorus'] = double.tryParse(data['phosporus']?[0]?['value'] ?? '0.0') ?? 0.0;
          _sensorData['Potassium'] = double.tryParse(data['potassium']?[0]?['value'] ?? '0.0') ?? 0.0;
          _sensorData['pH'] = double.tryParse(data['pH']?[0]?['value'] ?? '0.0') ?? 0.0;
          _sensorData['EC'] = double.tryParse(data['conductivity']?[0]?['value'] ?? '0.0') ?? 0.0;
          _sensorData['Temperature'] = double.tryParse(data['temperature']?[0]?['value'] ?? '0.0') ?? 0.0;
          _sensorData['Humidity'] = double.tryParse(data['humidity']?[0]?['value'] ?? '0.0') ?? 0.0;

          _isLoading = false;
          _errorMessage = ''; // Clear any previous error
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch sensor data';
          _isLoading = false;
        });
        throw Exception('Failed to fetch sensor data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error retrieving sensor data';
        _isLoading = false;
      });
      print('Sensor Data Fetch Error: $e');
    }
  }

  Future<void> _loginAndFetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await _loginToThingsBoard();
      await _fetchDeviceStatus(); // Fetch device status
      await _fetchSensorData();

      // Set up periodic data refresh
      Timer.periodic(const Duration(seconds: 10), (timer) {
        _fetchDeviceStatus(); // Periodically update device status
        _fetchSensorData();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize data';
        _isLoading = false;
      });
      print('Login and Fetch Data Error: $e');
    }
  }


  Future<void> _saveSensorData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(
          'Save Data',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: _nameController,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter Data name',
            hintStyle: GoogleFonts.poppins(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.green),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                Navigator.pop(context);
                _performSave(_nameController.text);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSave(String name) async {
    // Use the current context
    BuildContext context = this.context;

    // Tampilkan dialog loading
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
                'Menyimpan Data',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mohon tunggu sementara data sedang disimpan',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      String? userId = _authService.getCurrentUser()?.uid;

      if (userId == null) {
        // Tutup dialog loading
        Navigator.of(context).pop();

        // Tampilkan dialog error
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2D3E),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal Menyimpan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada pengguna yang login',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup dialog error
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
        return;
      }

      String measurementId = _uuid.v4();

      Map<String, dynamic> sensorEntry = {
        'id': measurementId,
        'name': name,
        'longitude': _longitude,
        'latitude': _latitude,
        'timestamp': ServerValue.timestamp,
      };

      _sensorData.forEach((key, value) {
        sensorEntry[key] = value;
      });

      await _database.child('users').child(userId).child('sensors').child(measurementId).set(sensorEntry);

      // Tutup dialog loading
      Navigator.of(context).pop();

      // Tampilkan dialog sukses
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2A2D3E),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Tersimpan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data berhasil disimpan!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog sukses
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      );

      _nameController.clear();
    } catch (e) {
      // Tutup dialog loading
      Navigator.of(context).pop();

      // Tampilkan dialog error
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2A2D3E),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'Gagal Menyimpan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gagal menyimpan data: $e',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog error
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text(
                    'Coba Lagi',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      );
      print('Save Error: $e');
    }
  }


  Future<void> _fetchDeviceStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_tbApiUrl/api/plugins/telemetry/DEVICE/$_deviceId/values/attributes/SERVER_SCOPE?keys=active'),
        headers: {
          'Content-Type': 'application/json',
          'X-Authorization': 'Bearer $_accessToken',
        },
      );

      print('Raw device status response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> attributesData = json.decode(response.body);
        print('Parsed attributes data: $attributesData');

        // Cari atribut dengan key "active" dalam array response
        if (attributesData.isNotEmpty) {
          for (var attribute in attributesData) {
            if (attribute is Map && attribute['key'] == 'active') {
              // Dapatkan nilai dari atribut active
              var activeValue = attribute['value'];

              // Konversi ke boolean
              bool isActive = activeValue == true || activeValue == 'true';

              print('Status aktif perangkat: $isActive');

              setState(() {
                _deviceStatus = isActive;
              });

              break; // Keluar dari loop setelah menemukan atribut active
            }
          }
        } else {
          print('Tidak ada data atribut yang diterima');
        }
      } else {
        print('Gagal mendapatkan status perangkat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saat mengambil status perangkat: $e');
    }
  }

  Future<void> _updateDeviceStatus(bool status) async {
    try {
      final response = await http.post(
        Uri.parse('$_tbApiUrl/api/plugins/telemetry/DEVICE/$_deviceId/SERVER_SCOPE'),
        headers: {
          'Content-Type': 'application/json',
          'X-Authorization': 'Bearer $_accessToken',
        },
        body: json.encode({
          'active': status
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _deviceStatus = status;
        });

        Fluttertoast.showToast(
          msg: status ? "Device Activated" : "Device Deactivated",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: status ? Colors.green : Colors.red,
          textColor: Colors.white,
        );
      } else {
        print('Failed to update device status: ${response.statusCode}');
        // Tampilkan pesan toast error
      }
    } catch (e) {
      print('Error updating device status: $e');
      // Tampilkan pesan toast error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF1E1E2C),

      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.green,
              ),
              SizedBox(height: 20),
              Text(
                'Fetching Sensor Data...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
        //     : _errorMessage.isNotEmpty
        //     ? Center(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       Icon(
        //         Icons.error_outline,
        //         color: Colors.red,
        //         size: 60,
        //       ),
        //       SizedBox(height: 20),
        //       Text(
        //         _errorMessage,
        //         style: GoogleFonts.poppins(
        //           color: Colors.white,
        //           fontSize: 16,
        //         ),
        //         textAlign: TextAlign.center,
        //       ),
        //       SizedBox(height: 20),
        //       ElevatedButton(
        //         onPressed: _loginAndFetchData,
        //         child: Text('Retry'),
        //       )
        //     ],
        //   ),
        // )
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Data Monitoring Lahan',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Device Status and Location Card
                Card(
                  color: const Color(0xFF2A2D3E),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Device Status Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Device Status',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Opacity(
                              opacity: 1.0, // Opacity penuh agar warna terlihat jelas
                              child: Switch(
                                value: _deviceStatus,
                                onChanged: null, // Ini membuat switch tidak bisa diinteraksi
                                activeColor: Colors.green, // Warna saat active
                                inactiveThumbColor: Colors.red, // Warna thumb saat inactive
                                inactiveTrackColor: Colors.red.withOpacity(0.5), // Warna track saat inactive
                              ),
                            )
                          ],
                        ),
                        const Divider(color: Colors.grey),
                        // Location coordinates
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location: $_latitude, $_longitude',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isSaving ? null : _saveSensorData,
                            icon: _isSaving
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.save, color: Colors.white),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Data',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Sensor Data Section Title
                Text(
                  'Data Sensor',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Sensor Parameters Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _sensorData.length,
                  itemBuilder: (context, index) {
                    String key = _sensorData.keys.elementAt(index);
                    double value = _sensorData[key]!;

                    IconData icon;
                    Color color;

                    // Assign icon and color based on parameter
                    switch (key) {
                      case 'Nitrogen':
                        icon = Icons.eco;
                        color = Colors.green;
                        break;
                      case 'Phosphorus':
                        icon = Icons.water_drop;
                        color = Colors.orange;
                        break;
                      case 'Potassium':
                        icon = Icons.spa;
                        color = Colors.purple;
                        break;
                      case 'pH':
                        icon = Icons.science;
                        color = Colors.red;
                        break;
                      case 'EC':
                        icon = Icons.bolt;
                        color = Colors.yellow;
                        break;
                      case 'Temperature':
                        icon = Icons.thermostat;
                        color = Colors.red;
                        break;
                      case 'Humidity':
                        icon = Icons.water;
                        color = Colors.blue;
                        break;
                      default:
                        icon = Icons.sensors;
                        color = Colors.grey;
                    }

                    // Units for each parameter
                    String unit = '';
                    if (key == 'Temperature') {
                      unit = '°C';
                    } else if (key == 'Humidity' || key == 'Nitrogen' || key == 'Phosphorus' || key == 'Potassium') {
                      unit = '%';
                    } else if (key == 'EC') {
                      unit = 'mS/cm';
                    }

                    return Card(
                      color: const Color(0xFF2A2D3E),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  key,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(icon, color: color, size: 24),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Modifikasi untuk mengatasi overflow pada EC
                            key == 'EC'
                                ? Column(
                              children: [
                                Text(
                                  '${value.toStringAsFixed(2)}',
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 20, // Ukuran font sedikit lebih kecil untuk EC
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  unit, // Menampilkan unit pada baris terpisah
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ],
                            )
                            : Text(
                              '${value.toStringAsFixed(2)}$unit',
                              style: GoogleFonts.robotoMono(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      await _authService.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

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

                // Extra padding at bottom
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}