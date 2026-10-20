import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/puzzle_piece.dart';

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
    this.showNumberBadge = true,
    this.highlightPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double padding = 2.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      pieceWidth - padding * 2,
      pieceHeight - padding * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));

    // 1. Pure clean rectangular tile path with rounded corners (No jigsaw cuts)
    final path = Path()..addRRect(rrect);

    // 2. Draw 3D Drop Shadow
    final shadowPaint = Paint()..style = PaintingStyle.fill;
    if (isLifted) {
      shadowPaint
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.save();
      canvas.translate(4.0, 8.0);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    } else {
      shadowPaint
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      canvas.save();
      canvas.translate(1.5, 2.5);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    // 3. Draw Clean Image Slice
    canvas.save();
    canvas.clipPath(path);

    if (isMysteryHidden && !piece.isPlaced) {
      final mysteryPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(rect.left, rect.top),
          Offset(rect.right, rect.bottom),
          [
            const Color(0xFF2A2A40),
            const Color(0xFF1E1E2E),
            const Color(0xFF383854),
          ],
        );
      canvas.drawRect(rect, mysteryPaint);

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
      final dstRect = rect;

      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium;

      canvas.drawImageRect(image!, srcRect, dstRect, paint);

      // Specular surface sheen for realistic depth
      final sheenPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(rect.left, rect.top),
          Offset(rect.right, rect.bottom),
          [
            Colors.white.withOpacity(isLifted ? 0.25 : 0.08),
            Colors.white.withOpacity(0.0),
            Colors.black.withOpacity(0.12),
          ],
        );
      canvas.drawRect(rect, sheenPaint);
    } else {
      final fallbackPaint = Paint()..color = const Color(0xFF455A64);
      canvas.drawRect(rect, fallbackPaint);
    }

    canvas.restore();

    // 4. 3D Beveled Highlight & Shadow Edges
    final highlightPath = Path()
      ..moveTo(rect.left, rect.bottom - 6)
      ..lineTo(rect.left, rect.top + 6)
      ..arcToPoint(Offset(rect.left + 6, rect.top), radius: const Radius.circular(6))
      ..lineTo(rect.right - 6, rect.top);

    final highlightPen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLifted ? 2.5 : 1.6
      ..color = Colors.white.withOpacity(isLifted ? 0.8 : 0.45);
    canvas.drawPath(highlightPath, highlightPen);

    final shadowPath = Path()
      ..moveTo(rect.right, rect.top + 6)
      ..lineTo(rect.right, rect.bottom - 6)
      ..arcToPoint(Offset(rect.right - 6, rect.bottom), radius: const Radius.circular(6))
      ..lineTo(rect.left + 6, rect.bottom);

    final shadowPen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLifted ? 2.5 : 1.6
      ..color = Colors.black.withOpacity(0.55);
    canvas.drawPath(shadowPath, shadowPen);

    // 5. Serial Number Badge (Shows 1, 2, 3... corresponding to correct order)
    if (showNumberBadge) {
      final serialNumber = '${piece.id + 1}';
      final badgeRadius = min(14.0, max(11.0, pieceWidth * 0.14));
      final fontSize = badgeRadius * 1.05;

      final tp = TextPainter(
        text: TextSpan(
          text: serialNumber,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: piece.isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFD700),
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeCenter = Offset(
        rect.left + badgeRadius + 4,
        rect.top + badgeRadius + 4,
      );

      // Badge Background
      canvas.drawCircle(
        badgeCenter,
        badgeRadius,
        Paint()
          ..color = piece.isCorrect
              ? const Color(0xE61B5E20)
              : const Color(0xE60A0D18),
      );

      // Badge Border Ring
      canvas.drawCircle(
        badgeCenter,
        badgeRadius,
        Paint()
          ..color = piece.isCorrect
              ? const Color(0xFF10B981)
              : const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      // Badge Number Text
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
