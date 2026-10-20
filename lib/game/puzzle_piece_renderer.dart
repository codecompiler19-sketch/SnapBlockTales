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

  // Seamless boundary removal when correct adjacent pieces meet
  final bool joinTop;
  final bool joinRight;
  final bool joinBottom;
  final bool joinLeft;

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
    this.joinTop = false,
    this.joinRight = false,
    this.joinBottom = false,
    this.joinLeft = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double gap = 1.5;
    final double left = joinLeft ? 0.0 : gap;
    final double top = joinTop ? 0.0 : gap;
    final double right = joinRight ? pieceWidth : pieceWidth - gap;
    final double bottom = joinBottom ? pieceHeight : pieceHeight - gap;

    final rect = Rect.fromLTRB(left, top, right, bottom);

    const double cornerR = 6.0;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: (joinTop || joinLeft) ? Radius.zero : const Radius.circular(cornerR),
      topRight: (joinTop || joinRight) ? Radius.zero : const Radius.circular(cornerR),
      bottomLeft: (joinBottom || joinLeft) ? Radius.zero : const Radius.circular(cornerR),
      bottomRight: (joinBottom || joinRight) ? Radius.zero : const Radius.circular(cornerR),
    );

    // 1. Path representing this piece's visible footprint
    final path = Path()..addRRect(rrect);

    // 2. 3D Drop Shadow only on unjoined / lifted pieces
    if (isLifted) {
      final shadowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.save();
      canvas.translate(4.0, 8.0);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    } else if (!joinTop && !joinRight && !joinBottom && !joinLeft) {
      final shadowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.save();
      canvas.translate(1.0, 2.0);
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
          [0.0, 0.5, 1.0],
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
      // Map piece to full cell [0, 0, pieceWidth, pieceHeight] so image seamlessly continues across boundaries
      final dstRect = Rect.fromLTWH(0, 0, pieceWidth, pieceHeight);

      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium;

      canvas.drawImageRect(image!, srcRect, dstRect, paint);

      // Subtle specular sheen on lifted piece
      if (isLifted) {
        final sheenPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(rect.left, rect.top),
            Offset(rect.right, rect.bottom),
            [
              Colors.white.withOpacity(0.22),
              Colors.white.withOpacity(0.0),
              Colors.black.withOpacity(0.12),
            ],
            [0.0, 0.5, 1.0],
          );
        canvas.drawRect(rect, sheenPaint);
      }
    } else {
      final fallbackPaint = Paint()..color = const Color(0xFF455A64);
      canvas.drawRect(rect, fallbackPaint);
    }

    canvas.restore();

    // 4. 3D Beveled Highlight & Shadow Edges (Only drawn along unjoined boundaries!)
    final highlightPen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLifted ? 2.5 : 1.4
      ..color = Colors.white.withOpacity(isLifted ? 0.8 : 0.35);

    final shadowPen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLifted ? 2.5 : 1.4
      ..color = Colors.black.withOpacity(0.45);

    // Top edge highlight (if not joined on top)
    if (!joinTop) {
      canvas.drawLine(
        Offset(left + (joinLeft ? 0 : cornerR), top),
        Offset(right - (joinRight ? 0 : cornerR), top),
        highlightPen,
      );
    }

    // Left edge highlight (if not joined on left)
    if (!joinLeft) {
      canvas.drawLine(
        Offset(left, top + (joinTop ? 0 : cornerR)),
        Offset(left, bottom - (joinBottom ? 0 : cornerR)),
        highlightPen,
      );
    }

    // Bottom edge shadow (if not joined on bottom)
    if (!joinBottom) {
      canvas.drawLine(
        Offset(left + (joinLeft ? 0 : cornerR), bottom),
        Offset(right - (joinRight ? 0 : cornerR), bottom),
        shadowPen,
      );
    }

    // Right edge shadow (if not joined on right)
    if (!joinRight) {
      canvas.drawLine(
        Offset(right, top + (joinTop ? 0 : cornerR)),
        Offset(right, bottom - (joinBottom ? 0 : cornerR)),
        shadowPen,
      );
    }

    // 5. Optional Number Badge (Only shown if explicitly toggled on via UI)
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

      canvas.drawCircle(
        badgeCenter,
        badgeRadius,
        Paint()
          ..color = piece.isCorrect
              ? const Color(0xE61B5E20)
              : const Color(0xE60A0D18),
      );

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
        oldDelegate.joinTop != joinTop ||
        oldDelegate.joinRight != joinRight ||
        oldDelegate.joinBottom != joinBottom ||
        oldDelegate.joinLeft != joinLeft ||
        oldDelegate.image != image;
  }
}
