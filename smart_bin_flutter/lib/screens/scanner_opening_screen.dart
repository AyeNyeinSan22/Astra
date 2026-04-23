import 'package:flutter/material.dart';
import 'camera_scanner_screen.dart';

class ScannerOpeningScreen extends StatefulWidget {
  const ScannerOpeningScreen({super.key});

  @override
  State<ScannerOpeningScreen> createState() => _ScannerOpeningScreenState();
}

class _ScannerOpeningScreenState extends State<ScannerOpeningScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan your scrap',
          style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search scrap rate',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF7CB342)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const Spacer(flex: 1),

          // --- Big Scanner Card ---
          Center(
            child: Container(
              width: 280,
              height: 320,
              decoration: BoxDecoration(
                color: const Color(0xFFCEF594), // Light green background
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fit_screen_outlined, // Looks like a scanner reticle
                    size: 100,
                    color: Color(0xFF4A4A4A),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF94D051),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Scan your scrap item',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  )
                ],
              ),
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),

      // --- Custom Bottom Navigation ---
      floatingActionButton: _buildFakeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFakeFab() {
    return Container(
      height: 60, width: 60,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))]),
      child: IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF94D051), size: 30),
          onPressed: () {} // We are already on this screen!
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: const Color(0xFF94D051),
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
            IconButton(icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 28), onPressed: () {}),
            const SizedBox(width: 48),
            IconButton(icon: const Icon(Icons.show_chart_outlined, color: Colors.white, size: 28), onPressed: () {}),
            IconButton(icon: const Icon(Icons.storefront_outlined, color: Colors.white, size: 28), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}