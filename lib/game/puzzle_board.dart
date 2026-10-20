import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/puzzle_piece.dart';
import '../services/audio_manager.dart';
import 'puzzle_edge_generator.dart';
import 'puzzle_piece_renderer.dart';

class PuzzleBoardWidget extends StatefulWidget {
  final ui.Image? image;
  final List<PuzzlePiece> pieces;
  final int rows;
  final int cols;
  final bool showWatermark;
  final int? highlightedPieceId;
  final bool isMysteryMode;
  final VoidCallback onPieceSnapped;
  final VoidCallback onPuzzleCompleted;

  const PuzzleBoardWidget({
    super.key,
    required this.image,
    required this.pieces,
    required this.rows,
    required this.cols,
    this.showWatermark = false,
    this.highlightedPieceId,
    this.isMysteryMode = false,
    required this.onPieceSnapped,
    required this.onPuzzleCompleted,
  });

  @override
  State<PuzzleBoardWidget> createState() => PuzzleBoardWidgetState();
}

class PuzzleBoardWidgetState extends State<PuzzleBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final GlobalKey _boardKey = GlobalKey();

  // Snapping animation state
  int? _recentlySnappedId;
  double _snapFlashOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Checks if a piece dragged to a global offset should snap to the board.
  bool trySnapPiece(PuzzlePiece piece, Offset globalPieceTopLeft, Size pieceSize) {
    if (piece.isPlaced) return false;

    final RenderBox? boardBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) return false;

    final boardPos = boardBox.localToGlobal(Offset.zero);
    final boardSize = boardBox.size;

    final pieceWidth = boardSize.width / widget.cols;
    final pieceHeight = boardSize.height / widget.rows;

    // Correct top-left in global coordinates
    final targetGlobalX = boardPos.dx + (piece.col * pieceWidth);
    final targetGlobalY = boardPos.dy + (piece.row * pieceHeight);

    final distance = (Offset(targetGlobalX, targetGlobalY) - globalPieceTopLeft).distance;
    final snapThreshold = max(40.0, pieceWidth * 0.45);

    if (distance <= snapThreshold) {
      snapPiece(piece);
      return true;
    }
    return false;
  }

  /// Manually or programmatically snaps a piece (e.g. via hint).
  void snapPiece(PuzzlePiece piece) {
    if (piece.isPlaced) return;

    setState(() {
      piece.isPlaced = true;
      _recentlySnappedId = piece.id;
      _snapFlashOpacity = 1.0;
    });

    AudioManager.instance.playSnap();
    widget.onPieceSnapped();

    // Check if puzzle fully solved!
    final allSolved = widget.pieces.every((p) => p.isPlaced);
    if (allSolved) {
      widget.onPuzzleCompleted();
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _snapFlashOpacity = 0.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute square or aspect-ratio board size that fits the constraints
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final boardAspect = widget.cols / widget.rows;

        double boardW, boardH;
        if (maxW / maxH > boardAspect) {
          boardH = maxH;
          boardW = boardH * boardAspect;
        } else {
          boardW = maxW;
          boardH = boardW / boardAspect;
        }

        final pieceW = boardW / widget.cols;
        final pieceH = boardH / widget.rows;

        return Center(
          child: Container(
            key: _boardKey,
            width: boardW,
            height: boardH,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1D28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3F4660),
                width: 3.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x60000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x20FFFFFF),
                  blurRadius: 1,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // 1. Watermark Ghost Image (Toggleable)
                  if (widget.showWatermark && widget.image != null)
                    Opacity(
                      opacity: 0.28,
                      child: RawImage(
                        image: widget.image,
                        width: boardW,
                        height: boardH,
                        fit: BoxFit.fill,
                      ),
                    ),

                  // 2. Faint Grid Lines / Slot Guidelines
                  CustomPaint(
                    size: Size(boardW, boardH),
                    painter: _BoardGridPainter(
                      rows: widget.rows,
                      cols: widget.cols,
                      pieces: widget.pieces,
                    ),
                  ),

                  // 3. Highlighted Slot Guide (Hint Effect)
                  if (widget.highlightedPieceId != null)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final hp = widget.pieces.firstWhere(
                          (p) => p.id == widget.highlightedPieceId,
                          orElse: () => widget.pieces.first,
                        );
                        if (hp.isPlaced) return const SizedBox.shrink();

                        return Positioned(
                          left: hp.col * pieceW,
                          top: hp.row * pieceH,
                          width: pieceW,
                          height: pieceH,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                const Color(0x20FFD700),
                                const Color(0x55FFD700),
                                _pulseController.value,
                              ),
                              border: Border.all(
                                color: Color.lerp(
                                  const Color(0xAAFFD700),
                                  const Color(0xFFFFE082),
                                  _pulseController.value,
                                )!,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFFFD700),
                                size: 28,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // 4. Render All Correctly Placed Pieces
                  ...widget.pieces.where((p) => p.isPlaced).map((piece) {
                    final isJustSnapped = piece.id == _recentlySnappedId;

                    return Positioned(
                      left: piece.col * pieceW,
                      top: piece.row * pieceH,
                      width: pieceW,
                      height: pieceH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: Size(pieceW, pieceH),
                            painter: PuzzlePiecePainter(
                              image: widget.image,
                              piece: piece,
                              pieceWidth: pieceW,
                              pieceHeight: pieceH,
                              boardWidth: boardW,
                              boardHeight: boardH,
                              isLifted: false,
                              isMysteryHidden: false, // Revealed once placed!
                            ),
                          ),
                          // Gold shimmer flash on snap
                          if (isJustSnapped && _snapFlashOpacity > 0.0)
                            AnimatedOpacity(
                              opacity: _snapFlashOpacity,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0x44FFD700),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final List<PuzzlePiece> pieces;

  _BoardGridPainter({
    required this.rows,
    required this.cols,
    required this.pieces,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / cols;
    final double cellH = size.height / rows;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0x18FFFFFF);

    // Draw faint jigsaw guide curves for empty slots
    for (final piece in pieces) {
      if (!piece.isPlaced) {
        canvas.save();
        canvas.translate(piece.col * cellW, piece.row * cellH);
        final path = PuzzleEdgeGenerator.buildPiecePath(
          width: cellW,
          height: cellH,
          top: piece.topEdge,
          right: piece.rightEdge,
          bottom: piece.bottomEdge,
          left: piece.leftEdge,
        );
        canvas.drawPath(path, borderPaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardGridPainter oldDelegate) => true;
}
