import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
      // Scan image
      Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen(cameras: widget.cameras)));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello,", style: TextStyle(fontSize: 20, color: Colors.black87)),
                      Text("Eco Warrior", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.greenAccent.shade100,
                    child: const Icon(Icons.person, color: Colors.green, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // My Impact Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("My Impact", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                        Icon(Icons.eco, color: Colors.green.shade700),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("120", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.black)),
                            Text("Points", style: TextStyle(fontSize: 14, color: Colors.green.shade800)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("5", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black)),
                            Text("Items Recycled", style: TextStyle(fontSize: 14, color: Colors.green.shade800)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Scan CTA Banner
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen(cameras: widget.cameras)));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A), // vibrant green
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Identify Your Trash", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text("Scan it now", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Smart Bin Status
              const Text("Smart Bin Status", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildBinStatusCard("Blue Bin", "Paper", 0.60, Colors.blue, Icons.description),
              const SizedBox(height: 12),
              _buildBinStatusCard("Yellow Bin", "Plastic", 0.20, Colors.amber.shade700, Icons.local_drink),
              const SizedBox(height: 12),
              _buildBinStatusCard("Gray Bin", "Metal", 0.85, Colors.grey.shade700, Icons.settings_input_component),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
          ]
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedItemColor: const Color(0xFF2BCE82),
            unselectedItemColor: Colors.black45,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.home_rounded, size: 26, color: _selectedIndex == 0 ? const Color(0xFF2BCE82) : Colors.black45),
                ),
                label: "Home"
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.location_on_outlined, size: 26, color: _selectedIndex == 1 ? const Color(0xFF2BCE82) : Colors.black45),
                ),
                label: "Location"
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2BCE82),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF2BCE82).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                ), 
                label: "Scan"
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.storefront_outlined, size: 26, color: _selectedIndex == 3 ? const Color(0xFF2BCE82) : Colors.black45),
                ),
                label: "Store"
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.settings_outlined, size: 26, color: _selectedIndex == 4 ? const Color(0xFF2BCE82) : Colors.black45),
                ),
                label: "Settings"
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBinStatusCard(String title, String subtitle, double fullness, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("($subtitle)", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 32),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: fullness,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text("${(fullness * 100).toInt()}% Full", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
