import 'package:flutter/material.dart';
import 'src/pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase berhasil diinisialisasi');

  // Tes koneksi ke database
  try {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('test');
    await ref.set({
      'connection': 'success',
      'timestamp': ServerValue.timestamp,
    });
    print('Tes koneksi Firebase berhasil');
  } catch (error) {
    print('Error saat menguji koneksi Firebase: $error');
  }

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