import 'package:flutter/material.dart';
import '../models/puzzle_level.dart';
import '../services/audio_manager.dart';

class LevelCardWidget extends StatelessWidget {
  final PuzzleLevel level;
  final bool isUnlocked;
  final bool isCompleted;
  final int earnedStars;
  final int? bestTimeSeconds;
  final VoidCallback onTap;

  const LevelCardWidget({
    super.key,
    required this.level,
    required this.isUnlocked,
    required this.isCompleted,
    required this.earnedStars,
    this.bestTimeSeconds,
    required this.onTap,
  });

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          AudioManager.instance.playTap();
          onTap();
        } else {
          AudioManager.instance.triggerHaptic(HapticFeedbackType.medium);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete the previous level to unlock!'),
              duration: Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isUnlocked ? const Color(0xFF1E2235) : const Color(0xFF141622),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFFFFD700).withOpacity(0.6)
                : (isUnlocked
                    ? const Color(0xFF3B82F6).withOpacity(0.5)
                    : Colors.white.withOpacity(0.06)),
            width: isCompleted ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? const Color(0x33FFD700)
                  : (isUnlocked
                      ? const Color(0x223B82F6)
                      : Colors.black.withOpacity(0.3)),
              blurRadius: isUnlocked ? 10 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Artwork Thumbnail
              Positioned.fill(
                child: isUnlocked
                    ? Image.asset(
                        level.imagePath,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: const Color(0xFF141724),
                        child: Center(
                          child: Image.asset(
                            'assets/images/3d/node_level_locked.png',
                            width: 68,
                            height: 68,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
              ),

              // Gradient Overlay for Readability
              if (isUnlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                ),

              // Level Number Badge (Top-Left)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFFFD700)
                        : (isUnlocked
                            ? const Color(0xFF3B82F6)
                            : Colors.black54),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'L${level.id}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? const Color(0xFF212121)
                          : Colors.white,
                    ),
                  ),
                ),
              ),

              // Dimensions Badge (Top-Right)
              if (isUnlocked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      level.dimensionLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Bottom Info: Title, Stars, Best Time
              if (isUnlocked)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        level.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 3 Stars (3D Stars)
                          Row(
                            children: List.generate(3, (i) {
                              final isEarned = i < earnedStars;
                              return Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Image.asset(
                                  isEarned
                                      ? 'assets/images/3d/star_mini_gold.png'
                                      : 'assets/images/3d/icon_star_empty_3d.png',
                                  width: 15,
                                  height: 15,
                                  fit: BoxFit.contain,
                                ),
                              );
                            }),
                          ),
                          // Best time if recorded
                          if (bestTimeSeconds != null)
                            Text(
                              _formatTime(bestTimeSeconds!),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF81C784),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
