import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BloxboxdApp());
}

// ==========================================
// APP ENTRY POINT & SAFE FIREBASE LOADER
// ==========================================
class BloxboxdApp extends StatelessWidget {
  const BloxboxdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloxboxd',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14181C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E054), // Letterboxd Green
          secondary: Color(0xFF40BCF4), // Letterboxd Blue
          tertiary: Color(0xFFFF8000), // Letterboxd Orange
          surface: Color(0xFF1F262E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF14181C),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1F262E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
      ),
      home: const FirebaseInitializer(),
    );
  }
}

// Safely initializes Firebase without crashing or showing a blank screen
class FirebaseInitializer extends StatelessWidget {
  const FirebaseInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    final initialization = Firebase.apps.isNotEmpty
        ? Future.value(Firebase.app())
        : Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyDXN_8-pxP97BG00yy3cDmRzKHdA4zBY1I",
              authDomain: "flutter-finals-725ed.firebaseapp.com",
              projectId: "flutter-finals-725ed",
              storageBucket: "flutter-finals-725ed.firebasestorage.app",
              messagingSenderId: "784142585461",
              appId: "1:784142585461:web:3ac4a9633d49893df3f23c",
              measurementId: "G-GEXKQKX6NQ",
            ),
          );

    return FutureBuilder(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Firebase Init Error:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          return const AuthWrapper();
        }
        // Shows a neat loading indicator while Firebase wakes up
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF00E054)),
          ),
        );
      },
    );
  }
}

// ==========================================
// AUTH WRAPPER (Restricts protected screens)
// ==========================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00E054))),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
