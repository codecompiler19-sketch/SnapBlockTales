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
  Set<int> _activeDraggingGroup = {};

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

  bool isSlotJoinedTop(int slotRow, int slotCol, PuzzlePiece currentPiece) {
    if (slotRow == 0) return false;
    final topSlot = (slotRow - 1) * widget.cols + slotCol;
    final topPiece = widget.pieces.firstWhere((p) => p.currentSlot == topSlot, orElse: () => currentPiece);
    return topPiece.col == currentPiece.col && topPiece.row + 1 == currentPiece.row;
  }

  bool isSlotJoinedBottom(int slotRow, int slotCol, PuzzlePiece currentPiece) {
    if (slotRow >= widget.rows - 1) return false;
    final bottomSlot = (slotRow + 1) * widget.cols + slotCol;
    final bottomPiece = widget.pieces.firstWhere((p) => p.currentSlot == bottomSlot, orElse: () => currentPiece);
    return bottomPiece.col == currentPiece.col && currentPiece.row + 1 == bottomPiece.row;
  }

  bool isSlotJoinedLeft(int slotRow, int slotCol, PuzzlePiece currentPiece) {
    if (slotCol == 0) return false;
    final leftSlot = slotRow * widget.cols + (slotCol - 1);
    final leftPiece = widget.pieces.firstWhere((p) => p.currentSlot == leftSlot, orElse: () => currentPiece);
    return leftPiece.row == currentPiece.row && leftPiece.col + 1 == currentPiece.col;
  }

  bool isSlotJoinedRight(int slotRow, int slotCol, PuzzlePiece currentPiece) {
    if (slotCol >= widget.cols - 1) return false;
    final rightSlot = slotRow * widget.cols + (slotCol + 1);
    final rightPiece = widget.pieces.firstWhere((p) => p.currentSlot == rightSlot, orElse: () => currentPiece);
    return rightPiece.row == currentPiece.row && currentPiece.col + 1 == rightPiece.col;
  }

  int countTotalJoinedEdges() {
    int count = 0;
    for (int r = 0; r < widget.rows; r++) {
      for (int c = 0; c < widget.cols; c++) {
        final slotIndex = r * widget.cols + c;
        final piece = widget.pieces.firstWhere((p) => p.currentSlot == slotIndex, orElse: () => widget.pieces[slotIndex]);
        if (isSlotJoinedRight(r, c, piece)) count++;
        if (isSlotJoinedBottom(r, c, piece)) count++;
      }
    }
    return count;
  }

  /// Returns all connected slot indices that are seamlessly joined with [startSlot].
  Set<int> getConnectedGroupSlots(int startSlot) {
    final visited = <int>{startSlot};
    final queue = <int>[startSlot];

    while (queue.isNotEmpty) {
      final currentSlot = queue.removeAt(0);
      final r = currentSlot ~/ widget.cols;
      final c = currentSlot % widget.cols;
      final piece = widget.pieces.firstWhere(
        (p) => p.currentSlot == currentSlot,
        orElse: () => widget.pieces[currentSlot],
      );

      // Check Top
      if (isSlotJoinedTop(r, c, piece)) {
        final topSlot = (r - 1) * widget.cols + c;
        if (visited.add(topSlot)) {
          queue.add(topSlot);
        }
      }

      // Check Bottom
      if (isSlotJoinedBottom(r, c, piece)) {
        final bottomSlot = (r + 1) * widget.cols + c;
        if (visited.add(bottomSlot)) {
          queue.add(bottomSlot);
        }
      }

      // Check Left
      if (isSlotJoinedLeft(r, c, piece)) {
        final leftSlot = r * widget.cols + (c - 1);
        if (visited.add(leftSlot)) {
          queue.add(leftSlot);
        }
      }

      // Check Right
      if (isSlotJoinedRight(r, c, piece)) {
        final rightSlot = r * widget.cols + (c + 1);
        if (visited.add(rightSlot)) {
          queue.add(rightSlot);
        }
      }
    }

    return visited;
  }

  /// Checks if an entire group of slots can move by (dRow, dCol) without overflowing the board.
  bool canGroupMove(Set<int> groupSlots, int dRow, int dCol) {
    for (final s in groupSlots) {
      final r = s ~/ widget.cols + dRow;
      final c = s % widget.cols + dCol;
      if (r < 0 || r >= widget.rows || c < 0 || c >= widget.cols) {
        return false;
      }
    }
    return true;
  }

  /// Moves an entire seamlessly joined group together from [fromAnchorSlot] to [toAnchorSlot].
  void moveGroup(int fromAnchorSlot, int toAnchorSlot) {
    if (fromAnchorSlot == toAnchorSlot) return;

    final groupSlots = getConnectedGroupSlots(fromAnchorSlot);
    final fromRow = fromAnchorSlot ~/ widget.cols;
    final fromCol = fromAnchorSlot % widget.cols;
    final toRow = toAnchorSlot ~/ widget.cols;
    final toCol = toAnchorSlot % widget.cols;

    final dRow = toRow - fromRow;
    final dCol = toCol - fromCol;

    if (!canGroupMove(groupSlots, dRow, dCol)) {
      if (groupSlots.length == 1) {
        swapSlots(fromAnchorSlot, toAnchorSlot);
      } else {
        AudioManager.instance.playDrop();
      }
      return;
    }

    final targetSlots = groupSlots.map((s) {
      final r = s ~/ widget.cols + dRow;
      final c = s % widget.cols + dCol;
      return r * widget.cols + c;
    }).toSet();

    final prevJoined = countTotalJoinedEdges();

    final groupPieces = groupSlots
        .map((s) => widget.pieces.firstWhere((p) => p.currentSlot == s))
        .toList();

    final vacatedSlots = groupSlots.difference(targetSlots).toList();
    final displacedSlots = targetSlots.difference(groupSlots).toList();
    final displacedPieces = displacedSlots
        .map((s) => widget.pieces.firstWhere((p) => p.currentSlot == s))
        .toList();

    // Precalculate new slots for group pieces to avoid race condition collisions
    final groupPiecesWithNewSlots = groupPieces.map((p) {
      final r = p.currentSlot ~/ widget.cols + dRow;
      final c = p.currentSlot % widget.cols + dCol;
      return MapEntry(p, r * widget.cols + c);
    }).toList();

    setState(() {
      for (final entry in groupPiecesWithNewSlots) {
        entry.key.currentSlot = entry.value;
        entry.key.isPlaced = (entry.key.currentSlot == entry.key.id);
      }

      for (int i = 0; i < displacedPieces.length; i++) {
        displacedPieces[i].currentSlot = vacatedSlots[i];
        displacedPieces[i].isPlaced =
            (displacedPieces[i].currentSlot == displacedPieces[i].id);
      }

      _selectedSlot = null;
      _hoveredSlot = null;
      _activeDraggingGroup = {};
    });

    final newJoined = countTotalJoinedEdges();
    final newlyJoined = newJoined > prevJoined;

    if (newlyJoined) {
      AudioManager.instance.playSnap();
      AudioManager.instance.triggerHaptic(HapticFeedbackType.medium);
      _recentlySnappedId = groupPieces.first.id;
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

  /// Swaps pieces at slotA and slotB.
  void swapSlots(int slotA, int slotB) {
    moveGroup(slotA, slotB);
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

                      final selectedGroup = _selectedSlot != null
                          ? getConnectedGroupSlots(_selectedSlot!)
                          : <int>{};
                      final isSelected = selectedGroup.contains(slotIndex);
                      final isHovered = _hoveredSlot == slotIndex;
                      final isCorrect = piece.currentSlot == piece.id;
                      final isGroupDragging = _activeDraggingGroup.contains(slotIndex);

                      return Positioned(
                        left: slotCol * pieceW,
                        top: slotRow * pieceH,
                        width: pieceW,
                        height: pieceH,
                        child: DragTarget<int>(
                          onWillAcceptWithDetails: (details) {
                            final fromSlot = details.data;
                            if (fromSlot == slotIndex) return false;
                            final group = getConnectedGroupSlots(fromSlot);
                            final fromRow = fromSlot ~/ widget.cols;
                            final fromCol = fromSlot % widget.cols;
                            final toRow = slotIndex ~/ widget.cols;
                            final toCol = slotIndex % widget.cols;
                            return canGroupMove(group, toRow - fromRow, toCol - fromCol);
                          },
                          onAcceptWithDetails: (details) {
                            moveGroup(details.data, slotIndex);
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
                            final pieceWidget = _buildSlotPiece(
                              piece,
                              slotRow,
                              slotCol,
                              pieceW,
                              pieceH,
                              boardW,
                              boardH,
                              isCorrect,
                              isSelected,
                              isHovered,
                            );

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  if (_selectedSlot == null) {
                                    AudioManager.instance.playPickup();
                                    setState(() {
                                      _selectedSlot = slotIndex;
                                    });
                                  } else if (selectedGroup.contains(slotIndex)) {
                                    AudioManager.instance.playDrop();
                                    setState(() {
                                      _selectedSlot = null;
                                    });
                                  } else {
                                    moveGroup(_selectedSlot!, slotIndex);
                                  }
                                },
                                child: Draggable<int>(
                                  data: slotIndex,
                                  onDragStarted: () {
                                    AudioManager.instance.playPickup();
                                    final group = getConnectedGroupSlots(slotIndex);
                                    setState(() {
                                      _activeDraggingGroup = group;
                                      _selectedSlot = slotIndex;
                                    });
                                  },
                                  onDragEnd: (_) {
                                    setState(() {
                                      _activeDraggingGroup = {};
                                      _hoveredSlot = null;
                                    });
                                  },
                                  feedback: _buildGroupDragFeedback(
                                    slotIndex,
                                    getConnectedGroupSlots(slotIndex),
                                    pieceW,
                                    pieceH,
                                    boardW,
                                    boardH,
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.25,
                                    child: pieceWidget,
                                  ),
                                  child: isGroupDragging
                                      ? Opacity(opacity: 0.25, child: pieceWidget)
                                      : pieceWidget,
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

  Widget _buildGroupDragFeedback(
    int anchorSlot,
    Set<int> groupSlots,
    double pieceW,
    double pieceH,
    double boardW,
    double boardH,
  ) {
    final anchorRow = anchorSlot ~/ widget.cols;
    final anchorCol = anchorSlot % widget.cols;

    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.06,
        child: SizedBox(
          width: pieceW,
          height: pieceH,
          child: Stack(
            clipBehavior: Clip.none,
            children: groupSlots.map((s) {
              final sRow = s ~/ widget.cols;
              final sCol = s % widget.cols;
              final relX = (sCol - anchorCol) * pieceW;
              final relY = (sRow - anchorRow) * pieceH;

              final piece = widget.pieces.firstWhere(
                (p) => p.currentSlot == s,
                orElse: () => widget.pieces[s],
              );
              final joinTop = isSlotJoinedTop(sRow, sCol, piece);
              final joinRight = isSlotJoinedRight(sRow, sCol, piece);
              final joinBottom = isSlotJoinedBottom(sRow, sCol, piece);
              final joinLeft = isSlotJoinedLeft(sRow, sCol, piece);

              return Positioned(
                left: relX,
                top: relY,
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
                    joinTop: joinTop,
                    joinRight: joinRight,
                    joinBottom: joinBottom,
                    joinLeft: joinLeft,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotPiece(
    PuzzlePiece piece,
    int slotRow,
    int slotCol,
    double pieceW,
    double pieceH,
    double boardW,
    double boardH,
    bool isCorrect,
    bool isSelected,
    bool isHovered,
  ) {
    final joinTop = isSlotJoinedTop(slotRow, slotCol, piece);
    final joinRight = isSlotJoinedRight(slotRow, slotCol, piece);
    final joinBottom = isSlotJoinedBottom(slotRow, slotCol, piece);
    final joinLeft = isSlotJoinedLeft(slotRow, slotCol, piece);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          (joinTop || joinRight || joinBottom || joinLeft) ? 0 : 6,
        ),
        border: (isSelected || isHovered)
            ? Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF60A5FA),
                width: 2.5,
              )
            : null,
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
              joinTop: joinTop,
              joinRight: joinRight,
              joinBottom: joinBottom,
              joinLeft: joinLeft,
            ),
          ),

          // Magnetic Snap Glow Pulse Effect when newly joined/placed
          if (piece.id == _recentlySnappedId && _snapFlashOpacity > 0.0)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _snapFlashOpacity,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xBB10B981),
                        blurRadius: 16,
                        spreadRadius: 2,
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
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0x28FFFFFF);

    // Clean outer board frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(10.0),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardGridPainter oldDelegate) => false;
}
