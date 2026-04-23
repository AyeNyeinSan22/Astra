import 'package:flutter/material.dart';
import '../widgets/astra_logo.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

class OpeningScreen extends StatelessWidget {
  const OpeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Column(
        children: [
          // Wavy Header with Leaf Icons
          ClipPath(
            clipper: WavyHeaderClipper(),
            child: Container(
              height: size.height * 0.50, // Slightly reduced to give more space below
              width: double.infinity,
              color: const Color(0xFF94D051),
              child: Stack(
                children: [
                  // Background Decorative Icons
                  Positioned(
                    top: 60,
                    left: -20,
                    child: Icon(Icons.eco_rounded, size: 100, color: Colors.white.withOpacity(0.2)),
                  ),
                  Positioned(
                    bottom: 100,
                    right: -30,
                    child: Icon(Icons.recycling_rounded, size: 120, color: Colors.white.withOpacity(0.2)),
                  ),

                  // Adjusted Logo - ensured it fits and is visible
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: AstraLogo(size: 100, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Small actions,\nbig impact.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D3142),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '“Reduce waste, reuse the past,\nrecycle for a future that will last.”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const Spacer(),

                  // Sign In Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),

                  // Create Account Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                    },
                    child: const Text('Create account'),
                  ),
                  
                  // Bottom Padding to ensure "Create account" is not touching the bar
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavyHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.75, size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
