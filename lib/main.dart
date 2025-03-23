import 'package:flutter/material.dart';
import 'src/pages/splash_screen.dart';
import 'src/pages/login_page.dart'; // Import halaman login
import 'src/pages/home_page.dart'; // Import halaman home
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase default berhasil diinisialisasi');
    firebaseInitialized = true;
  } catch (error) {
    print('Gagal menginisialisasi Firebase default: $error');
  }
  
  if (firebaseInitialized) {
    try {
      await Firebase.initializeApp(
        name: 'coconut',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase berhasil diinisialisasi dengan nama: coconut');
    } catch (e) {
      if (e.toString().contains('duplicate app')) {
        print('Instance Firebase coconut sudah ada');
      } else {
        print('Gagal menginisialisasi Firebase coconut: $e');
      }
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',  // Rute awal
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),  // Tambahkan halaman login
        '/home': (context) => const HomePage(),    // Tambahkan halaman home
      },
    );
  }
}
