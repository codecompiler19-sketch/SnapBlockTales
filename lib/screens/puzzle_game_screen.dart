import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../game/puzzle_board.dart';
import '../game/puzzle_edge_generator.dart';
import '../models/game_mode.dart';
import '../models/player_progress.dart';
import '../models/puzzle_level.dart';
import '../models/puzzle_piece.dart';
import '../services/audio_manager.dart';
import '../services/image_service.dart';
import '../services/progress_service.dart';
import '../services/reward_service.dart';
import '../widgets/pause_dialog.dart';
import '../widgets/puzzle_tray.dart';
import '../widgets/victory_dialog.dart';
import 'settings_screen.dart';

class PuzzleGameScreen extends StatefulWidget {
  final PuzzleLevel level;
  final GameMode gameMode;
  final SavedGameState? resumeState;
  final String? customPhotoPath;

  const PuzzleGameScreen({
    super.key,
    required this.level,
    this.gameMode = GameMode.classic,
    this.resumeState,
    this.customPhotoPath,
  });

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen>
    with WidgetsBindingObserver {
  final GlobalKey<PuzzleBoardWidgetState> _boardKey =
      GlobalKey<PuzzleBoardWidgetState>();

  ui.Image? _decodedImage;
  bool _isLoading = true;
  List<PuzzlePiece> _pieces = [];

  // Gameplay state
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _showWatermark = false;
  bool _showNumbers = false;
  int? _highlightedPieceId;
  int _hintsUsed = 0;

  // On-Board Rearrange (Default per user request: pieces live directly on board)
  bool _isRearrangeMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPuzzle();
  }

