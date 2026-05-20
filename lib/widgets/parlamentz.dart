import 'package:flutter/material.dart';

import '../data/models/user_profile.dart';

/// Minimalistisches, rundes Indikator-Widget zur Darstellung der
/// politischen Orientierung (`Parlamentz`).
class ParlamentzIndicator extends StatelessWidget {
  const ParlamentzIndicator({super.key, required this.leaning, this.size = 72});

  final PoliticalLeaning leaning;
  final double size;

  Color _colorForLeaning(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (leaning) {
      case PoliticalLeaning.left:
        return Colors.redAccent;
      case PoliticalLeaning.centerLeft:
        return Colors.deepPurpleAccent;
      case PoliticalLeaning.neutral:
        return scheme.outline;
      case PoliticalLeaning.liberal:
        return Colors.lightBlueAccent;
      case PoliticalLeaning.conservative:
        return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForLeaning(context);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ParlamentzPainter(color: color)),
    );
  }
}

class _ParlamentzPainter extends CustomPainter {
  _ParlamentzPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..color = color.withAlpha((0.95 * 255).round())
      ..strokeCap = StrokeCap.round;

    // Outer ring
    canvas.drawCircle(center, radius, ringPaint);

    // Inner dot
    final dotPaint = Paint()..color = color.withAlpha((0.95 * 255).round());
    canvas.drawCircle(center, size.width * 0.08, dotPaint);

    // Decorative tiny arc to suggest 'seats'
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..color = color.withAlpha((0.6 * 255).round())
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - (size.width * 0.06),
    );
    canvas.drawArc(rect, -3.1, 1.4, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
