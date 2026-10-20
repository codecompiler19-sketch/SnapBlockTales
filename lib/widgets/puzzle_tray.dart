import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../game/puzzle_board.dart';
import '../game/puzzle_piece_renderer.dart';
import '../models/puzzle_piece.dart';
import '../services/audio_manager.dart';

class PuzzleTrayWidget extends StatefulWidget {
  final ui.Image? image;
  final List<PuzzlePiece> pieces;
  final int rows;
  final int cols;
  final GlobalKey<PuzzleBoardWidgetState> boardKey;
  final int? highlightedPieceId;
  final bool isMysteryMode;
  final bool leftHanded;

  const PuzzleTrayWidget({
    super.key,
    required this.image,
    required this.pieces,
    required this.rows,
    required this.cols,
    required this.boardKey,
    this.highlightedPieceId,
    this.isMysteryMode = false,
    this.leftHanded = false,
  });

  @override
  State<PuzzleTrayWidget> createState() => _PuzzleTrayWidgetState();
}

class _PuzzleTrayWidgetState extends State<PuzzleTrayWidget> {
  bool _filterEdgesOnly = false;

  @override
  Widget build(BuildContext context) {
    final unplacedPieces = widget.pieces.where((p) => !p.isPlaced).toList();
    final displayPieces = _filterEdgesOnly
        ? unplacedPieces.where((p) => p.isEdgePiece).toList()
        : unplacedPieces;

    // Piece slot size in tray
    const double traySlotSize = 78.0;

    return Container(
      height: 125,
      decoration: BoxDecoration(
        color: const Color(0xFF141622),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sub-bar with piece counter and "Edges Only" filter button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: widget.leftHanded
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining: ${unplacedPieces.length} / ${widget.pieces.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF90A4AE),
                  ),
                ),
                InkWell(
                  onTap: () {
                    AudioManager.instance.playTap();
                    setState(() {
                      _filterEdgesOnly = !_filterEdgesOnly;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _filterEdgesOnly
                          ? const Color(0xFFFFD700)
                          : const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.crop_square,
                          size: 14,
                          color: _filterEdgesOnly
                              ? const Color(0xFF141622)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Edges Only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _filterEdgesOnly
                                ? const Color(0xFF141622)
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable list of available pieces
          Expanded(
            child: displayPieces.isEmpty
                ? const Center(
                    child: Text(
                      'No matching pieces in tray',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: displayPieces.length,
                    itemBuilder: (context, index) {
                      final piece = displayPieces[index];
                      final isHighlighted = piece.id == widget.highlightedPieceId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Draggable<PuzzlePiece>(
                          data: piece,
                          onDragStarted: () {
                            AudioManager.instance.playPickup();
                          },
                          onDragEnd: (details) {
                            // Check if drop snapped onto board
                            final snapped = widget.boardKey.currentState
                                    ?.trySnapPiece(
                                  piece,
                                  details.offset,
                                  const Size(traySlotSize, traySlotSize),
                                ) ??
                                false;

                            if (!snapped) {
                              AudioManager.instance.playDrop();
                            }
                          },
                          feedback: Material(
                            color: Colors.transparent,
                            child: Transform.rotate(
                              angle: 0.04, // subtle 2-degree 3D lift tilt
                              child: Transform.scale(
                                scale: 1.10, // 3D lift magnification
                                child: SizedBox(
                                  width: traySlotSize,
                                  height: traySlotSize,
                                  child: CustomPaint(
                                    size: const Size(traySlotSize, traySlotSize),
                                    painter: PuzzlePiecePainter(
                                      image: widget.image,
                                      piece: piece,
                                      pieceWidth: traySlotSize,
                                      pieceHeight: traySlotSize,
                                      boardWidth: traySlotSize * widget.cols,
                                      boardHeight: traySlotSize * widget.rows,
                                      isLifted: true,
                                      isHighlighted: isHighlighted,
                                      isMysteryHidden: widget.isMysteryMode,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.25,
                            child: _buildPieceThumbnail(piece, traySlotSize, isHighlighted),
                          ),
                          child: _buildPieceThumbnail(piece, traySlotSize, isHighlighted),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceThumbnail(PuzzlePiece piece, double size, bool isHighlighted) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size, size),
        painter: PuzzlePiecePainter(
          image: widget.image,
          piece: piece,
          pieceWidth: size,
          pieceHeight: size,
          boardWidth: size * widget.cols,
          boardHeight: size * widget.rows,
          isLifted: false,
          isHighlighted: isHighlighted,
          isMysteryHidden: widget.isMysteryMode,
        ),
      ),
    );
  }
}
