// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SiMuApp());
}

class SiMuApp extends StatelessWidget {
  const SiMuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiMu - Keuangan Mahasiswa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A6BFF),
          primary: const Color(0xFF1A6BFF),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      // AuthGate: cek sesi Firebase secara real-time
      // Jika sudah login → langsung DashboardScreen (auto-login)
      // Jika belum → LoginScreen
      home: const AuthGate(),
    );
  }
}

/// AuthGate mendengarkan perubahan status autentikasi Firebase.
/// Tidak perlu shared_preferences manual — Firebase Auth menyimpan
/// token sesi secara persisten di device secara otomatis.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Menunggu status auth dari Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F7FF),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A6BFF),
              ),
            ),
          );
        }

        // Sudah login — langsung ke Dashboard tanpa perlu input ulang
        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardScreen();
        }

        // Belum login — tampilkan halaman Login
        return const LoginScreen();
      },
    );
  }
}
