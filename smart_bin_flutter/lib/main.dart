import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Ensure this import points to where you saved your opening screen!
import 'screens/opening_screen.dart';

void main() {
  runApp(const AuthSequenceApp());
}

class AuthSequenceApp extends StatelessWidget {
  const AuthSequenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF94D051);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Astra',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandGreen,
          primary: brandGreen,
          surface: const Color(0xFFF6FBF2),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        
        // Minimalist Input Styling
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: brandGreen, width: 1.5),
          ),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),

        // Modern Button Styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandGreen,
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(color: brandGreen, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      home: const OpeningScreen(),
    );
  }
}
