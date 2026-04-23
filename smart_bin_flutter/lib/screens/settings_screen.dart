import 'package:flutter/material.dart';
import '../backend/local_auth_backend.dart';
import 'account_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = LocalAuthBackend.getCurrentUser();
    final String displayName = (user != null && user.name.isNotEmpty) ? user.name : 'Sammy';
    final String email = user?.email ?? 'sammy@example.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF94D051), width: 2)),
                        child: const CircleAvatar(radius: 50, backgroundColor: Color(0xFFF6FBF2), child: Icon(Icons.person, size: 60, color: Color(0xFF94D051))),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFF94D051), shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Settings Sections
            _buildSectionHeader('Account'),
            _buildSettingsItem(Icons.person_outline, 'Personal Information', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()))),
            _buildSettingsItem(Icons.history, 'Recycling History', () {}),
            _buildSettingsItem(Icons.stars_rounded, 'My Rewards', () {}),
            
            const SizedBox(height: 24),
            _buildSectionHeader('App Settings'),
            _buildSettingsItem(Icons.notifications_none_rounded, 'Notifications', () {}),
            _buildSettingsItem(Icons.language_rounded, 'Language', () {}),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Support'),
            _buildSettingsItem(Icons.help_outline_rounded, 'Help Center', () {}),
            _buildSettingsItem(Icons.info_outline_rounded, 'About Smart Bin', () {}),
            
            const SizedBox(height: 40),
            // Logout Button
            OutlinedButton(
              onPressed: () {
                LocalAuthBackend.logout();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              },
              child: const Text('Log out'),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF94D051)),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2D3142))),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
