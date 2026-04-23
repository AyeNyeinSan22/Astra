import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../widgets/astra_logo.dart';
import '../backend/local_auth_backend.dart';
import '../backend/bin_level_service.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'scanner_opening_screen.dart';
import 'eco_shop_screen.dart';
import 'habit_checklist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _currentLocation = 'Fetching location...';
  double _paperLevel = 0.0;
  double _plasticLevel = 0.0;
  Timer? _levelTimer;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _startLevelMonitoring();
  }

  @override
  void dispose() {
    _levelTimer?.cancel();
    super.dispose();
  }

  void _startLevelMonitoring() {
    _updateLevels();
    _levelTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateLevels();
    });
  }

  Future<void> _updateLevels() async {
    final levels = await BinLevelService.fetchLevels();
    if (mounted) {
      setState(() {
        _plasticLevel = (levels['plastic'] ?? 0) / 100.0;
        _paperLevel = (levels['paper'] ?? 0) / 100.0;
      });
    }
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentLocation = 'Permission denied');
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() => _currentLocation = '${place.locality}, ${place.administrativeArea}');
      }
    } catch (e) {
      if (mounted) setState(() => _currentLocation = 'Location unavailable');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      // Already on home
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())).then((_) => setState(() {}));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EcoShopScreen())).then((_) => setState(() {}));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = LocalAuthBackend.getCurrentUser();
    final String displayName = (user != null && user.name.isNotEmpty) 
        ? user.name.split(' ').first 
        : (user?.email.split('@').first ?? 'Recycler');
    final int points = user?.points ?? 0;
    final int level = user?.level ?? 1;
    final double levelProgress = user?.levelProgress ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F1), // Softer, eco-tinted background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AstraLogo(size: 32),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Level $level', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF94D051))),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 60,
                            height: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: levelProgress,
                                backgroundColor: const Color(0xFF94D051).withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF94D051)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: Color(0xFF94D051), size: 18),
                            const SizedBox(width: 4),
                            Text('$points pts', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),
              
              Text('Hi, $displayName!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              const Text("Small actions, big impact.", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w400)),
              const SizedBox(height: 24),

              // Location Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF94D051).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on, color: Color(0xFF94D051), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Location', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(_currentLocation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text('Bin Fill Levels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildBinLevelCard('Paper Bin', _paperLevel, Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildBinLevelCard('Plastic Bin', _plasticLevel, Colors.blue)),
                ],
              ),
              const SizedBox(height: 28),

              const Text('Your Eco-Forest', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        bool isGrown = (user?.itemsRecycled ?? 0) > (index * 5);
                        return Column(
                          children: [
                            Icon(
                              isGrown ? Icons.park : Icons.eco_outlined,
                              color: isGrown ? const Color(0xFF94D051) : Colors.grey.shade300,
                              size: 40 + (index * 2).toDouble(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isGrown ? 'Grown' : '${(index * 5) - (user?.itemsRecycled ?? 0)} to go',
                              style: TextStyle(fontSize: 10, color: isGrown ? const Color(0xFF94D051) : Colors.grey),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You have planted ${(user?.itemsRecycled ?? 0) ~/ 5} trees so far!',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitChecklistScreen()));
                  if (mounted) setState(() {}); 
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF94D051), Color(0xFF7CB342)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: const Color(0xFF94D051).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Habit Game', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('Earn bonus points for eco-friendly behavior!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            Text('Play Now →', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.emoji_events_rounded, size: 40, color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
              const SizedBox(height: 16),
              if (user != null && user.activities.isNotEmpty)
                ...user.activities.take(3).map((activity) => _buildActivityItem(activity))
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No recent activity. Start recycling!', style: TextStyle(color: Colors.grey))),
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildActivityItem(ActivityRecord activity) {
    IconData icon; Color color;
    switch (activity.type) {
      case 'recycle': icon = Icons.recycling; color = const Color(0xFF4DB6AC); break;
      case 'habit': icon = Icons.check_circle_outline; color = const Color(0xFF94D051); break;
      case 'shop': icon = Icons.shopping_bag_outlined; color = Colors.orange; break;
      default: icon = Icons.notifications_none; color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
                Text(activity.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text('${activity.points > 0 ? "+" : ""}${activity.points} pts', style: TextStyle(fontWeight: FontWeight.bold, color: activity.points > 0 ? const Color(0xFF94D051) : Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildBinLevelCard(String label, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(height: 80, width: 55, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12), topLeft: Radius.circular(4), topRight: Radius.circular(4)), border: Border.all(color: Colors.grey.shade200, width: 2))),
              Container(height: 80 * percentage, width: 55, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.only(bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10), topLeft: percentage > 0.95 ? const Radius.circular(4) : Radius.zero, topRight: percentage > 0.95 ? const Radius.circular(4) : Radius.zero))),
              Positioned(top: 0, child: Container(height: 4, width: 60, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              Positioned(bottom: 30, child: Text('${(percentage * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w900, color: percentage > 0.4 ? Colors.white : color, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      height: 64, width: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
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
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      elevation: 20,
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
    bool isSelected = _selectedIndex == index;
    return IconButton(
      onPressed: () => _onItemTapped(index),
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFF94D051) : Colors.grey.shade400,
        size: 28,
      ),
    );
  }
}
