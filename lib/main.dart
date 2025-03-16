import 'package:flutter/material.dart';
import 'src/pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase dengan nama khusus
  try {
    await Firebase.initializeApp(
      name: 'coconut', // Berikan nama unik untuk instance Firebase
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase berhasil diinisialisasi dengan nama: coconut');
  } catch (error) {
    print('Gagal menginisialisasi Firebase: $error');
    return; // Hentikan eksekusi jika Firebase gagal diinisialisasi
  }

  // Tes koneksi ke Firebase Realtime Database
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