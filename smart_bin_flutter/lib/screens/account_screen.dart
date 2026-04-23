import 'package:flutter/material.dart';
import '../backend/local_auth_backend.dart';
import 'edit_profile_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (mounted) {
      setState(() {
        currentUser = LocalAuthBackend.getCurrentUser();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Account', style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.bold)),
      ),
      body: currentUser == null
          ? const Center(child: Text("No user logged in"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF94D051), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.grey)),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 12, color: Color(0xFF94D051)),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUser!.name.isEmpty ? (currentUser!.email.split('@').first) : currentUser!.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Gender - ${currentUser!.gender.isEmpty ? 'N/A' : currentUser!.gender}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      Text('Age - ${currentUser!.age.isEmpty ? 'N/A' : currentUser!.age} year', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Account Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A4A4A))),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  _buildDetailTile(Icons.person_outline, 'General info', () async {
                    final didUpdate = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    if (didUpdate == true) {
                      _loadUserData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully!")));
                      }
                    }
                  }),
                  Divider(color: Colors.grey.shade200, height: 1),
                  _buildDetailTile(Icons.lock_outline, 'Password', () {}),
                  Divider(color: Colors.grey.shade200, height: 1),
                  _buildDetailTile(Icons.mail_outline, 'Contact info', () {}),
                ],
              ),
            )
          ],
        ),
      ),

      // --- THE NUCLEAR FIX: A FAKE FAB ---
      floatingActionButton: _buildFakeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFakeFab() {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3))]),
      child: IconButton(icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF94D051), size: 30), onPressed: () {}),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF4A4A4A))),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
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
            IconButton(icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28), onPressed: () {}),
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