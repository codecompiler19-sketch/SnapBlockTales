import 'package:flutter/material.dart';
import '../models/puzzle_section.dart';
import '../services/audio_manager.dart';
import '../services/progress_service.dart';
import '../widgets/level_card.dart';
import 'puzzle_game_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  final PuzzleSection section;

  const LevelSelectionScreen({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final levels = section.getLevels();

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            AudioManager.instance.playTap();
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              'Section ${section.id}: ${section.title}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              section.subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ProgressService.instance,
          builder: (context, _) {
            final progress = ProgressService.instance.progress;
            final completedCount = levels
                .where((l) => progress.levelStars.containsKey(l.id))
                .length;

            return Column(
              children: [
                // Section Summary Header Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: section.gradientColors[0].withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: $completedCount / ${levels.length} Completed',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${levels.fold(0, (sum, l) => sum + progress.getStarsForLevel(l.id))} / ${levels.length * 3}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2-column or 3-column Grid of Level Cards
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final isUnlocked = progress.isLevelUnlocked(level.id);
                      final isCompleted =
                          progress.levelStars.containsKey(level.id);
                      final stars = progress.getStarsForLevel(level.id);
                      final bestTime = progress.getBestTimeForLevel(level.id);

                      return LevelCardWidget(
                        level: level,
                        isUnlocked: isUnlocked,
                        isCompleted: isCompleted,
                        earnedStars: stars,
                        bestTimeSeconds: bestTime,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PuzzleGameScreen(level: level),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
