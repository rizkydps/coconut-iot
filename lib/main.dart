import 'package:flutter/material.dart';
import 'src/pages/splash_screen.dart';
import 'src/pages/login_page.dart';
import 'src/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();

  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  // Inisialisasi Firebase default
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase default berhasil diinisialisasi');
  } catch (error) {
    print('Gagal menginisialisasi Firebase default: $error');
    return;
  }

  // Inisialisasi Firebase dengan nama khusus
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

  // Gunakan instance default untuk koneksi
  try {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('test');
    await ref.set({
      'connection': 'success',
      'timestamp': ServerValue.timestamp,
    });
    print('Tes koneksi Firebase berhasil');
  } catch (error, stackTrace) {
    print('Error saat menguji koneksi Firebase: $error');
    print('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