  Future<void> _initPuzzle() async {
    // Generate deterministic puzzle pieces
    _pieces = PuzzleEdgeGenerator.generatePieces(
      rows: widget.level.rows,
      cols: widget.level.cols,
      seed: widget.level.id * 1000 + widget.level.rows,
    );

    // Initial shuffle for on-board rearrange mode
    if (_isRearrangeMode) {
      if (widget.resumeState == null || widget.resumeState!.placedPieceIds.isEmpty) {
        _shufflePiecesList();
      } else {
        _elapsedSeconds = widget.resumeState!.elapsedSeconds;
      }
    }

    // Load Image
    final isCustom = widget.customPhotoPath != null;
    final imagePath = widget.customPhotoPath ?? widget.level.imagePath;

    try {
      _decodedImage = await ImageService.instance.loadImage(
        imagePath,
        isFile: isCustom,
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _startTimer();
      AudioManager.instance.playLevelStart();
    }
  }

  void _shufflePiecesList() {
    final rand = Random();
    final count = _pieces.length;
    final List<int> slots = List.generate(count, (i) => i);
    do {
      slots.shuffle(rand);
    } while (count > 2 && slots.asMap().entries.any((e) => e.key == e.value));

    for (int i = 0; i < count; i++) {
      _pieces[i].currentSlot = slots[i];
      _pieces[i].isPlaced = (_pieces[i].currentSlot == _pieces[i].id);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isCompleted) {
        setState(() {
          _elapsedSeconds++;
        });

        if (widget.gameMode == GameMode.timed) {
          final remaining = widget.level.targetTimeSeconds - _elapsedSeconds;
          if (remaining <= 0) {
            _timer?.cancel();
            _handleTimeOut();
          }
        }
      }
    });
  }

  void _handleTimeOut() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Time Up!', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'The challenge countdown ran out! Would you like to try again?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartLevel();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            child: const Text('Retry', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _restartLevel() {
    setState(() {
      _elapsedSeconds = 0;
      _hintsUsed = 0;
      _highlightedPieceId = null;
      _isCompleted = false;
      if (_isRearrangeMode) {
        _shufflePiecesList();
      } else {
        for (final p in _pieces) {
          p.isPlaced = false;
        }
      }
    });
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveCurrentSession();
      AudioManager.instance.pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      AudioManager.instance.resumeBgm();
    }
  }

  void _saveCurrentSession() {
    if (_isCompleted || _pieces.isEmpty) return;
    final placedIds = _pieces.where((p) => p.isPlaced).map((p) => p.id).toList();

    ProgressService.instance.saveGameSession(
      SavedGameState(
        levelId: widget.level.id,
        gameMode: widget.gameMode.name,
        elapsedSeconds: _elapsedSeconds,
        placedPieceIds: placedIds,
        customImagePath: widget.customPhotoPath,
        rows: widget.level.rows,
        cols: widget.level.cols,
      ),
    );
  }

  void _onPieceSnapped() {
    setState(() {
      if (_highlightedPieceId != null) {
        final hp = _pieces.firstWhere(
          (p) => p.id == _highlightedPieceId,
          orElse: () => _pieces.first,
        );
        if (hp.isCorrect) {
          _highlightedPieceId = null;
        }
      }
    });
  }

  void _onPuzzleCompleted() {
    if (_isCompleted) return;
    _isCompleted = true;
    _timer?.cancel();

    final progressService = ProgressService.instance;
    final reward = RewardService.calculateReward(
      level: widget.level,
      timeElapsedSeconds: _elapsedSeconds,
      hintsUsed: _hintsUsed,
      currentUnlockedSection: progressService.progress.highestUnlockedSection,
    );

    progressService.completeLevel(
      widget.level.id,
      reward.stars,
      _elapsedSeconds,
      reward.totalCoins,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VictoryCelebrationDialog(
        level: widget.level,
        rewardResult: reward,
        timeElapsedSeconds: _elapsedSeconds,
        onNextLevel: () {
          Navigator.pop(context);
          final nextLevelId = widget.level.id + 1;
          if (nextLevelId <= 50) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PuzzleGameScreen(
                  level: PuzzleLevel.getLevelById(nextLevelId),
                  gameMode: widget.gameMode,
                ),
              ),
            );
          } else {
            Navigator.pop(context);
          }
        },
        onReplay: () {
          Navigator.pop(context);
          _restartLevel();
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _useHint() async {
    final progress = ProgressService.instance;
    final isRelax = widget.gameMode == GameMode.relax;
    const hintCost = 25;

    if (!isRelax && progress.progress.coins < hintCost) {
      AudioManager.instance.triggerHaptic(HapticFeedbackType.selection);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins for Hint (Requires 25 coins)'),
          duration: Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final misplaced = _isRearrangeMode
        ? _pieces.where((p) => !p.isCorrect).toList()
        : _pieces.where((p) => !p.isPlaced).toList();

    if (misplaced.isEmpty) return;

    if (!isRelax) {
      await progress.spendCoins(hintCost);
    }

    _hintsUsed++;
    AudioManager.instance.playHint();

    misplaced.shuffle();
    final hintPiece = misplaced.first;

    setState(() {
      _highlightedPieceId = hintPiece.id;
    });

    final targetRow = (hintPiece.id ~/ widget.level.cols) + 1;
    final targetCol = (hintPiece.id % widget.level.cols) + 1;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Target location highlighted! (Row $targetRow, Col $targetCol)',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _useAutoPlace() async {
    final progress = ProgressService.instance;
    final isRelax = widget.gameMode == GameMode.relax;
    const autoCost = 60;

    if (!isRelax && progress.progress.coins < autoCost) {
      AudioManager.instance.triggerHaptic(HapticFeedbackType.selection);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins for Auto-Place (Requires 60 coins)'),
          duration: Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!isRelax) {
      await progress.spendCoins(autoCost);
    }

    _hintsUsed += 2;

    if (_isRearrangeMode) {
      _boardKey.currentState?.autoPlaceOnePiece();
    } else {
      final unplaced = _pieces.where((p) => !p.isPlaced).toList();
      if (unplaced.isNotEmpty) {
        unplaced.shuffle();
        final piece = unplaced.first;
        _boardKey.currentState?.snapPiece(piece);
      }
    }
  }

  void _showImagePreviewModal() {
    AudioManager.instance.playTap();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2235),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.level.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _decodedImage != null
                    ? RawImage(
                        image: _decodedImage,
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        widget.level.imagePath,
                        fit: BoxFit.contain,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pauseGame() {
    AudioManager.instance.playTap();
    setState(() {
      _isPaused = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PauseDialog(
        onResume: () {
          Navigator.pop(context);
          setState(() {
            _isPaused = false;
          });
        },
        onRestart: () {
          Navigator.pop(context);
          _restartLevel();
        },
        onSettings: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
        onExit: () {
          _saveCurrentSession();
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance.progress;
    final correctCount = _isRearrangeMode
        ? _pieces.where((p) => p.isCorrect).length
        : _pieces.where((p) => p.isPlaced).length;
    final totalCount = _pieces.length;

    return WillPopScope(
      onWillPop: () async {
        _saveCurrentSession();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F111A),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                )
              : Column(
                  children: [
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              _saveCurrentSession();
                              Navigator.pop(context);
                            },
                          ),

                          // Level Title & Mode
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Level ${widget.level.id}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        widget.level.dimensionLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFFFD700),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  widget.level.title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Coins Counter
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  size: 16,
                                  color: Color(0xFFFFD700),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${progress.coins}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Pause Button
                          IconButton(
                            icon: const Icon(
                              Icons.pause_circle_filled_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _pauseGame,
                          ),
                        ],
                      ),
                    ),

                    // Controls / Stats Sub-Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Placed / Correct Progress Counter
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1D28),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$correctCount / $totalCount Correct',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Timer
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1D28),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: widget.gameMode == GameMode.timed
                                      ? Colors.redAccent
                                      : const Color(0xFF81C784),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.gameMode == GameMode.timed
                                      ? _formatTime(
                                          widget.level.targetTimeSeconds -
                                              _elapsedSeconds,
                                        )
                                      : _formatTime(_elapsedSeconds),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: widget.gameMode == GameMode.timed
                                        ? Colors.redAccent
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons: Preview, Ghost, Hint, Auto
                          Row(
                            children: [
                              // Full Image Preview Modal
                              IconButton(
                                icon: const Icon(
                                  Icons.image,
                                  size: 20,
                                  color: Colors.white70,
                                ),
                                tooltip: 'Full Image Preview',
                                onPressed: _showImagePreviewModal,
                              ),

                              // Ghost Watermark Toggle
                              IconButton(
                                icon: Icon(
                                  _showWatermark
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 20,
                                  color: _showWatermark
                                      ? const Color(0xFFFFD700)
                                      : Colors.white54,
                                ),
                                tooltip: 'Toggle Board Ghost Guide',
                                onPressed: () {
                                  AudioManager.instance.playTap();
                                  setState(() {
                                    _showWatermark = !_showWatermark;
                                  });
                                },
                              ),

                              // Tile Numbers Toggle
                              IconButton(
                                icon: Icon(
                                  Icons.pin_outlined,
                                  size: 20,
                                  color: _showNumbers
                                      ? const Color(0xFFFFD700)
                                      : Colors.white54,
                                ),
                                tooltip: 'Toggle Numbers Guide',
                                onPressed: () {
                                  AudioManager.instance.playTap();
                                  setState(() {
                                    _showNumbers = !_showNumbers;
                                  });
                                },
                              ),

                              // Hint (25 Coins)
                              InkWell(
                                onTap: _useHint,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E344A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFFD700)
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb,
                                        size: 15,
                                        color: Color(0xFFFFD700),
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Hint',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFFD700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Auto-Place (60 Coins)
                              InkWell(
                                onTap: _useAutoPlace,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E344A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF81C784)
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.auto_fix_high,
                                        size: 15,
                                        color: Color(0xFF81C784),
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Auto',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF81C784),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Main Focus: The 3D Puzzle Board
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: PuzzleBoardWidget(
                          key: _boardKey,
                          image: _decodedImage,
                          pieces: _pieces,
                          rows: widget.level.rows,
                          cols: widget.level.cols,
                          showWatermark: _showWatermark,
                          highlightedPieceId: _highlightedPieceId,
                          isMysteryMode: widget.gameMode == GameMode.mystery,
                          isRearrangeMode: _isRearrangeMode,
                          showNumberBadge: _showNumbers,
                          onPieceSnapped: _onPieceSnapped,
                          onPuzzleCompleted: _onPuzzleCompleted,
                        ),
                      ),
                    ),

                    // Bottom Bar: Instructions / Mode Controls
                    if (_isRearrangeMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141622),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Reshuffle Button
                            OutlinedButton.icon(
                              onPressed: () {
                                AudioManager.instance.playTap();
                                _boardKey.currentState?.shufflePiecesOnBoard();
                              },
                              icon: const Icon(Icons.shuffle, size: 16, color: Color(0xFFFFD700)),
                              label: const Text(
                                'Reshuffle',
                                style: TextStyle(color: Color(0xFFFFD700), fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0x66FFD700)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),

                            // Helper text
                            const Expanded(
                              child: Text(
                                '🧩 Swap pieces to match the picture!\n✨ Correct neighbors magnetically join & boundaries vanish',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            color: const Color(0xFF141622),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    AudioManager.instance.playTap();
                                    setState(() {
                                      _isRearrangeMode = true;
                                      _shufflePiecesList();
                                    });
                                  },
                                  icon: const Icon(Icons.grid_on, size: 14, color: Color(0xFFFFD700)),
                                  label: const Text(
                                    'Switch to On-Board Swap',
                                    style: TextStyle(color: Color(0xFFFFD700), fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PuzzleTrayWidget(
                            image: _decodedImage,
                            pieces: _pieces,
                            rows: widget.level.rows,
                            cols: widget.level.cols,
                            boardKey: _boardKey,
                            highlightedPieceId: _highlightedPieceId,
                            isMysteryMode: widget.gameMode == GameMode.mystery,
                            leftHanded: progress.leftHanded,
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
