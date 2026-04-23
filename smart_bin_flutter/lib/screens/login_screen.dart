import 'package:flutter/material.dart';
import '../backend/local_auth_backend.dart';
import '../widgets/shared_widgets.dart';
import 'sign_up_screen.dart';
import 'home_screen.dart';
import 'reset_password_screen.dart'; // <-- Make sure this is imported!

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePass = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _handleLogin() async {
    setState(() => _isLoading = true);

    bool success = await LocalAuthBackend.loginUser(_emailController.text, _passController.text);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Welcome back!")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid email or password.")));
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hi, Welcome! 👋',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900, // Extra Bold
                  color: Color(0xFF4A4A4A)
              ),
            ),
            const SizedBox(height: 32),

            const Text('Email address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(hintText: 'Your email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
            const SizedBox(height: 8),
            TextField(
              controller: _passController,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                hintText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: const Color(0xFF94D051),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => setState(() => _rememberMe = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Remember me', style: TextStyle(fontSize: 14, color: Color(0xFF4A4A4A), fontWeight: FontWeight.w500)),
                  ],
                ),
                // --- UPDATED FORGOT PASSWORD BUTTON ---
                TextButton(
                  onPressed: () {
                    // Navigate to Reset Password Screen and pass the email
                    String emailToReset = _emailController.text.isNotEmpty
                        ? _emailController.text
                        : 'admin@admin.com'; // Default to our test account if empty

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResetPasswordScreen(email: emailToReset),
                      ),
                    );
                  },
                  child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.w600)),
                )
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Log in'),
              ),
            ),
            const SizedBox(height: 32),

            const SocialDividers(text: 'Or with'),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: buildSocialButton(
                    context,
                    Icons.facebook,
                    'Facebook',
                    Colors.blue,
                    () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildSocialButton(
                    context,
                    Icons.g_mobiledata,
                    'Google',
                    Colors.red,
                    () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                    iconSize: 32,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(text: 'Sign up', style: TextStyle(color: Color(0xFF94D051), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}