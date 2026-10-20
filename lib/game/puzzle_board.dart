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
  final bool isRearrangeMode;
  final bool showNumberBadge;
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
    this.isRearrangeMode = true,
    this.showNumberBadge = false,
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

  // On-Board Rearrange State
  int? _selectedSlot;
  int? _hoveredSlot;

  // Snapping animation flash
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

  /// Shuffles pieces on the board into random slots (for On-Board Rearrange mode).
  void shufflePiecesOnBoard() {
    final rand = Random();
    final count = widget.pieces.length;
    final List<int> slots = List.generate(count, (i) => i);

    // Derangement: ensure no piece starts in its correct slot
    do {
      slots.shuffle(rand);
    } while (count > 2 && slots.asMap().entries.any((e) => e.key == e.value));

    setState(() {
      for (int i = 0; i < count; i++) {
        widget.pieces[i].currentSlot = slots[i];
        widget.pieces[i].isPlaced = (widget.pieces[i].currentSlot == widget.pieces[i].id);
      }
      _selectedSlot = null;
      _hoveredSlot = null;
    });
  }

  /// Swaps pieces at slotA and slotB.
  void swapSlots(int slotA, int slotB) {
    if (slotA == slotB) return;

    final pieceA = widget.pieces.firstWhere((p) => p.currentSlot == slotA);
    final pieceB = widget.pieces.firstWhere((p) => p.currentSlot == slotB);

    setState(() {
      pieceA.currentSlot = slotB;
      pieceB.currentSlot = slotA;

      pieceA.isPlaced = (pieceA.currentSlot == pieceA.id);
      pieceB.isPlaced = (pieceB.currentSlot == pieceB.id);

      _selectedSlot = null;
      _hoveredSlot = null;
    });

    final anyCorrect = pieceA.isPlaced || pieceB.isPlaced;
    if (anyCorrect) {
      AudioManager.instance.playSnap();
      AudioManager.instance.triggerHaptic(HapticFeedbackType.medium);
      _recentlySnappedId = pieceA.isPlaced ? pieceA.id : pieceB.id;
      _snapFlashOpacity = 1.0;
      widget.onPieceSnapped();

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _snapFlashOpacity = 0.0;
          });
        }
      });
    } else {
      AudioManager.instance.playDrop();
    }

    _checkCompletion();
  }

  void _checkCompletion() {
    final allSolved = widget.pieces.every((p) => p.currentSlot == p.id);
    if (allSolved) {
      widget.onPuzzleCompleted();
    }
  }

  /// Automatically places one misplaced piece into its correct slot.
  void autoPlaceOnePiece() {
    final misplaced = widget.pieces.where((p) => p.currentSlot != p.id).toList();
    if (misplaced.isEmpty) return;

    misplaced.shuffle();
    final targetPiece = misplaced.first;
    final targetSlot = targetPiece.id; // its correct slot

    swapSlots(targetPiece.currentSlot, targetSlot);
  }

  /// Checks if a piece dragged to a global offset should snap to the board (Tray mode).
  bool trySnapPiece(PuzzlePiece piece, Offset globalPieceTopLeft, Size pieceSize) {
    if (piece.isPlaced) return false;

    final RenderBox? boardBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) return false;

    final boardPos = boardBox.localToGlobal(Offset.zero);
    final boardSize = boardBox.size;

    final pieceWidth = boardSize.width / widget.cols;
    final pieceHeight = boardSize.height / widget.rows;

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

  void snapPiece(PuzzlePiece piece) {
    if (piece.isPlaced) return;

    setState(() {
      piece.isPlaced = true;
      piece.currentSlot = piece.id;
      _recentlySnappedId = piece.id;
      _snapFlashOpacity = 1.0;
    });

    AudioManager.instance.playSnap();
    widget.onPieceSnapped();

    _checkCompletion();

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
              color: const Color(0xFF141724),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3F4660),
                width: 3.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x70000000),
                  blurRadius: 20,
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
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // 1. Watermark Ghost Image (Toggleable)
                  if (widget.showWatermark && widget.image != null)
                    Opacity(
                      opacity: 0.35,
                      child: RawImage(
                        image: widget.image,
                        width: boardW,
                        height: boardH,
                        fit: BoxFit.fill,
                      ),
                    ),

                  // 2. Grid lines / slots
                  CustomPaint(
                    size: Size(boardW, boardH),
                    painter: _BoardGridPainter(
                      rows: widget.rows,
                      cols: widget.cols,
                      pieces: widget.pieces,
                      isRearrangeMode: widget.isRearrangeMode,
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
                        if (hp.isCorrect) return const SizedBox.shrink();

                        final targetCol = hp.id % widget.cols;
                        final targetRow = hp.id ~/ widget.cols;

                        return Positioned(
                          left: targetCol * pieceW,
                          top: targetRow * pieceH,
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
                                width: 2.8,
                              ),
                              borderRadius: BorderRadius.circular(6),
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

                  // 4. ON-BOARD REARRANGE MODE: Render ALL pieces directly on board slots
                  if (widget.isRearrangeMode)
                    ...List.generate(widget.pieces.length, (slotIndex) {
                      final slotCol = slotIndex % widget.cols;
                      final slotRow = slotIndex ~/ widget.cols;

                      // Find the piece currently placed in this slot
                      final piece = widget.pieces.firstWhere(
                        (p) => p.currentSlot == slotIndex,
                        orElse: () => widget.pieces[slotIndex],
                      );

                      final isSelected = _selectedSlot == slotIndex;
                      final isHovered = _hoveredSlot == slotIndex;
                      final isCorrect = piece.currentSlot == piece.id;

                      return Positioned(
                        left: slotCol * pieceW,
                        top: slotRow * pieceH,
                        width: pieceW,
                        height: pieceH,
                        child: DragTarget<int>(
                          onWillAcceptWithDetails: (details) => details.data != slotIndex,
                          onAcceptWithDetails: (details) {
                            final fromSlot = details.data;
                            swapSlots(fromSlot, slotIndex);
                          },
                          onMove: (_) {
                            if (_hoveredSlot != slotIndex) {
                              setState(() {
                                _hoveredSlot = slotIndex;
                              });
                            }
                          },
                          onLeave: (_) {
                            if (_hoveredSlot == slotIndex) {
                              setState(() {
                                _hoveredSlot = null;
                              });
                            }
                          },
                          builder: (context, candidateData, rejectedData) {
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  if (_selectedSlot == null) {
                                    AudioManager.instance.playPickup();
                                    setState(() {
                                      _selectedSlot = slotIndex;
                                    });
                                  } else if (_selectedSlot == slotIndex) {
                                    AudioManager.instance.playDrop();
                                    setState(() {
                                      _selectedSlot = null;
                                    });
                                  } else {
                                    swapSlots(_selectedSlot!, slotIndex);
                                  }
                                },
                                child: Draggable<int>(
                                  data: slotIndex,
                                  onDragStarted: () {
                                    AudioManager.instance.playPickup();
                                    setState(() {
                                      _selectedSlot = slotIndex;
                                    });
                                  },
                                  onDragEnd: (_) {
                                    setState(() {
                                      _hoveredSlot = null;
                                    });
                                  },
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: Transform.scale(
                                      scale: 1.08,
                                      child: SizedBox(
                                        width: pieceW,
                                        height: pieceH,
                                        child: CustomPaint(
                                          size: Size(pieceW, pieceH),
                                          painter: PuzzlePiecePainter(
                                            image: widget.image,
                                            piece: piece,
                                            pieceWidth: pieceW,
                                            pieceHeight: pieceH,
                                            boardWidth: boardW,
                                            boardHeight: boardH,
                                            isLifted: true,
                                            isTileMode: true,
                                            showNumberBadge: widget.showNumberBadge,
                                            isMysteryHidden: widget.isMysteryMode && !piece.isPlaced,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.35,
                                    child: _buildSlotPiece(piece, pieceW, pieceH, boardW, boardH, isCorrect, isSelected, isHovered),
                                  ),
                                  child: _buildSlotPiece(piece, pieceW, pieceH, boardW, boardH, isCorrect, isSelected, isHovered),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),

                  // 5. TRAY DOCK MODE: Render placed pieces only
                  if (!widget.isRearrangeMode)
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
                                isTileMode: false,
                                isMysteryHidden: false,
                              ),
                            ),
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

  Widget _buildSlotPiece(
    PuzzlePiece piece,
    double pieceW,
    double pieceH,
    double boardW,
    double boardH,
    bool isCorrect,
    bool isSelected,
    bool isHovered,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFD700)
              : (isHovered
                  ? const Color(0xFF60A5FA)
                  : (isCorrect
                      ? const Color(0x5510B981)
                      : Colors.transparent)),
          width: isSelected || isHovered ? 2.8 : (isCorrect ? 1.5 : 0.0),
        ),
        boxShadow: isSelected
            ? const [
                BoxShadow(
                  color: Color(0x99FFD700),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
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
              isLifted: isSelected,
              isTileMode: true,
              showNumberBadge: widget.showNumberBadge,
              isMysteryHidden: widget.isMysteryMode && !piece.isPlaced,
            ),
          ),

          // Correct placement indicator checkmark
          if (isCorrect)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xCC000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: Color(0xFF10B981),
                ),
              ),
            ),

          // Magnetic Snap Glow Pulse Effect
          if (piece.id == _recentlySnappedId)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _snapFlashOpacity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981), width: 3.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xCC10B981),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoardGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final List<PuzzlePiece> pieces;
  final bool isRearrangeMode;

  _BoardGridPainter({
    required this.rows,
    required this.cols,
    required this.pieces,
    required this.isRearrangeMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / cols;
    final double cellH = size.height / rows;

    final slotBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x2EFFFFFF);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final slotIndex = r * cols + c;
        final cellRect = Rect.fromLTWH(c * cellW + 2, r * cellH + 2, cellW - 4, cellH - 4);
        final rrect = RRect.fromRectAndRadius(cellRect, const Radius.circular(8.0));

        // Draw slot outline
        canvas.drawRRect(rrect, slotBorderPaint);

        // Faint target slot number in background (1, 2, 3...)
        final slotNum = '${slotIndex + 1}';
        final tp = TextPainter(
          text: TextSpan(
            text: slotNum,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0x1AFFFFFF),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            c * cellW + (cellW - tp.width) / 2,
            r * cellH + (cellH - tp.height) / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardGridPainter oldDelegate) => true;
}
