import 'package:flutter/material.dart';
import '../backend/local_auth_backend.dart';
import 'scanner_opening_screen.dart';
import 'co2_dashboard_screen.dart';

class MyCollectionScreen extends StatefulWidget {
  const MyCollectionScreen({super.key});

  @override
  State<MyCollectionScreen> createState() => _MyCollectionScreenState();
}

class _MyCollectionScreenState extends State<MyCollectionScreen> {
  @override
  Widget build(BuildContext context) {
    final user = LocalAuthBackend.getCurrentUser();
    final activities = user?.activities.where((a) => a.type == 'recycle').toList() ?? [];

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
          'My Collection',
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
          const SizedBox(height: 16),

          // --- Grid View ---
          Expanded(
            child: activities.isEmpty 
              ? const Center(child: Text("No items recycled yet.", style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final item = activities[index];
                    return _buildCollectionCard(
                      title: item.title,
                      date: item.date,
                      points: item.points,
                      icon: Icons.recycling, // Could be dynamic if title suggests specific type
                      bgColor: const Color(0xFFE8F5E9),
                    );
                  },
                ),
          ),
        ],
      ),

      // --- Custom Bottom Navigation (With Fake FAB fix) ---
      floatingActionButton: _buildFakeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCollectionCard({required String title, required String date, required int points, required IconData icon, required Color bgColor}) {
    return Container(
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(child: Icon(icon, size: 70, color: Colors.grey.shade400)),
                Positioned(
                  bottom: 8, right: 12,
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))]),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 45,
            decoration: const BoxDecoration(color: Color(0xFF94D051), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(date, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                Text('+$points', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFakeFab() {
    return Container(
      height: 60, width: 60,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))]),
      child: IconButton(
        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF94D051), size: 30), 
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerOpeningScreen())).then((_) => setState(() {}))
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
            IconButton(
              icon: const Icon(Icons.show_chart_outlined, color: Colors.white, size: 28), 
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Co2DashboardScreen())),
            ),
            IconButton(icon: const Icon(Icons.storefront_outlined, color: Colors.white, size: 28), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}