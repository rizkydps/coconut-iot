import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _nameController = TextEditingController();
  final Uuid _uuid = Uuid();
  
  bool _deviceStatus = false;
  bool _isSaving = false;
  
  // Sensor data - normally this would come from your IoT device
  final Map<String, double> _sensorData = {
    'Nitrogen': 10.4,
    'Phosphorus': 10.4,
    'Potassium': 10.2,
    'pH': 10.5,
    'EC': 10.2,
    'Temperature': 10.3,
    'Humidity': 10.7,

  };
  
  // Coordinates data
  String _latitude = '-7.7931';
  String _longitude = '110.3695';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

  Future<void> _saveSensorData() async {
    // Show dialog to enter name for this measurement
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(
          'Save Data  ',
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
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Generate a unique ID for this measurement
      String measurementId = _uuid.v4();
      
      // Create data to save
      Map<String, dynamic> sensorEntry = {
        'id': measurementId,
        'name': name,
        'longitude': _longitude,
        'latitude': _latitude,
        'timestamp': ServerValue.timestamp,
      };
      
      // Add all sensor data
      _sensorData.forEach((key, value) {
        sensorEntry[key] = value;
      });
      
      // Save to Firebase under 'sensors' node
      await _database.child('sensors').child(measurementId).set(sensorEntry);
      
      Fluttertoast.showToast(
        msg: "Data saved successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
      _nameController.clear();
    } catch (e, stackTrace) {
        Fluttertoast.showToast(
          msg: "Error detail: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        print('Error saving data: $e');
        print('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
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
                // Header with title
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Land Data Monitoring',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
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
                        // Add Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
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
                
                // Section Title
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