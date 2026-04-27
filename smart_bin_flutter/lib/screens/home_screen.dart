import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../backend/bin_level_service.dart';
import '../backend/local_auth_backend.dart';
import '../widgets/astra_logo.dart';
import '../wifi_bin_monitor.dart';
import 'eco_shop_screen.dart';
import 'edit_profile_screen.dart';
import 'habit_checklist_screen.dart';
import 'scanner_opening_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _currentLocation = 'Fetching location...';

  // Bin fill levels (0.0 – 1.0), updated in real-time from Firebase.
  double _plasticLevel = 0.0;
  double _paperLevel   = 0.0;
  double _metalLevel   = 0.0;

  // Firebase real-time subscription – cancelled in dispose().
  StreamSubscription<BinLevels>? _levelSubscription;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _startLevelMonitoring();
  }

  @override
  void dispose() {
    // Always cancel stream subscriptions to prevent memory leaks.
    _levelSubscription?.cancel();
    super.dispose();
  }

  /// Subscribe to Firebase Realtime Database for live bin-fill updates.
  ///
  /// The Arduino bridge pushes a new snapshot every ~3 seconds, so the UI
  /// updates automatically without any manual polling or timer.
  void _startLevelMonitoring() {
    _levelSubscription = BinLevelService.levelsStream().listen(
      (BinLevels levels) {
        if (!mounted) return;
        setState(() {
          _plasticLevel = levels.plastic / 100.0;
          _paperLevel   = levels.paper   / 100.0;
          _metalLevel   = levels.metal   / 100.0;
        });
      },
      onError: (_) {
        // Firebase not yet configured or offline – keep showing zeros.
      },
    );
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
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks[0];
        setState(() =>
            _currentLocation = '${place.locality}, ${place.administrativeArea}');
      }
    } catch (_) {
      if (mounted) setState(() => _currentLocation = 'Location unavailable');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()))
          .then((_) => setState(() {}));
    } else if (index == 3) {
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EcoShopScreen()))
          .then((_) => setState(() {}));
    } else if (index == 4) {
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()))
          .then((_) => setState(() {}));
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
      backgroundColor: const Color(0xFFF1F4F1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AstraLogo(size: 32),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Level $level',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF94D051))),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 60,
                            height: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: levelProgress,
                                backgroundColor: const Color(0xFF94D051)
                                    .withValues(alpha: 0.1),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF94D051)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.05),
                                blurRadius: 5)
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars,
                                color: Color(0xFF94D051), size: 18),
                            const SizedBox(width: 4),
                            Text('$points pts',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3142))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text('Hi, $displayName!',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142))),
              const Text('Small actions, big impact.',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400)),
              const SizedBox(height: 24),

              // ── Location Card ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: const Color(0xFF94D051).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.location_on,
                          color: Color(0xFF94D051), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Location',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(_currentLocation,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3142))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Bin Fill Levels (live from Firebase) ──────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bin Fill Levels',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142))),
                  // Small Firebase live indicator dot
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFF94D051), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      const Text('Live',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94D051),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Three bin cards in a row
              Row(
                children: [
                  Expanded(
                      child: _buildBinLevelCard(
                          'Paper', _paperLevel, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildBinLevelCard(
                          'Plastic', _plasticLevel, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildBinLevelCard(
                          'Metal', _metalLevel, Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 12),

              // Optional: manual Wi-Fi monitor for local debugging
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WifiBinMonitor())),
                icon: const Icon(Icons.wifi, size: 18),
                label: const Text('Manual Wi-Fi Monitor'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 28),

              // ── Eco-Forest ────────────────────────────────────
              const Text('Your Eco-Forest',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142))),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        final grown =
                            (user?.itemsRecycled ?? 0) > (index * 5);
                        return Column(
                          children: [
                            Icon(
                              grown ? Icons.park : Icons.eco_outlined,
                              color: grown
                                  ? const Color(0xFF94D051)
                                  : Colors.grey.shade300,
                              size: 40 + (index * 2).toDouble(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              grown
                                  ? 'Grown'
                                  : '${(index * 5) - (user?.itemsRecycled ?? 0)} to go',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: grown
                                      ? const Color(0xFF94D051)
                                      : Colors.grey),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You have planted ${(user?.itemsRecycled ?? 0) ~/ 5} trees so far!',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3142)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Daily Habit Game ──────────────────────────────
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const HabitChecklistScreen()));
                  if (mounted) setState(() {});
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF94D051), Color(0xFF7CB342)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xFF94D051).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Habit Game',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('Earn bonus points for eco-friendly behavior!',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            Text('Play Now →',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.emoji_events_rounded,
                            size: 40, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Recent Activity ───────────────────────────────
              const Text('Recent Activity',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142))),
              const SizedBox(height: 16),
              if (user != null && user.activities.isNotEmpty)
                ...user.activities
                    .take(3)
                    .map((a) => _buildActivityItem(a))
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: Text('No recent activity. Start recycling!',
                          style: TextStyle(color: Colors.grey))),
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

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _buildActivityItem(ActivityRecord activity) {
    IconData icon;
    Color color;
    switch (activity.type) {
      case 'recycle':
        icon = Icons.recycling;
        color = const Color(0xFF4DB6AC);
        break;
      case 'habit':
        icon = Icons.check_circle_outline;
        color = const Color(0xFF94D051);
        break;
      case 'shop':
        icon = Icons.shopping_bag_outlined;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications_none;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D3142))),
                Text(activity.date,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${activity.points > 0 ? "+" : ""}${activity.points} pts',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: activity.points > 0
                    ? const Color(0xFF94D051)
                    : Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildBinLevelCard(String label, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                  height: 70,
                  width: 44,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4)),
                      border: Border.all(
                          color: Colors.grey.shade200, width: 2))),
              Container(
                  height: 70 * percentage,
                  width: 44,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.only(
                          bottomLeft: const Radius.circular(8),
                          bottomRight: const Radius.circular(8),
                          topLeft: percentage > 0.95
                              ? const Radius.circular(4)
                              : Radius.zero,
                          topRight: percentage > 0.95
                              ? const Radius.circular(4)
                              : Radius.zero))),
              Positioned(
                  top: 0,
                  child: Container(
                      height: 4,
                      width: 48,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
              Positioned(
                  bottom: 24,
                  child: Text(
                    '${(percentage * 100).toInt()}%',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color:
                            percentage > 0.4 ? Colors.white : color,
                        fontSize: 12),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142))),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.qr_code_scanner,
            color: Color(0xFF94D051), size: 30),
        onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ScannerOpeningScreen()))
            .then((_) => setState(() {})),
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
    final bool isSelected = _selectedIndex == index;
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
