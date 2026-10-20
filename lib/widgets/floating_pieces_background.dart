import 'dart:math';
import 'package:flutter/material.dart';
import '../game/puzzle_edge_generator.dart';
import '../models/puzzle_piece.dart';

class FloatingPiecesBackground extends StatefulWidget {
  final Widget child;

  const FloatingPiecesBackground({
    super.key,
    required this.child,
  });

  @override
  State<FloatingPiecesBackground> createState() =>
      _FloatingPiecesBackgroundState();
}

class _FloatingPiecesBackgroundState extends State<FloatingPiecesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_FloatingPieceData> _pieces = [];
  final Random _rand = Random(42);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Create 14 floating ambient 3D pieces
    for (int i = 0; i < 14; i++) {
      _pieces.add(
        _FloatingPieceData(
          x: _rand.nextDouble(),
          y: _rand.nextDouble(),
          size: 45.0 + _rand.nextDouble() * 55.0,
          speed: 0.15 + _rand.nextDouble() * 0.25,
          angle: _rand.nextDouble() * 2 * pi,
          rotSpeed: (_rand.nextDouble() - 0.5) * 0.4,
          opacity: 0.08 + _rand.nextDouble() * 0.12,
          color: _palette[_rand.nextInt(_palette.length)],
        ),
      );
    }
  }

  static const List<Color> _palette = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark premium radial gradient backdrop
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.2),
              radius: 1.2,
              colors: [
                Color(0xFF1B1E30),
                Color(0xFF0F111A),
                Color(0xFF08090E),
              ],
            ),
          ),
        ),

        // Animated floating pieces layer
        AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _FloatingPiecesPainter(
                pieces: _pieces,
                progress: _animController.value,
              ),
            );
          },
        ),

        // Child Screen
        widget.child,
      ],
    );
  }
}

class _FloatingPieceData {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double angle;
  final double rotSpeed;
  final double opacity;
  final Color color;

  _FloatingPieceData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.rotSpeed,
    required this.opacity,
    required this.color,
  });
}

class _FloatingPiecesPainter extends CustomPainter {
  final List<_FloatingPieceData> pieces;
  final double progress;

  _FloatingPiecesPainter({
    required this.pieces,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      // Compute animated position
      final currentY = (p.y - (progress * p.speed)) % 1.0;
      final posX = p.x * size.width;
      final posY = currentY * size.height;
      final rot = p.angle + (progress * p.rotSpeed * 2 * pi);

      canvas.save();
      canvas.translate(posX, posY);
      canvas.rotate(rot);

      final path = PuzzleEdgeGenerator.buildPiecePath(
        width: p.size,
        height: p.size,
        top: EdgeShape.outTab,
        right: EdgeShape.inTab,
        bottom: EdgeShape.outTab,
        left: EdgeShape.inTab,
      );

      // Ambient drop shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(p.opacity * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.save();
      canvas.translate(4, 6);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();

      // Translucent tinted piece surface
      final fillPaint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Subtle edge highlight
      final strokePaint = Paint()
        ..color = Colors.white.withOpacity(p.opacity * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, strokePaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingPiecesPainter oldDelegate) => true;
}
