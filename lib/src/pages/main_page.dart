import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'analysis_page.dart';
import 'result_page.dart';
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

  // Declare variables needed for state management
  List<PlantRecommendationResult> _recommendations = [];
  Map<String, double> _soilParameters = {};
  bool _isLoading = false;
  bool _isButtonClicked = false;

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
        recommendations: _recommendations,
        soilParameters: _soilParameters,
        isLoading: _isLoading,
        isButtonClicked: _isButtonClicked,
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

  void updateResultsPage({
    required List<PlantRecommendationResult> recommendations,
    required Map<String, double> soilParameters,
    bool isLoading = false,
    String? errorMessage,
    bool isButtonClicked = false,
  }) {
    setState(() {
      _recommendations = recommendations;
      _soilParameters = soilParameters;
      _isLoading = isLoading;
      _isButtonClicked = isButtonClicked;

      // Update ResultPage in _pages list
      _pages[2] = ResultPage(
        recommendations: _recommendations,
        soilParameters: _soilParameters,
        isLoading: _isLoading,
        errorMessage: errorMessage,
        isButtonClicked: _isButtonClicked,
      );
    });
  }

  void navigateToResultPage() {
    // Navigate to the ResultPage tab by changing _selectedIndex
    setState(() {
      _selectedIndex = 2; // Assuming ResultPage is the third tab (index 2)
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
              _buildNavItem(2, Icons.assignment, 'Result'),
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