import 'package:flutter/material.dart';
import '../../theme/snip_colors.dart';

/// The official SNIP logo with crossed scissors forming an 'S' shape.
class SnipLogo extends StatelessWidget {
  const SnipLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.showTagline = false,
    this.textColor,
    this.primaryColor = SnipColors.primary,
  });

  final double size;
  final bool showText;
  final bool showTagline;
  final Color? textColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? SnipColors.dark;

    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SnipScissorsPainter(color: primaryColor),
      ),
    );

    if (!showText) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        SizedBox(width: size * 0.28),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SNIP',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: size * 0.72,
                letterSpacing: 1.2,
                color: effectiveTextColor,
                height: 1.0,
              ),
            ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              Text(
                'BOOK • MANAGE • GROW',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.22,
                  letterSpacing: 1.1,
                  color: primaryColor,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SnipScissorsPainter extends CustomPainter {
  const _SnipScissorsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.13;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Draw top-left handle loop
    final topLoopCenter = Offset(w * 0.35, h * 0.30);
    final loopRadius = w * 0.20;
    canvas.drawCircle(topLoopCenter, loopRadius, strokePaint);

    // Draw bottom-right handle loop
    final bottomLoopCenter = Offset(w * 0.65, h * 0.70);
    canvas.drawCircle(bottomLoopCenter, loopRadius, strokePaint);

    // Diagonal blade 1: from top-left loop to bottom-left blade tip
    final blade1 = Path()
      ..moveTo(w * 0.45, h * 0.35)
      ..lineTo(w * 0.78, h * 0.20);
    canvas.drawPath(blade1, strokePaint);

    // Diagonal blade 2: from bottom-right loop to top-right blade tip
    final blade2 = Path()
      ..moveTo(w * 0.55, h * 0.65)
      ..lineTo(w * 0.22, h * 0.80);
    canvas.drawPath(blade2, strokePaint);

    // Central pivot dot
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), strokeWidth * 0.7, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SnipScissorsPainter oldDelegate) =>
      oldDelegate.color != color;
}
