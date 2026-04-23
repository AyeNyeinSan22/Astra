import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backend/local_auth_backend.dart';
import 'dart:math';

class HabitChecklistScreen extends StatefulWidget {
  const HabitChecklistScreen({super.key});

  @override
  State<HabitChecklistScreen> createState() => _HabitChecklistScreenState();
}

class _HabitChecklistScreenState extends State<HabitChecklistScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _missionPool = [
    {'title': 'Used a reusable water bottle', 'icon': Icons.local_drink_rounded, 'points': 15, 'co2': 12.0, 'category': 'Waste', 'rarity': 'Common'},
    {'title': 'Avoided plastic straws', 'icon': Icons.eco_rounded, 'points': 10, 'co2': 5.0, 'category': 'Plastic', 'rarity': 'Common'},
    {'title': 'Recycled paper/cardboard', 'icon': Icons.description_rounded, 'points': 25, 'co2': 35.0, 'category': 'Recycle', 'rarity': 'Rare'},
    {'title': 'Used a cloth bag for shopping', 'icon': Icons.shopping_bag_rounded, 'points': 20, 'co2': 15.0, 'category': 'Plastic', 'rarity': 'Common'},
    {'title': 'Turned off lights when leaving', 'icon': Icons.lightbulb_rounded, 'points': 10, 'co2': 50.0, 'category': 'Energy', 'rarity': 'Common'},
    {'title': 'Composted organic waste', 'icon': Icons.bakery_dining_rounded, 'points': 40, 'co2': 120.0, 'category': 'Organic', 'rarity': 'Epic'},
    {'title': 'Walked or biked for a short trip', 'icon': Icons.directions_bike_rounded, 'points': 50, 'co2': 450.0, 'category': 'Carbon', 'rarity': 'Epic'},
    {'title': 'Unplugged unused electronics', 'icon': Icons.power_off_rounded, 'points': 15, 'co2': 30.0, 'category': 'Energy', 'rarity': 'Common'},
    {'title': 'Used a reusable coffee cup', 'icon': Icons.coffee_rounded, 'points': 20, 'co2': 18.0, 'category': 'Waste', 'rarity': 'Common'},
    {'title': 'Picked up 3 pieces of litter', 'icon': Icons.cleaning_services_rounded, 'points': 35, 'co2': 10.0, 'category': 'Community', 'rarity': 'Rare'},
  ];

  late List<Map<String, dynamic>> _dailyMissions;
  final Set<int> _completedIndices = {};

  @override
  void initState() {
    super.initState();
    final random = Random();
    _dailyMissions = List.from(_missionPool)..shuffle(random);
    _dailyMissions = _dailyMissions.take(4).toList();
  }

  int get _totalEarned => _completedIndices.fold(0, (sum, index) => sum + (_dailyMissions[index]['points'] as int));
  double get _totalCo2 => _completedIndices.fold(0.0, (sum, index) => sum + (_dailyMissions[index]['co2'] as double));
  double get _completionPercent => _dailyMissions.isEmpty ? 0 : _completedIndices.length / _dailyMissions.length;

  @override
  Widget build(BuildContext context) {
    final user = LocalAuthBackend.getCurrentUser();
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1E),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(user),
          SliverToBoxAdapter(child: _buildRanksHeader(user)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildMissionCard(index),
                childCount: _dailyMissions.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomSheet: _buildRewardPanel(),
    );
  }

  Widget _buildSliverAppBar(UserModel? user) {
    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A1C1E),
      leading: IconButton(
        icon: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.close, color: Colors.white, size: 20)),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -40, bottom: -20,
              child: AnimatedScale(
                scale: 1.0 + (_completionPercent * 0.2),
                duration: const Duration(milliseconds: 500),
                child: Icon(
                  Icons.public,
                  size: 260,
                  color: Color.lerp(
                    Colors.grey.withValues(alpha: 0.1),
                    const Color(0xFF94D051).withValues(alpha: 0.2),
                    _completionPercent,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF94D051), borderRadius: BorderRadius.circular(6)),
                    child: const Text('ACTIVATE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Eco-Warrior\nQuests', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildHeaderStat(Icons.local_fire_department_rounded, '${user?.dailyStreak ?? 0}d Streak', Colors.orange),
                      const SizedBox(width: 12),
                      _buildHeaderStat(Icons.auto_awesome, 'Multiplier x1.${(user?.dailyStreak ?? 0) > 5 ? 5 : 2}', Colors.cyanAccent),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRanksHeader(UserModel? user) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRESS: ${(_completionPercent * 100).toInt()}%', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              Text('${_completedIndices.length}/${_dailyMissions.length} COMPLETED', style: const TextStyle(color: Color(0xFF94D051), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _completionPercent,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF94D051)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(int index) {
    final mission = _dailyMissions[index];
    final isDone = _completedIndices.contains(index);
    final rarityColor = _getRarityColor(mission['rarity']);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDone ? Colors.white.withValues(alpha: 0.02) : const Color(0xFF25282B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDone ? Colors.transparent : Colors.white.withValues(alpha: 0.05)),
          boxShadow: isDone ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              if (isDone) {
              _completedIndices.remove(index);
            } else {
              _completedIndices.add(index);
            }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 54, width: 54,
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(mission['icon'], color: rarityColor, size: 28),
                    ),
                    if (isDone)
                      const Icon(Icons.check_circle, color: Color(0xFF94D051), size: 24),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: rarityColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(mission['rarity'].toUpperCase(), style: TextStyle(color: rarityColor, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 4),
                      Text(mission['title'], style: TextStyle(color: isDone ? Colors.grey : Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: isDone ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 2),
                      Text('${mission['category']} • Save ${mission['co2']}g CO2', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('+${mission['points']}', style: TextStyle(color: isDone ? Colors.grey : const Color(0xFF94D051), fontWeight: FontWeight.w900, fontSize: 18)),
                    const Text('XP', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Epic': return Colors.deepPurpleAccent;
      case 'Rare': return Colors.blueAccent;
      default: return const Color(0xFF94D051);
    }
  }

  Widget _buildRewardPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF25282B),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('QUEST REWARDS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text('$_totalEarned PTS • ${_totalCo2.toInt()}g CO2', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
              if (_completionPercent == 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Text('BONUS: +50 XP', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                )
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _completedIndices.isEmpty ? null : () async {
              int bonusPoints = (_completionPercent == 1.0 ? 50 : 0);
              await LocalAuthBackend.addImpact(
                title: 'Completed Daily Quest',
                points: _totalEarned + bonusPoints,
                co2: _totalCo2,
                items: 0, // Habits don't count as recycled items, but we could count them if we wanted
                type: 'habit',
              );
              if (mounted) _showLevelUpCelebration(context, _totalEarned + bonusPoints, _totalCo2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF94D051),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('CLAIM LOOT & COMPLETE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  void _showLevelUpCelebration(BuildContext context, int points, double co2) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFF94D051), size: 120),
                const SizedBox(height: 24),
                const Text('QUEST COMPLETE!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('You earned $points XP and saved ${co2.toInt()}g of CO2 today!', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('RETURN TO BASE'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
