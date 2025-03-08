import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_service.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  late Timer _timer;
  String _currentTime = '';
  bool _deviceStatus = false;
  
  // Sensor data - normally this would come from your IoT device
  final Map<String, double> _sensorData = {
    'Nitrogen': 45.8,
    'Phosphorus': 23.4,
    'Potassium': 67.2,
    'pH': 6.5,
    'EC': 1.2,
    'Temperature': 28.3,
    'Humidity': 65.7,
  };
  
  // Coordinates data
  final String _latitude = '-7.7931';
  final String _longitude = '110.3695';

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
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
              'assets/coco.png', // Ensure you have this asset
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.eco, color: Colors.green, size: 40);
              },
            ),
            const SizedBox(width: 10),
            Text(
              'COCONUUT',
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false, // Penting ketika menggunakan navigation bar yang melayang
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device status and location card
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
                            Switch(
                              value: _deviceStatus,
                              onChanged: (value) {
                                setState(() {
                                  _deviceStatus = value;
                                });
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                            ),
                          ],
                        ),
                        const Divider(color: Colors.grey),
                        // Location coordinates
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Location: $_latitude, $_longitude',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Section Title
                Text(
                  'Sensor Parameters',
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
                    if (key == 'Temperature') unit = '°C';
                    else if (key == 'Humidity' || key == 'Nitrogen' || key == 'Phosphorus' || key == 'Potassium') unit = '%';
                    else if (key == 'EC') unit = 'mS/cm';
                    
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
                            const SizedBox(height: 8),
                            Text(
                              '${value.toString()}$unit',
                              style: GoogleFonts.robotoMono(
                                fontSize: 24,
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
}