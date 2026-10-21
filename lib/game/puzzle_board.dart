import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/puzzle_piece.dart';
import '../services/audio_manager.dart';
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
  final bool colorBlindMode;
  final VoidCallback onPieceSnapped;
  final VoidCallback onPuzzleCompleted;
  final VoidCallback? onMoveMade;

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
    this.colorBlindMode = false,
    required this.onPieceSnapped,
    required this.onPuzzleCompleted,
    this.onMoveMade,
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

  bool canGroupMoveDirection(Set<int> groupSlots, int dRow, int dCol) {
    final minRow = groupSlots.map((s) => s ~/ widget.cols).reduce(min);
    final maxRow = groupSlots.map((s) => s ~/ widget.cols).reduce(max);
    final minCol = groupSlots.map((s) => s % widget.cols).reduce(min);
    final maxCol = groupSlots.map((s) => s % widget.cols).reduce(max);
    return (minRow + dRow >= 0) &&
        (maxRow + dRow < widget.rows) &&
        (minCol + dCol >= 0) &&
        (maxCol + dCol < widget.cols);
  }

  void moveGroupDirection(int anchorSlot, int dRow, int dCol) {
    final groupSlots = getConnectedGroupSlots(anchorSlot);
    final minRow = groupSlots.map((s) => s ~/ widget.cols).reduce(min);
    final maxRow = groupSlots.map((s) => s ~/ widget.cols).reduce(max);
    final minCol = groupSlots.map((s) => s % widget.cols).reduce(min);
    final maxCol = groupSlots.map((s) => s % widget.cols).reduce(max);

    if (minRow + dRow < 0 ||
        maxRow + dRow >= widget.rows ||
        minCol + dCol < 0 ||
        maxCol + dCol >= widget.cols) {
      AudioManager.instance.playDrop();
      return;
    }

    final anchorRow = anchorSlot ~/ widget.cols;
    final anchorCol = anchorSlot % widget.cols;
    final targetRow = anchorRow + dRow;
    final targetCol = anchorCol + dCol;
    final toAnchorSlot = targetRow * widget.cols + targetCol;

    moveGroup(anchorSlot, toAnchorSlot);
  }

  /// Moves an entire seamlessly joined group together from [fromAnchorSlot] to [toAnchorSlot],
  /// replacing the displaced pieces into the vacated positions like a synchronized team.
  void moveGroup(int fromAnchorSlot, int toAnchorSlot) {
    if (fromAnchorSlot == toAnchorSlot) return;

    final groupSlots = getConnectedGroupSlots(fromAnchorSlot);
    final fromRow = fromAnchorSlot ~/ widget.cols;
    final fromCol = fromAnchorSlot % widget.cols;
    final toRow = toAnchorSlot ~/ widget.cols;
    final toCol = toAnchorSlot % widget.cols;

    int dRow = toRow - fromRow;
    int dCol = toCol - fromCol;

    // Bounds of the group on the grid
    final minRow = groupSlots.map((s) => s ~/ widget.cols).reduce(min);
    final maxRow = groupSlots.map((s) => s ~/ widget.cols).reduce(max);
    final minCol = groupSlots.map((s) => s % widget.cols).reduce(min);
    final maxCol = groupSlots.map((s) => s % widget.cols).reduce(max);

    // Smart Clamping: Always keep the moving team cleanly within the board boundaries
    if (minRow + dRow < 0) dRow = -minRow;
    if (maxRow + dRow >= widget.rows) dRow = (widget.rows - 1) - maxRow;
    if (minCol + dCol < 0) dCol = -minCol;
    if (maxCol + dCol >= widget.cols) dCol = (widget.cols - 1) - maxCol;

    if (dRow == 0 && dCol == 0) {
      setState(() {
        _selectedSlot = null;
        _hoveredSlot = null;
        _activeDraggingGroup = {};
      });
      AudioManager.instance.playDrop();
      return;
    }

    // Map each piece in the group to its new slot
    final Map<int, int> groupSlotMoves = {};
    for (final s in groupSlots) {
      final r = s ~/ widget.cols + dRow;
      final c = s % widget.cols + dCol;
      groupSlotMoves[s] = r * widget.cols + c;
    }

    final targetSlots = groupSlotMoves.values.toSet();
    final vacatedSlots = groupSlots.where((s) => !targetSlots.contains(s)).toList();
    final displacedSlots = targetSlots.where((s) => !groupSlots.contains(s)).toList();

    // Map each displaced piece to a vacated slot using parallel team inversion
    final Map<int, int> displacedSlotMoves = {};
    for (final dSlot in displacedSlots) {
      final naturalVacated = (dSlot ~/ widget.cols - dRow) * widget.cols +
          (dSlot % widget.cols - dCol);
      if (vacatedSlots.contains(naturalVacated)) {
        displacedSlotMoves[dSlot] = naturalVacated;
      }
    }

    final remainingVacated =
        vacatedSlots.where((s) => !displacedSlotMoves.values.contains(s)).toList();
    final remainingDisplaced =
        displacedSlots.where((s) => !displacedSlotMoves.containsKey(s)).toList();

    // Sort to align columns nicely when sliding down
    remainingDisplaced.sort((a, b) => (a % widget.cols).compareTo(b % widget.cols));
    remainingVacated.sort((a, b) => (a % widget.cols).compareTo(b % widget.cols));

    for (int i = 0; i < remainingDisplaced.length; i++) {
      displacedSlotMoves[remainingDisplaced[i]] = remainingVacated[i];
    }

    final prevJoined = countTotalJoinedEdges();

    final groupPieces = groupSlots
        .map((s) => widget.pieces.firstWhere((p) => p.currentSlot == s))
        .toList();

    final displacedPieces = displacedSlots
        .map((s) => widget.pieces.firstWhere((p) => p.currentSlot == s))
        .toList();

    setState(() {
      for (final p in groupPieces) {
        p.currentSlot = groupSlotMoves[p.currentSlot]!;
        p.isPlaced = (p.currentSlot == p.id);
      }

      for (final p in displacedPieces) {
        p.currentSlot = displacedSlotMoves[p.currentSlot]!;
        p.isPlaced = (p.currentSlot == p.id);
      }

      _selectedSlot = null;
      _hoveredSlot = null;
      _activeDraggingGroup = {};
    });

    widget.onMoveMade?.call();

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
    widget.onMoveMade?.call();

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
                          onWillAcceptWithDetails: (details) => details.data != slotIndex,
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
                                  } else if (slotIndex == _selectedSlot) {
                                    // Clicking same anchor deselects
                                    AudioManager.instance.playDrop();
                                    setState(() {
                                      _selectedSlot = null;
                                    });
                                  } else if (selectedGroup.contains(slotIndex)) {
                                    // Tapped another piece in the SAME connected group: move towards that piece's direction!
                                    final anchorRow = _selectedSlot! ~/ widget.cols;
                                    final anchorCol = _selectedSlot! % widget.cols;
                                    final dRow = (slotRow - anchorRow).sign;
                                    final dCol = (slotCol - anchorCol).sign;
                                    if (dRow != 0 || dCol != 0) {
                                      moveGroupDirection(_selectedSlot!, dRow, dCol);
                                    } else {
                                      setState(() {
                                        _selectedSlot = slotIndex;
                                      });
                                    }
                                  } else {
                                    // Tapped slot outside group: shift group to that slot!
                                    moveGroup(_selectedSlot!, slotIndex);
                                  }
                                },
                                child: Draggable<int>(
                                  data: slotIndex,
                                  dragAnchorStrategy: (draggable, context, position) {
                                    final group = getConnectedGroupSlots(slotIndex);
                                    final anchorRow = slotIndex ~/ widget.cols;
                                    final anchorCol = slotIndex % widget.cols;
                                    final minRow = group.map((s) => s ~/ widget.cols).reduce(min);
                                    final minCol = group.map((s) => s % widget.cols).reduce(min);
                                    return Offset(
                                      (anchorCol - minCol + 0.5) * pieceW,
                                      (anchorRow - minRow + 0.5) * pieceH,
                                    );
                                  },
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

                  // 6. Floating Direction Controls for connected multi-piece groups
                  if (widget.isRearrangeMode && _selectedSlot != null)
                    ..._buildGroupActionControls(boardW, boardH, pieceW, pieceH),
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
    final minRow = groupSlots.map((s) => s ~/ widget.cols).reduce(min);
    final maxRow = groupSlots.map((s) => s ~/ widget.cols).reduce(max);
    final minCol = groupSlots.map((s) => s % widget.cols).reduce(min);
    final maxCol = groupSlots.map((s) => s % widget.cols).reduce(max);

    final groupW = (maxCol - minCol + 1) * pieceW;
    final groupH = (maxRow - minRow + 1) * pieceH;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Transform.scale(
        scale: 1.05,
        child: SizedBox(
          width: groupW,
          height: groupH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                      const BoxShadow(
                        color: Color(0x60000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
              ...groupSlots.map((s) {
                final sRow = s ~/ widget.cols;
                final sCol = s % widget.cols;
                final relX = (sCol - minCol) * pieceW;
                final relY = (sRow - minRow) * pieceH;

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
                      showNumberBadge: widget.showNumberBadge || widget.colorBlindMode,
                      isMysteryHidden: widget.isMysteryMode && !piece.isPlaced,
                      joinTop: joinTop,
                      joinRight: joinRight,
                      joinBottom: joinBottom,
                      joinLeft: joinLeft,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupActionControls(
    double boardW,
    double boardH,
    double pieceW,
    double pieceH,
  ) {
    if (_selectedSlot == null) return [];
    final group = getConnectedGroupSlots(_selectedSlot!);
    if (group.length < 2) return [];

    final canUp = canGroupMoveDirection(group, -1, 0);
    final canDown = canGroupMoveDirection(group, 1, 0);
    final canLeft = canGroupMoveDirection(group, 0, -1);
    final canRight = canGroupMoveDirection(group, 0, 1);

    final minRow = group.map((s) => s ~/ widget.cols).reduce(min);
    final maxRow = group.map((s) => s ~/ widget.cols).reduce(max);
    final minCol = group.map((s) => s % widget.cols).reduce(min);
    final maxCol = group.map((s) => s % widget.cols).reduce(max);

    final groupCenterCol = (minCol + maxCol + 1) / 2.0;
    final groupCenterRow = (minRow + maxRow + 1) / 2.0;

    final List<Widget> controls = [];

    Widget buildMoveButton({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      required double left,
      required double top,
      double width = 145,
      double height = 36,
    }) {
      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x90000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x80FFB300),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (canUp) {
      final btnTop = max(10.0, minRow * pieceH - 42.0);
      final btnLeft = (groupCenterCol * pieceW - 75.0).clamp(8.0, boardW - 158.0);
      controls.add(
        buildMoveButton(
          icon: Icons.arrow_upward_rounded,
          label: 'MOVE TEAM UP',
          onTap: () => moveGroupDirection(_selectedSlot!, -1, 0),
          left: btnLeft,
          top: btnTop,
        ),
      );
    }

    if (canDown) {
      final btnTop = min(boardH - 46.0, (maxRow + 1) * pieceH + 6.0);
      final btnLeft = (groupCenterCol * pieceW - 85.0).clamp(8.0, boardW - 178.0);
      controls.add(
        buildMoveButton(
          icon: Icons.arrow_downward_rounded,
          label: 'MOVE TEAM DOWN',
          onTap: () => moveGroupDirection(_selectedSlot!, 1, 0),
          left: btnLeft,
          top: btnTop,
          width: 165,
        ),
      );
    }

    if (canLeft) {
      final btnLeft = max(8.0, minCol * pieceW - 55.0);
      final btnTop = (groupCenterRow * pieceH - 18.0).clamp(8.0, boardH - 44.0);
      controls.add(
        buildMoveButton(
          icon: Icons.arrow_back_rounded,
          label: 'LEFT',
          onTap: () => moveGroupDirection(_selectedSlot!, 0, -1),
          left: btnLeft,
          top: btnTop,
          width: 80,
        ),
      );
    }

    if (canRight) {
      final btnLeft = min(boardW - 90.0, (maxCol + 1) * pieceW + 6.0);
      final btnTop = (groupCenterRow * pieceH - 18.0).clamp(8.0, boardH - 44.0);
      controls.add(
        buildMoveButton(
          icon: Icons.arrow_forward_rounded,
          label: 'RIGHT',
          onTap: () => moveGroupDirection(_selectedSlot!, 0, 1),
          left: btnLeft,
          top: btnTop,
          width: 90,
        ),
      );
    }

    return controls;
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
              showNumberBadge: widget.showNumberBadge || widget.colorBlindMode,
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
