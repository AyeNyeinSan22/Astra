import 'package:flutter/material.dart';
import '../widgets/astra_logo.dart';
import '../backend/local_auth_backend.dart';
import 'settings_screen.dart';
import 'my_collection_screen.dart';

class Co2DashboardScreen extends StatefulWidget {
  const Co2DashboardScreen({super.key});

  @override
  State<Co2DashboardScreen> createState() => _Co2DashboardScreenState();
}

class _Co2DashboardScreenState extends State<Co2DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = LocalAuthBackend.getCurrentUser();
    final String displayName = (user != null && user.name.isNotEmpty) ? user.name : 'Sammy';

    // Fallback values just in case user is null
    final int points = user?.points ?? 0;
    final int items = user?.itemsRecycled ?? 0;
    final double co2 = user?.co2SavedGrams ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AstraLogo(size: 40),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black87), onPressed: () {}),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                          if (mounted) setState(() {});
                        },
                        child: const CircleAvatar(radius: 16, backgroundColor: Color(0xFF7CB342), child: Icon(Icons.person_outline, size: 20, color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),

              // --- Dynamic Greeting ---
              Text('Hi, $displayName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              const Text("Let's contribution to our earth.", style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),

              // --- Main CO2 Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0FF), // Light Blue
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Background Icon (Simulated CO2 Cloud)
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Icon(Icons.cloud_outlined, size: 140, color: const Color(0xFFB3CCFF).withOpacity(0.5)),
                    ),

                    // Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('${co2.toInt()}g', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFF5A5A5A), height: 1.0)),
                        const Text('CO2 saved', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7A7A7A))),
                        const SizedBox(height: 32),

                        // Points & Items Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('My points', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7A7A7A))),
                                Text('$points', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5A5A5A))),
                                const SizedBox(height: 16),
                                const Text('Items Recycled', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7A7A7A))),
                                Text('$items', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5A5A5A))),
                              ],
                            ),
                            const SizedBox(width: 40), // Space to keep it aligned like the mockup
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Promotional Banners (Scrollable Horizontal) ---
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildPromoBanner(),
                    const SizedBox(width: 16),
                    _buildPromoBanner(), // A second one so you can scroll!
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mock Pagination Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                ],
              ),

              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),

      // --- THE NUCLEAR FIX: A FAKE FAB ---
      floatingActionButton: _buildFakeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Helper Widget: Promo Banner ---
  Widget _buildPromoBanner() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF94D051), Color(0xFFAED56A)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background Icon placeholder for bottles
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(Icons.recycling, size: 100, color: Colors.white.withOpacity(0.3)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Recycle Today', style: TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                const Text('EARN 100 POINTS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Earn Now', style: TextStyle(color: Color(0xFF7CB342), fontWeight: FontWeight.bold, fontSize: 14)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget: Fake FAB ---
  Widget _buildFakeFab() {
    return Container(
      height: 60, width: 60,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))]),
      child: IconButton(icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF94D051), size: 30), onPressed: () {}),
    );
  }

  // --- Helper Widget: Bottom Nav ---
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
            IconButton(
              icon: const Icon(Icons.show_chart_outlined, color: Colors.white, size: 28), 
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyCollectionScreen())),
            ),
            IconButton(icon: const Icon(Icons.storefront_outlined, color: Colors.white, size: 28), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}