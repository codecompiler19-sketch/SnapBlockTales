import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../models/puzzle_level.dart';
import '../services/audio_manager.dart';
import '../services/reward_service.dart';

class VictoryCelebrationDialog extends StatefulWidget {
  final PuzzleLevel level;
  final LevelRewardResult rewardResult;
  final int timeElapsedSeconds;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  const VictoryCelebrationDialog({
    super.key,
    required this.level,
    required this.rewardResult,
    required this.timeElapsedSeconds,
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
  int _displayedStars = 0;
  int _displayedCoins = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    // Trigger victory audio
    AudioManager.instance.playVictory();

    // Staggered star animation
    _triggerStarAnimations();
  }

  void _triggerStarAnimations() async {
    for (int i = 1; i <= widget.rewardResult.stars; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _displayedStars = i;
      });
      AudioManager.instance.playStar();
    }

    // Roll up coins
    await Future.delayed(const Duration(milliseconds: 200));
    final targetCoins = widget.rewardResult.totalCoins;
    const steps = 15;
    for (int s = 1; s <= steps; s++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() {
        _displayedCoins = ((targetCoins * s) / steps).round();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti explosion
        ConfettiWidget(
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
          numberOfParticles: 35,
          gravity: 0.25,
        ),

        // Dialog Content Card
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF23283B), Color(0xFF131520)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                width: 2.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Crown / Trophy Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withOpacity(0.5),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 40,
                    color: Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 12),

                // Victory Header
                const Text(
                  'PUZZLE COMPLETED!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.level.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),

                // 3 Animated Golden Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isEarned = index < _displayedStars;
                    return AnimatedScale(
                      scale: isEarned ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.star_rounded,
                          size: 44,
                          color: isEarned
                              ? const Color(0xFFFFD700)
                              : Colors.white24,
                          shadows: isEarned
                              ? const [
                                  BoxShadow(
                                    color: Color(0xFFFFD700),
                                    blurRadius: 14,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),

                // Stats Row: Time Elapsed & Coins
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Time
                      Column(
                        children: [
                          const Text(
                            'Time',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(widget.timeElapsedSeconds),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.white24,
                      ),
                      // Coins
                      Column(
                        children: [
                          const Text(
                            'Earned',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                size: 18,
                                color: Color(0xFFFFD700),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+$_displayedCoins',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // If unlocked next section announcement!
                if (widget.rewardResult.isNewSectionUnlocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF81C784),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open,
                            size: 16, color: Color(0xFF81C784)),
                        SizedBox(width: 6),
                        Text(
                          'New Section Unlocked!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF81C784),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    // Home button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          AudioManager.instance.playTap();
                          widget.onHome();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.home, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Replay button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          AudioManager.instance.playTap();
                          widget.onReplay();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Icon(Icons.refresh, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Next Level Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          AudioManager.instance.playTap();
                          widget.onNextLevel();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF212121),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
