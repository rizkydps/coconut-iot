import 'package:flutter/material.dart';
import 'src/pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
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
    // Lanjutkan aplikasi meskipun Firebase gagal
  }
  
  // Hanya mencoba inisialisasi Firebase kedua jika yang pertama berhasil
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
  
  // Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}