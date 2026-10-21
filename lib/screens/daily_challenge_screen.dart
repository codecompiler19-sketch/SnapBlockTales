import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../models/puzzle_level.dart';
import '../services/audio_manager.dart';
import '../services/image_service.dart';
import '../services/progress_service.dart';
import 'puzzle_game_screen.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Deterministic daily level based on day of year
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final dailyLevelId = (dayOfYear % 50) + 1;
    final dailyLevel = PuzzleLevel.getLevelById(dailyLevelId);

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
        title: const Text(
          'Daily Challenge',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ProgressService.instance,
          builder: (context, _) {
            final progress = ProgressService.instance.progress;
            final isCompletedToday = progress.lastDailyDate == todayKey;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Streak Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40F59E0B),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${progress.dailyStreak} Day Streak!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Solve every day for escalating coin bonuses',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Today's Featured Card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2235),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isCompletedToday
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B).withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Artwork
                            ImageService.instance.buildLevelImage(
                              dailyLevel.imagePath,
                              fit: BoxFit.cover,
                            ),

                            // Gradient Scrim
                            Container(
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

                            // Completed Badge or Date Tag
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompletedToday
                                      ? const Color(0xFF10B981)
                                      : Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCompletedToday
                                          ? Icons.check_circle_rounded
                                          : Icons.today,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isCompletedToday
                                          ? 'Completed!'
                                          : todayKey,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom Info
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dailyLevel.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Difficulty: ${dailyLevel.dimensionLabel} (${dailyLevel.pieceCount} pieces)',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.monetization_on,
                                        size: 16,
                                        color: Color(0xFFFFD700),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+${100 + (progress.dailyStreak * 20)} Coins',
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start Challenge Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playTap();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PuzzleGameScreen(
                              level: dailyLevel,
                              gameMode: GameMode.daily,
                            ),
                          ),
                        ).then((_) {
                          // If finished, record daily completion
                          if (progress.levelStars.containsKey(dailyLevel.id)) {
                            ProgressService.instance
                                .recordDailyCompletion(todayKey);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompletedToday
                            ? const Color(0xFF10B981)
                            : const Color(0xFFFFD700),
                        foregroundColor: const Color(0xFF212121),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCompletedToday
                                ? Icons.replay_rounded
                                : Icons.play_arrow_rounded,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCompletedToday
                                ? 'REPLAY TODAY\'S PUZZLE'
                                : 'START DAILY PUZZLE',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
