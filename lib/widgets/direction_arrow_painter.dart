import 'package:flutter/material.dart';

/// Custom Painter untuk menggambar panah arah (direction arrow) yang mengikuti compass
/// Digunakan di Maps Screen untuk menunjukkan arah hadap user
class DirectionArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4285F4) // Google Maps blue
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Draw triangle arrow pointing up (north)
    // Top point (ujung panah)
    path.moveTo(size.width / 2, 0);
    // Bottom left (kiri bawah)
    path.lineTo(size.width / 2 - 8, size.height / 2 + 4);
    // Bottom right (kanan bawah)
    path.lineTo(size.width / 2 + 8, size.height / 2 + 4);
    // Close path
    path.close();

    // Draw shadow untuk depth effect
    canvas.drawShadow(path, Colors.black.withOpacity(0.3), 3.0, false);
    
    // Draw arrow
    canvas.drawPath(path, paint);
    
    // Draw white border untuk visibility
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
