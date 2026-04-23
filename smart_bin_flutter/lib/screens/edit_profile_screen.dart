import 'package:flutter/material.dart';
import '../backend/local_auth_backend.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    var user = LocalAuthBackend.getCurrentUser();
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _genderController.text = user.gender;
      _dobController.text = user.dob;
    }
  }

  void _handleSave() async {
    // 1. Force the keyboard to disappear immediately
    FocusManager.instance.primaryFocus?.unfocus();

    // Give the keyboard 100ms to visually slide down so it doesn't freeze the screen transition
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() => _isLoading = true);
    bool success = false;

    try {
      await LocalAuthBackend.updateUserProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        gender: _genderController.text,
        dob: _dobController.text,
      );
      success = true;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error saving profile.")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // Safely pop only if the build context is still alive
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Color(0xFFE6F0FF), child: Icon(Icons.person, size: 50, color: Colors.grey)),
                  Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF94D051), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 14, color: Colors.white)))
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildLabel('Full Name'), _buildTextField(_nameController), const SizedBox(height: 16),
            _buildLabel('Email'), _buildTextField(_emailController, isEmail: true), const SizedBox(height: 16),
            _buildLabel('Phone'), _buildTextField(_phoneController, isNumber: true), const SizedBox(height: 16),
            _buildLabel('Gender'), _buildTextField(_genderController), const SizedBox(height: 16),
            _buildLabel('Date of Birth'), _buildTextField(_dobController), const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF94D051), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0, left: 4.0), child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))));
  }

  Widget _buildTextField(TextEditingController controller, {bool isEmail = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : (isNumber ? TextInputType.phone : TextInputType.text),
      decoration: InputDecoration(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF94D051), width: 2)),
      ),
    );
  }
}