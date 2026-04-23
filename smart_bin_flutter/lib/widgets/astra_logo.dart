import 'package:flutter/material.dart';

class AstraLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AstraLogo({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // If no color is provided, we use the brand green. 
    // On the Opening Screen, we pass white.
    final Color mainColor = color ?? const Color(0xFF94D051);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Decorative background glow/circle
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
            // The Leaf/Eco Icon
            Icon(
              Icons.eco_rounded,
              size: size * 0.7,
              color: mainColor,
            ),
            // The "Astra" Star element
            Positioned(
              top: size * 0.1,
              right: size * 0.1,
              child: Icon(
                Icons.auto_awesome,
                size: size * 0.3,
                color: mainColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // The Team Name
        Text(
          'ASTRA',
          style: TextStyle(
            color: mainColor,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.25,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
