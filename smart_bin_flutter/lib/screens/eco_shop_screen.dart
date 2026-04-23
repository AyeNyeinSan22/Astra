import 'package:flutter/material.dart';
import '../backend/local_auth_backend.dart';
import 'scanner_opening_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';

class EcoShopScreen extends StatefulWidget {
  const EcoShopScreen({super.key});

  @override
  State<EcoShopScreen> createState() => _EcoShopScreenState();
}

class _EcoShopScreenState extends State<EcoShopScreen> {
  final List<Map<String, dynamic>> _products = [
    {'title': 'Handmade Bag', 'points': 500, 'icon': Icons.shopping_bag_outlined, 'color': Colors.blue.shade50, 'accent': Colors.blue},
    {'title': 'Bamboo Straws', 'points': 150, 'icon': Icons.eco_outlined, 'color': Colors.green.shade50, 'accent': Colors.green},
    {'title': 'Eco Bottle', 'points': 350, 'icon': Icons.local_drink_outlined, 'color': Colors.orange.shade50, 'accent': Colors.orange},
    {'title': 'Organic Soap', 'points': 120, 'icon': Icons.clean_hands_outlined, 'color': Colors.purple.shade50, 'accent': Colors.purple},
    {'title': 'Cotton Tote', 'points': 200, 'icon': Icons.shopping_basket_outlined, 'color': Colors.teal.shade50, 'accent': Colors.teal},
    {'title': 'Solar Light', 'points': 1000, 'icon': Icons.wb_sunny_outlined, 'color': Colors.yellow.shade50, 'accent': Colors.amber},
  ];

  void _onItemTapped(int index) {
    if (index == 3) return; // Already on store

    if (index == 0) {
      Navigator.pop(context); // Go back to Home
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    }
  }

  void _handleRedeem(Map<String, dynamic> item, int userPoints) async {
    if (userPoints < item['points']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You need ${item['points'] - userPoints} more points for this!"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Redeem ${item['title']}?"),
        content: Text("This will cost you ${item['points']} points. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF94D051), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Redeem", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await LocalAuthBackend.redeemItem(title: item['title'], cost: item['points']);
      if (success && mounted) {
        setState(() {}); // Refresh points
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Success! ${item['title']} redeemed."),
            backgroundColor: const Color(0xFF94D051),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = LocalAuthBackend.getCurrentUser();
    final int points = user?.points ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F1), // Softer, eco-tinted background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Eco Store', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Header Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF94D051), Color(0xFF7CB342)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF94D051).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('$points PTS', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.stars, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text("Sustainable Rewards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final item = _products[index];
                bool canAfford = points >= item['points'];

                return GestureDetector(
                  onTap: () => _handleRedeem(item, points),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: item['color'],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                child: Center(child: Icon(item['icon'], size: 50, color: item['accent'].withOpacity(0.7))),
                              ),
                              if (!canAfford)
                                Container(
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                                  child: const Center(child: Icon(Icons.lock_outline, color: Colors.black26, size: 30)),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142))),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item['points']} pts', style: TextStyle(color: canAfford ? const Color(0xFF94D051) : Colors.grey, fontWeight: FontWeight.w800, fontSize: 13)),
                                  Icon(Icons.arrow_circle_right, color: canAfford ? const Color(0xFF94D051) : Colors.grey.shade300, size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFab() {
    return Container(
      height: 64, width: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IconButton(
        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF94D051), size: 30),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerOpeningScreen())).then((_) => setState(() {})),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      height: 70,
      color: const Color(0xFF94D051),
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      elevation: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded),
          _buildNavItem(1, Icons.person_rounded),
          const SizedBox(width: 50),
          _buildNavItem(3, Icons.storefront_rounded),
          _buildNavItem(4, Icons.settings_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isSelected = index == 3; // EcoStore index
    return IconButton(
      onPressed: () => _onItemTapped(index),
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
        size: 28,
      ),
    );
  }
}
