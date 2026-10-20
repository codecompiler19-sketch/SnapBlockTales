import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/puzzle_piece.dart';
import 'puzzle_edge_generator.dart';

class PuzzlePiecePainter extends CustomPainter {
  final ui.Image? image;
  final PuzzlePiece piece;
  final double pieceWidth;
  final double pieceHeight;
  final double boardWidth;
  final double boardHeight;
  final bool isLifted;
  final bool isHighlighted;
  final bool isMysteryHidden;
  final bool isTileMode;
  final bool showNumberBadge;
  final double highlightPulse;

  PuzzlePiecePainter({
    required this.image,
    required this.piece,
    required this.pieceWidth,
    required this.pieceHeight,
    required this.boardWidth,
    required this.boardHeight,
    this.isLifted = false,
    this.isHighlighted = false,
    this.isMysteryHidden = false,
    this.isTileMode = true,
    this.showNumberBadge = false,
    this.highlightPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2.5, 2.5, pieceWidth - 5.0, pieceHeight - 5.0);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10.0));

    // 1. Build clip path
    Path path;
    if (isTileMode) {
      path = Path()..addRRect(rrect);
    } else {
      path = PuzzleEdgeGenerator.buildPiecePath(
        width: pieceWidth,
        height: pieceHeight,
        top: piece.topEdge,
        right: piece.rightEdge,
        bottom: piece.bottomEdge,
        left: piece.leftEdge,
      );
    }

    // 2. Draw 3D Drop Shadow
    final shadowPaint = Paint()..style = PaintingStyle.fill;
    if (isLifted) {
      shadowPaint
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.save();
      canvas.translate(6.0, 10.0);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    } else if (!piece.isCorrect) {
      shadowPaint
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.save();
      canvas.translate(2.0, 3.0);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    // 3. Draw Clipped Image Portion
    canvas.save();
    canvas.clipPath(path);

    if (isMysteryHidden && !piece.isPlaced) {
      final mysteryPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(pieceWidth, pieceHeight),
          [
            const Color(0xFF2A2A40),
            const Color(0xFF1E1E2E),
            const Color(0xFF383854),
          ],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, pieceWidth, pieceHeight), mysteryPaint);

      final iconPainter = TextPainter(
        text: const TextSpan(
          text: '?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0x44FFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(
          (pieceWidth - iconPainter.width) / 2,
          (pieceHeight - iconPainter.height) / 2,
        ),
      );
    } else if (image != null) {
      // Clamped source rect strictly within [0, 0, image.width, image.height]
      final double srcX = (piece.normX * image!.width).clamp(0.0, image!.width.toDouble());
      final double srcY = (piece.normY * image!.height).clamp(0.0, image!.height.toDouble());
      final double srcW = (piece.normWidth * image!.width).clamp(1.0, image!.width - srcX);
      final double srcH = (piece.normHeight * image!.height).clamp(1.0, image!.height - srcY);

      final srcRect = Rect.fromLTWH(srcX, srcY, srcW, srcH);
      final dstRect = Rect.fromLTWH(0, 0, pieceWidth, pieceHeight);

      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium;

      canvas.drawImageRect(image!, srcRect, dstRect, paint);

      // Specular surface sheen
      final sheenPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(pieceWidth, pieceHeight),
          [
            Colors.white.withOpacity(isLifted ? 0.22 : 0.08),
            Colors.white.withOpacity(0.0),
            Colors.black.withOpacity(0.12),
          ],
        );
      canvas.drawPaint(sheenPaint);
    } else {
      final fallbackPaint = Paint()..color = const Color(0xFF455A64);
      canvas.drawPaint(fallbackPaint);
    }

    canvas.restore();

    // 4. 3D Beveled Highlight & Shadow Edges
    if (isTileMode) {
      // Top-Left directional highlight
      final highlightPath = Path()
        ..moveTo(rect.left, rect.bottom - 8)
        ..lineTo(rect.left, rect.top + 8)
        ..arcToPoint(Offset(rect.left + 8, rect.top), radius: const Radius.circular(8))
        ..lineTo(rect.right - 8, rect.top);

      final highlightPen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLifted ? 2.5 : 1.8
        ..color = Colors.white.withOpacity(isLifted ? 0.75 : 0.45);
      canvas.drawPath(highlightPath, highlightPen);

      // Bottom-Right directional shadow
      final shadowPath = Path()
        ..moveTo(rect.right, rect.top + 8)
        ..lineTo(rect.right, rect.bottom - 8)
        ..arcToPoint(Offset(rect.right - 8, rect.bottom), radius: const Radius.circular(8))
        ..lineTo(rect.left + 8, rect.bottom);

      final shadowPen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLifted ? 2.5 : 1.8
        ..color = Colors.black.withOpacity(0.55);
      canvas.drawPath(shadowPath, shadowPen);
    } else {
      final highlightBevel = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLifted ? 2.5 : 1.8
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(pieceWidth, pieceHeight),
          [
            Colors.white.withOpacity(0.65),
            Colors.white.withOpacity(0.25),
            Colors.transparent,
          ],
        );
      canvas.drawPath(path, highlightBevel);
    }

    // 5. Number Badge (Optional helper to see original target index 1..N)
    if (showNumberBadge) {
      final targetNum = '${piece.id + 1}';
      final tp = TextPainter(
        text: TextSpan(
          text: targetNum,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFD700),
            shadows: [
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeCenter = Offset(rect.left + 16, rect.top + 16);
      canvas.drawCircle(
        badgeCenter,
        12,
        Paint()..color = const Color(0xCC000000),
      );
      tp.paint(
        canvas,
        Offset(badgeCenter.dx - tp.width / 2, badgeCenter.dy - tp.height / 2),
      );
    }

    // 6. Hint highlight pulse
    if (isHighlighted) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 + (highlightPulse * 2.0)
        ..color = Color.lerp(
          const Color(0xFFFFD700),
          const Color(0xFFFFF8E1),
          highlightPulse,
        )!
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PuzzlePiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.isLifted != isLifted ||
        oldDelegate.isHighlighted != isHighlighted ||
        oldDelegate.highlightPulse != highlightPulse ||
        oldDelegate.isMysteryHidden != isMysteryHidden ||
        oldDelegate.showNumberBadge != showNumberBadge ||
        oldDelegate.isTileMode != isTileMode ||
        oldDelegate.image != image;
  }
}
