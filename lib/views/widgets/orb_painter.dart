import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/mind_orb.dart';

class OrbPaintData {
  const OrbPaintData({
    required this.emotion,
    required this.position,
    required this.radius,
    required this.phase,
  });

  final EmotionType emotion;
  final Offset position;
  final double radius;
  final double phase;
}

class StarfieldPainter extends CustomPainter {
  const StarfieldPainter();

  static final List<_Star> _stars = _buildStars();

  static List<_Star> _buildStars() {
    final random = math.Random(20261018);
    return List.generate(96, (_) {
      return _Star(
        dx: random.nextDouble(),
        dy: random.nextDouble(),
        radius: random.nextDouble() * 1.3 + 0.3,
        alpha: random.nextDouble() * 0.55 + 0.15,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in _stars) {
      paint.color = AppColors.starlightWhite.withValues(alpha: star.alpha);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) => false;
}

class OrbPainter extends CustomPainter {
  const OrbPainter({required this.orbs, required this.time});

  final List<OrbPaintData> orbs;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in orbs) {
      _paintOrb(canvas, orb);
    }
  }

  void _paintOrb(Canvas canvas, OrbPaintData orb) {
    final color = orb.emotion.color;
    final pulse = switch (orb.emotion) {
      EmotionType.anger => 0.08 * math.sin(time * 8 + orb.phase),
      EmotionType.calm => 0.045 * math.sin(time * 1.4 + orb.phase),
      EmotionType.sadness => 0.03 * math.sin(time * 1.1 + orb.phase),
      EmotionType.joy => 0.05 * math.sin(time * 2.2 + orb.phase),
      EmotionType.anxiety => 0.06 * math.sin(time * 1.6 + orb.phase),
    };
    final radius = orb.radius * (1 + pulse);

    if (orb.emotion == EmotionType.anxiety) {
      canvas.drawCircle(
        orb.position,
        radius * 3.1,
        Paint()
          ..shader = ui.Gradient.radial(
            orb.position,
            radius * 3.1,
            [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0),
            ],
            const [0, 0.45, 1],
          ),
      );
    }

    final glowRadius = orb.emotion == EmotionType.anger
        ? radius * 2.05
        : radius * 2.55;
    canvas.drawCircle(
      orb.position,
      glowRadius,
      Paint()
        ..shader = ui.Gradient.radial(orb.position, glowRadius, [
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0),
        ]),
    );

    if (orb.emotion == EmotionType.sadness) {
      final wave = (time * 0.6 + orb.phase) % 1;
      canvas.drawCircle(
        orb.position,
        radius * (1.2 + wave * 0.8),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = color.withValues(alpha: (1 - wave) * 0.7),
      );
      canvas.drawCircle(
        orb.position,
        radius * 1.28,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.85),
      );
    }

    final shade = Color.lerp(color, const Color(0xFF000000), 0.35)!;
    canvas.drawCircle(
      orb.position,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          orb.position + Offset(-radius * 0.28, -radius * 0.32),
          radius,
          [const Color(0xFFFFFFFF).withValues(alpha: 0.95), color, shade],
          const [0, 0.42, 1],
        ),
    );

    if (orb.emotion == EmotionType.joy) {
      final spark = Paint()..color = const Color(0xFFFFF4C2);
      for (var i = 0; i < 4; i++) {
        final angle = time * 1.8 + orb.phase + i * math.pi / 2;
        canvas.drawCircle(
          orb.position +
              Offset(math.cos(angle) * radius * 1.55, math.sin(angle) * radius * 1.55),
          1.7,
          spark,
        );
      }
    }

    if (orb.emotion == EmotionType.anger) {
      final spike = (math.sin(time * 8 + orb.phase) + 1) / 2;
      canvas.drawCircle(
        orb.position,
        radius * (1.15 + spike * 0.28),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = color.withValues(alpha: 0.35 + spike * 0.65),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) => true;
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.alpha,
  });

  final double dx;
  final double dy;
  final double radius;
  final double alpha;
}
