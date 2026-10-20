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
  final double highlightPulse; // 0.0 to 1.0

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
    this.highlightPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Build the exact interlocking jigsaw path
    final path = PuzzleEdgeGenerator.buildPiecePath(
      width: pieceWidth,
      height: pieceHeight,
      top: piece.topEdge,
      right: piece.rightEdge,
      bottom: piece.bottomEdge,
      left: piece.leftEdge,
    );

    // 2. Draw 3D Drop Shadow
    final shadowPaint = Paint()..style = PaintingStyle.fill;
    if (isLifted) {
      // 3D Lifted drop shadow (larger spread, offset, and blur)
      shadowPaint
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
      canvas.save();
      canvas.translate(8.0, 14.0);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    } else if (!piece.isPlaced) {
      // Subtle ambient shadow for unplaced piece
      shadowPaint
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.save();
      canvas.translate(2.0, 3.5);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    // 3. Draw Mystery Mode Silhouette or Clipped Image
    canvas.save();
    canvas.clipPath(path);

    if (isMysteryHidden && !piece.isPlaced) {
      // Mystery Mode: embossed silhouette with frosted shimmer
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
      canvas.drawRect(Rect.fromLTWH(-40, -40, pieceWidth + 80, pieceHeight + 80), mysteryPaint);

      // Question mark or mystery pattern in center
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
      // Draw the mapped portion of the source image!
      // The image is mapped over the full board (boardWidth x boardHeight)
      // Piece's position on the full board is (piece.col * pieceWidth, piece.row * pieceHeight)
      final srcRect = Rect.fromLTWH(
        piece.normX * image!.width,
        piece.normY * image!.height,
        piece.normWidth * image!.width,
        piece.normHeight * image!.height,
      );

      // Also account for tabs sticking outward by expanding src & dst
      final double tabW = pieceWidth * 0.25;
      final double tabH = pieceHeight * 0.25;

      final expandedDst = Rect.fromLTWH(
        -tabW,
        -tabH,
        pieceWidth + (tabW * 2),
        pieceHeight + (tabH * 2),
      );

      final double imgTabX = (tabW / boardWidth) * image!.width;
      final double imgTabY = (tabH / boardHeight) * image!.height;

      final expandedSrc = Rect.fromLTWH(
        srcRect.left - imgTabX,
        srcRect.top - imgTabY,
        srcRect.width + (imgTabX * 2),
        srcRect.height + (imgTabY * 2),
      );

      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium;

      canvas.drawImageRect(image!, expandedSrc, expandedDst, paint);

      // 4. Specular Sheen (glossy top glaze)
      final sheenPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(pieceWidth, pieceHeight),
          [
            Colors.white.withOpacity(isLifted ? 0.22 : 0.12),
            Colors.white.withOpacity(0.0),
            Colors.black.withOpacity(0.10),
          ],
        );
      canvas.drawPaint(sheenPaint);
    } else {
      // Fallback placeholder
      final fallbackPaint = Paint()..color = const Color(0xFF455A64);
      canvas.drawPaint(fallbackPaint);
    }

    canvas.restore();

    // 5. 3D Beveled Highlight & Shadow Edges
    if (!piece.isPlaced || isLifted) {
      // Top/Left directional highlight bevel
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

      // Bottom/Right directional shadow bevel
      final shadowBevel = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLifted ? 2.5 : 1.8
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(pieceWidth, pieceHeight),
          [
            Colors.transparent,
            Colors.black.withOpacity(0.35),
            Colors.black.withOpacity(0.70),
          ],
        );
      canvas.drawPath(path, shadowBevel);
    } else {
      // Correctly placed seam: very faint subtle hairline seam
      final seamPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..color = const Color(0x22FFFFFF);
      canvas.drawPath(path, seamPaint);
    }

    // 6. Golden Hint Highlight Pulse
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
        oldDelegate.image != image;
  }
}
