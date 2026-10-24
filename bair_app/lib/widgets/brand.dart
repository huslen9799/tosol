import 'package:flutter/material.dart';

class AppColors {
  static const turquoise = Color(0xFF83E6D6);
  static const blue = Color(0xFF83C5E6);
  static const lavender = Color(0xFF8394E6);
  static const primary = Color(0xFF83E6D6);
  static const active = Color(0xFF8394E6);
  static const light = Color(0xFFEDFBF8);
  static const background = Color(0xFFF7FAFD);
  static const text = Colors.black;
  static const secondaryText = Colors.black;
  static const muted = Color(0xFF8796AD);
  static const border = Color(0xFFDCE6F4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 34});
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _HouseMark()),
  );
}

class _HouseMark extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeJoin = StrokeJoin.miter;
    final path = Path()
      ..moveTo(size.width * .12, size.height * .40)
      ..lineTo(size.width * .5, size.height * .08)
      ..lineTo(size.width * .88, size.height * .40)
      ..lineTo(size.width * .88, size.height * .90)
      ..lineTo(size.width * .12, size.height * .90)
      ..close();
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.fill;
    for (final x in [.39, .53]) {
      for (final y in [.48, .63]) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * x,
            size.height * y,
            size.width * .1,
            size.height * .1,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
