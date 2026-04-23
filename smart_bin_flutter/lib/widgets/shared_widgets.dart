import 'package:flutter/material.dart';
import '../backend/local_auth_backend.dart';

class SocialDividers extends StatelessWidget {
  final String text;
  const SocialDividers({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }
}

// Helper for the 3-icon row in Signup
Widget buildSocialRow(BuildContext context, VoidCallback onSuccess) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      buildIconBox(context, Icons.facebook, Colors.blue, "Facebook", onSuccess),
      buildIconBox(context, Icons.g_mobiledata, Colors.red, "Google", onSuccess, size: 40),
      buildIconBox(context, Icons.apple, Colors.black, "Apple", onSuccess),
    ],
  );
}

Widget buildIconBox(BuildContext context, IconData icon, Color color, String provider, VoidCallback onSuccess, {double size = 28}) {
  return GestureDetector(
    onTap: () => _handleSocialAuth(context, provider, onSuccess),
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(child: Icon(icon, color: color, size: size)),
    ),
  );
}

// Helper for the Text+Icon buttons in Login
Widget buildSocialButton(BuildContext context, IconData icon, String label, Color iconColor, VoidCallback onSuccess, {double iconSize = 24}) {
  return GestureDetector(
    onTap: () => _handleSocialAuth(context, label, onSuccess),
    child: Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    ),
  );
}

void _handleSocialAuth(BuildContext context, String provider, VoidCallback onSuccess) async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF94D051))),
  );

  // Simulate OAuth process
  await Future.delayed(const Duration(seconds: 1));
  
  // Register/Login in backend
  String email = "eco_user@${provider.toLowerCase().replaceAll(' ', '')}.com";
  await LocalAuthBackend.registerUser(email, "social_auth_123");
  await LocalAuthBackend.loginUser(email, "social_auth_123");

  if (context.mounted) {
    Navigator.pop(context); // Remove loading
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Authenticated via $provider!")));
    onSuccess();
  }
}
