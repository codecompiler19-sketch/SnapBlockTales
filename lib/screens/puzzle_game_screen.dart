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
import '../widgets/game_settings_panel.dart';
import '../widgets/pause_dialog.dart';
import '../widgets/puzzle_tray.dart';
import '../widgets/victory_dialog.dart';
import 'coins_shop_screen.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ui.Image? _decodedImage;
  bool _isLoading = true;
  List<PuzzlePiece> _pieces = [];

  // Gameplay state
  int _elapsedSeconds = 0;
  int _movesCount = 0;
  int _imagePreviewCount = 0;
  // Coin cost for 2nd and subsequent image previews: 100 coins (1st look is free)
  static const int previewCoinCost = 100;

  // Dynamic winning coins and hint cost:
  // If winning is 30 -> hint is 15 coins. If winning is 50 -> hint is 25 coins.
  int get _levelWinningCoins {
    final count = widget.level.rows * widget.level.cols;
    if (count <= 9) return 30;
    if (count <= 16) return 50;
    return 120;
  }

  int get _hintCoinCost => (_levelWinningCoins / 2).round();
  Timer? _timer;
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _showWatermark = false;
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
      _movesCount = 0;
      _imagePreviewCount = 0;
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

  void _skipCurrentLevel() async {
    if (_isCompleted) return;
    _timer?.cancel();
    _isCompleted = true;

    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    AudioManager.instance.playTap();

    // Unlock next level without awarding stars, points, or showing victory screen
    await ProgressService.instance.skipLevel(widget.level.id);

    if (!mounted) return;

    final nextLevelId = widget.level.id + 1;
    if (nextLevelId <= 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Level ${widget.level.id} skipped (0 points/stars awarded). Loading Level $nextLevelId...'),
          duration: const Duration(milliseconds: 2200),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF374151),
        ),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Level skipped. You have reached the final level!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
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

    if (progressService.progress.congratsPopup) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (context) => VictoryCelebrationDialog(
          level: widget.level,
          rewardResult: reward,
          timeElapsedSeconds: _elapsedSeconds,
          movesCount: _movesCount,
          image: _decodedImage,
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Level ${widget.level.id} Completed in $_movesCount moves!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _useHint() async {
    final progress = ProgressService.instance;
    final isRelax = widget.gameMode == GameMode.relax;
    final hintCost = _hintCoinCost;

    final misplaced = _isRearrangeMode
        ? _pieces.where((p) => !p.isCorrect).toList()
        : _pieces.where((p) => !p.isPlaced).toList();

    if (misplaced.isEmpty) return;

    if (!isRelax) {
      if (progress.progress.inventoryHints > 0) {
        // Use an inventory hint
        await progress.useInventoryHint();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Used 1 Hint from Inventory (${progress.progress.inventoryHints} remaining)'),
              duration: const Duration(milliseconds: 1400),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Pay coins: half of the level winning amount
        if (progress.progress.coins < hintCost) {
          AudioManager.instance.triggerHaptic(HapticFeedbackType.selection);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Not enough coins for Hint (Requires $hintCost coins)'),
              duration: const Duration(milliseconds: 1400),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        await progress.spendCoins(hintCost, category: 'hint');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hint Used (-$hintCost coins)'),
              duration: const Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    _hintsUsed++;
    _movesCount++;
    AudioManager.instance.playHint();

    // Automatically arrange incorrect piece to correct place
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

  void _showImagePreviewModal() async {
    final progress = ProgressService.instance;
    final isRelax = widget.gameMode == GameMode.relax;
    final isFirstFree = _imagePreviewCount == 0;

    if (!isFirstFree && !isRelax) {
      if (progress.progress.coins < previewCoinCost) {
        AudioManager.instance.triggerHaptic(HapticFeedbackType.selection);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough coins for Image Preview (Requires $previewCoinCost coins)'),
            duration: Duration(milliseconds: 1600),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await progress.spendCoins(previewCoinCost);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image Preview (-$previewCoinCost coins)'),
            duration: Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() {
      _imagePreviewCount++;
    });

    AudioManager.instance.playTap();
    if (!mounted) return;

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.level.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isFirstFree ? 'Free 1st Preview' : 'Preview #$_imagePreviewCount (-$previewCoinCost🪙)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final progress = ProgressService.instance.progress;
        final isDark = progress.darkMode;
        final correctCount = _isRearrangeMode
            ? _pieces.where((p) => p.isCorrect).length
            : _pieces.where((p) => p.isPlaced).length;
        final totalCount = _pieces.length;

        final bgColor = isDark ? const Color(0xFF0F111A) : const Color(0xFFEFF2F7);
        final cardBgColor = isDark ? const Color(0xFF1B1D28) : Colors.white;
        final toolBarBg = isDark ? const Color(0xFF161824) : Colors.white;
        final bottomBarBg = isDark ? const Color(0xFF151722) : Colors.white;
        final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
        final textSecondary = isDark ? Colors.white54 : const Color(0xFF64748B);
        final toolIconColor = isDark ? Colors.white70 : const Color(0xFF475569);
        final borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

        return WillPopScope(
          onWillPop: () async {
            _saveCurrentSession();
            return true;
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: bgColor,
            endDrawer: GameSettingsPanel(
              isInGame: true,
              onClose: () => Navigator.pop(context),
              onSkipLevel: _skipCurrentLevel,
              onRestartLevel: () {
                Navigator.pop(context);
                _restartLevel();
              },
              onHome: () {
                _saveCurrentSession();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                        )
                      : Column(
                          children: [
                            // 1. TOP APP BAR (Back, Title, Coins, Menu)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                              child: Row(
                                children: [
                                  // Back Button (3D)
                                  IconButton(
                                    icon: Image.asset(
                                      'assets/images/3d/btn_back_3d.png',
                                      width: 26,
                                      height: 26,
                                      fit: BoxFit.contain,
                                    ),
                                    onPressed: () {
                                      _saveCurrentSession();
                                      Navigator.pop(context);
                                    },
                                  ),

                                  // Level Title & Dimension
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Level ${widget.level.id}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white.withOpacity(0.12)
                                                    : const Color(0xFFFFF3CD),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                widget.level.dimensionLabel,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? const Color(0xFFFFD700)
                                                      : const Color(0xFFD97706),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          widget.level.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Coins Counter (Tappable -> Opens Coins Shop)
                                  InkWell(
                                    onTap: () {
                                      AudioManager.instance.playTap();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CoinsShopScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      height: 34,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(17),
                                        image: const DecorationImage(
                                          image: AssetImage('assets/images/3d/panel_header_currency.png'),
                                          fit: BoxFit.fill,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            'assets/images/3d/icon_coin_gold_3d.png',
                                            width: 18,
                                            height: 18,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${progress.coins}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFFFE082),
                                              shadows: [
                                                Shadow(
                                                  color: Color(0xFF78350F),
                                                  offset: Offset(1, 1),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFFD700),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              size: 10,
                                              color: Color(0xFF78350F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // Menu / Settings Hamburger Button (3D)
                                  IconButton(
                                    icon: Image.asset(
                                      'assets/images/3d/btn_menu_settings_3d.png',
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.contain,
                                    ),
                                    tooltip: 'Menu & Settings',
                                    onPressed: () {
                                      AudioManager.instance.playTap();
                                      _scaffoldKey.currentState?.openEndDrawer();
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // 2. STATS STRIP (Correct, Moves, Time)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Correct Counter
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: cardBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                      boxShadow: isDark
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 14,
                                          color: Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$correctCount/$totalCount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Moves Counter
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: cardBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                      boxShadow: isDark
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.sync_alt_rounded,
                                          size: 14,
                                          color: Color(0xFF38BDF8),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$_movesCount Moves',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Timer
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: cardBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                      boxShadow: isDark
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: widget.gameMode == GameMode.timed
                                              ? Colors.redAccent
                                              : const Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 5),
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
                                                : textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. RESPONSIVE TOOLS BAR (Preview, Ghost, Numbers, Shuffle, HINT & AUTO - Never Cuts Off!)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: toolBarBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                  boxShadow: isDark
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact = constraints.maxWidth < 360;

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Left Tools: Preview, Ghost Watermark, Reshuffle (3D Icons)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildToolIcon(
                                              image3d: 'assets/images/3d/btn_preview_3d.png',
                                              tooltip: _imagePreviewCount == 0
                                                  ? 'Image Preview (1st Look Free)'
                                                  : 'Image Preview ($previewCoinCost coins)',
                                              badge: _imagePreviewCount == 0 ? 'FREE' : '$previewCoinCost🪙',
                                              iconColor: toolIconColor,
                                              onTap: _showImagePreviewModal,
                                              isCompact: isCompact,
                                            ),
                                            _buildToolIcon(
                                              image3d: 'assets/images/3d/btn_ghost_3d.png',
                                              tooltip: 'Ghost Watermark',
                                              iconColor: toolIconColor,
                                              isActive: _showWatermark,
                                              onTap: () {
                                                AudioManager.instance.playTap();
                                                setState(() {
                                                  _showWatermark = !_showWatermark;
                                                });
                                              },
                                              isCompact: isCompact,
                                            ),
                                            if (_isRearrangeMode)
                                              _buildToolIcon(
                                                image3d: 'assets/images/3d/btn_shuffle_3d.png',
                                                tooltip: 'Reshuffle Board',
                                                iconColor: toolIconColor,
                                                onTap: () {
                                                  AudioManager.instance.playTap();
                                                  _boardKey.currentState?.shufflePiecesOnBoard();
                                                },
                                                isCompact: isCompact,
                                              ),
                                          ],
                                        ),

                                        // Right Tools: HINT (3D Animated Icon - Arranges 1 piece automatically)
                                        _buildPillActionButton(
                                          image3d: 'assets/images/3d/btn_hint_3d.png',
                                          label: 'Hint',
                                          cost: progress.inventoryHints > 0
                                              ? '${progress.inventoryHints} left'
                                              : '$_hintCoinCost',
                                          color: const Color(0xFFFFD700),
                                          isDark: isDark,
                                          onTap: _useHint,
                                          isCompact: isCompact,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),

                            // 4. MAIN FOCUS: The 3D Puzzle Board
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                  showNumberBadge: false,
                                  onPieceSnapped: _onPieceSnapped,
                                  onPuzzleCompleted: _onPuzzleCompleted,
                                  onMoveMade: () {
                                    setState(() {
                                      _movesCount++;
                                    });
                                  },
                                ),
                              ),
                            ),

                            // 5. BOTTOM BAR: Interactive Helper Tip / Mode Controls
                            if (_isRearrangeMode)
                              Container(
                                margin: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: bottomBarBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                  boxShadow: isDark
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.touch_app_rounded,
                                      size: 16,
                                      color: Color(0xFFFFD700),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tap or drag pieces to swap. Correct neighbors merge automatically!',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
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
                                    color: bottomBarBg,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolIcon({
    IconData? icon,
    String? image3d,
    required String tooltip,
    required VoidCallback onTap,
    String? badge,
    Color iconColor = Colors.white70,
    bool isActive = false,
    bool isCompact = false,
  }) {
    final iconSize = isCompact ? 18.0 : 22.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 1.0 : 3.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 5 : 7),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0x33FFD700) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: image3d != null
                    ? Image.asset(image3d, width: iconSize, height: iconSize, fit: BoxFit.contain)
                    : Icon(
                        icon ?? Icons.help_outline,
                        size: isCompact ? 17 : 20,
                        color: isActive ? const Color(0xFFFFD700) : iconColor,
                      ),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: badge == 'FREE' ? const Color(0xFF10B981) : const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 2),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillActionButton({
    IconData? icon,
    String? image3d,
    required String label,
    required String cost,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    required bool isCompact,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 7 : 10,
          vertical: isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222638) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image3d != null)
              Image.asset(image3d, width: isCompact ? 16 : 20, height: isCompact ? 16 : 20, fit: BoxFit.contain)
            else
              Icon(icon ?? Icons.lightbulb, size: isCompact ? 13 : 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                cost,
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  fontWeight: FontWeight.w900,
                  color: isDark ? color : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
