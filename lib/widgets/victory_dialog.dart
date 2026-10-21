import 'dart:ui' as ui;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../models/puzzle_level.dart';
import '../services/audio_manager.dart';
import '../services/image_service.dart';
import '../services/reward_service.dart';

class VictoryCelebrationDialog extends StatefulWidget {
  final PuzzleLevel level;
  final LevelRewardResult rewardResult;
  final int timeElapsedSeconds;
  final int movesCount;
  final ui.Image? image;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  const VictoryCelebrationDialog({
    super.key,
    required this.level,
    required this.rewardResult,
    required this.timeElapsedSeconds,
    this.movesCount = 0,
    this.image,
    required this.onNextLevel,
    required this.onReplay,
    required this.onHome,
  });

  @override
  State<VictoryCelebrationDialog> createState() =>
      _VictoryCelebrationDialogState();
}

class _VictoryCelebrationDialogState extends State<VictoryCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLiked = false;
  bool _isDisliked = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _animController.forward();
    AudioManager.instance.playVictory();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onLikeTap() {
    AudioManager.instance.playTap();
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) _isDisliked = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLiked ? 'Artwork liked! ❤️' : 'Like removed'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDislikeTap() {
    AudioManager.instance.playTap();
    setState(() {
      _isDisliked = !_isDisliked;
      if (_isDisliked) _isLiked = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isDisliked ? 'Thanks for your feedback!' : 'Dislike removed'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDownloadTap() {
    AudioManager.instance.playTap();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Completed masterpiece saved to your gallery! 🖼️'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onShareTap() {
    AudioManager.instance.playTap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Solved Level ${widget.level.id} (${widget.level.title}) in ${_formatTime(widget.timeElapsedSeconds)} with ${widget.movesCount > 0 ? widget.movesCount : (widget.level.rows * widget.level.cols * 2)} moves! 🧩',
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.82),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Responsive Board
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 380,
                      height: 520,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // 1. Carved Wood & Stone Board Base
                          Positioned(
                            top: 28,
                            left: 10,
                            width: 360,
                            height: 480,
                            child: Image.asset(
                              'assets/images/3d/panel_victory_board.png',
                              fit: BoxFit.fill,
                            ),
                          ),

                          // 2. Stars Cluster Banner (Sitting directly on the arch crest)
                          Positioned(
                            top: 14,
                            left: 110,
                            width: 160,
                            height: 75,
                            child: Image.asset(
                              'assets/images/3d/stars_banner_3d.png',
                              fit: BoxFit.contain,
                            ),
                          ),

                          // 3. Ribbon "YOU WIN!" (Pinned seamlessly across the arch & star base)
                          Positioned(
                            top: 50,
                            left: 70,
                            width: 240,
                            height: 68,
                            child: Image.asset(
                              'assets/images/3d/ribbon_you_win.png',
                              fit: BoxFit.contain,
                            ),
                          ),

                          // 4. Framed Artwork (Nicely centered in parchment area)
                          Positioned(
                            top: 135,
                            left: 100,
                            width: 180,
                            height: 130,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF6D4C41),
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: widget.image != null
                                    ? RawImage(
                                        image: widget.image,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : ImageService.instance.buildLevelImage(
                                        widget.level.imagePath,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                              ),
                            ),
                          ),

                          // 5. Social Action Icons (Like, Dislike, Download, Share)
                          Positioned(
                            top: 232,
                            right: 104,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3E2723).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD7CCC8).withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: _onLikeTap,
                                    child: Icon(
                                      _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                                      color: _isLiked ? const Color(0xFFFFD700) : Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: _onDislikeTap,
                                    child: Icon(
                                      _isDisliked ? Icons.thumb_down_rounded : Icons.thumb_down_alt_outlined,
                                      color: _isDisliked ? Colors.redAccent : Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: _onDownloadTap,
                                    child: const Icon(
                                      Icons.file_download_outlined,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: _onShareTap,
                                    child: const Icon(
                                      Icons.share_outlined,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 6. Level Title
                          Positioned(
                            top: 275,
                            left: 60,
                            width: 260,
                            child: Text(
                              'Level ${widget.level.id}: ${widget.level.title}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF4E342E),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),

                          // 7. Coin Reward Pill (Clean golden gradient capsule with 3D coin)
                          Positioned(
                            top: 302,
                            left: 110,
                            width: 160,
                            height: 38,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: const Color(0xFFFFE082),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF78350F).withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/3d/icon_coin_gold_3d.png',
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+${widget.rewardResult.totalCoins}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFF78350F),
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 8. Stats Bar (Moves & Time in warm parchment style)
                          Positioned(
                            top: 350,
                            left: 90,
                            width: 200,
                            height: 30,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8D7B8).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xFFBCAAA4),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.sync_alt_rounded,
                                        color: Color(0xFF1976D2),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.movesCount > 0 ? widget.movesCount : (widget.level.rows * widget.level.cols * 2)} Moves',
                                        style: const TextStyle(
                                          color: Color(0xFF4E342E),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: const Color(0xFF8D6E63).withOpacity(0.4),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        color: Color(0xFF2E7D32),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTime(widget.timeElapsedSeconds),
                                        style: const TextStyle(
                                          color: Color(0xFF4E342E),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 9. Left Socket Button: Menu / Home (Centered at socket)
                          Positioned(
                            left: 72,
                            top: 429,
                            width: 56,
                            height: 56,
                            child: GestureDetector(
                              onTap: () {
                                AudioManager.instance.playTap();
                                widget.onHome();
                              },
                              child: Image.asset(
                                'assets/images/3d/btn_circle_menu.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // 10. Center Socket Button: Next Level (Big Play Button)
                          Positioned(
                            left: 154,
                            top: 421,
                            width: 72,
                            height: 72,
                            child: GestureDetector(
                              onTap: () {
                                AudioManager.instance.playTap();
                                widget.onNextLevel();
                              },
                              child: Image.asset(
                                'assets/images/3d/btn_circle_next.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // 11. Right Socket Button: Replay / Restart (Centered at socket)
                          Positioned(
                            left: 252,
                            top: 429,
                            width: 56,
                            height: 56,
                            child: GestureDetector(
                              onTap: () {
                                AudioManager.instance.playTap();
                                widget.onReplay();
                              },
                              child: Image.asset(
                                'assets/images/3d/btn_circle_restart.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Confetti Explosion
            IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.amber,
                ],
                numberOfParticles: 40,
                gravity: 0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
