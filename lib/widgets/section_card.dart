import 'package:flutter/material.dart';
import '../models/puzzle_section.dart';
import '../services/audio_manager.dart';

class SectionCardWidget extends StatelessWidget {
  final PuzzleSection section;
  final bool isUnlocked;
  final int completedLevelsCount;
  final int earnedStars;
  final VoidCallback onTap;

  const SectionCardWidget({
    super.key,
    required this.section,
    required this.isUnlocked,
    required this.completedLevelsCount,
    required this.earnedStars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressFraction = completedLevelsCount / section.levelCount;
    final isFullyCompleted = completedLevelsCount == section.levelCount;

    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          AudioManager.instance.playTap();
          onTap();
        } else {
          AudioManager.instance.triggerHaptic(HapticFeedbackType.medium);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Complete all levels of Section ${section.id - 1} to unlock ${section.title}!',
              ),
              duration: const Duration(milliseconds: 1400),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: isUnlocked
                ? [
                    section.gradientColors[0].withOpacity(0.85),
                    section.gradientColors[1].withOpacity(0.95),
                  ]
                : [
                    const Color(0xFF1E202C),
                    const Color(0xFF13151F),
                  ],
          ),
          border: Border.all(
            color: isFullyCompleted
                ? const Color(0xFFFFD700)
                : (isUnlocked
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.06)),
            width: isFullyCompleted ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? section.gradientColors[0].withOpacity(0.35)
                  : Colors.black.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Section Icon Badge
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isUnlocked ? section.icon : Icons.lock_rounded,
                color: isUnlocked ? Colors.white : Colors.white30,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),

            // Middle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SECTION ${section.id}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isUnlocked
                              ? const Color(0xFFFFD700)
                              : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  ${section.title}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.white : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    section.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnlocked ? Colors.white70 : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 6,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFullyCompleted
                            ? const Color(0xFFFFD700)
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Stats: X/10 levels & Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedLevelsCount/${section.levelCount} Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? Colors.white70 : Colors.white38,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$earnedStars/${section.levelCount * 3}',
                            style: const TextStyle(
                              fontSize: 11,
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

            const SizedBox(width: 8),
            Icon(
              isUnlocked
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.lock_outline_rounded,
              color: isUnlocked ? Colors.white70 : Colors.white24,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
