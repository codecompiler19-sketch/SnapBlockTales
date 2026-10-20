import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/audio_manager.dart';
import '../services/progress_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allAchievements = Achievement.getAllAchievements();

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
          'Achievements & Rewards',
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

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allAchievements.length,
              itemBuilder: (context, index) {
                final ach = allAchievements[index];
                final isAchieved = ach.isUnlocked(progress);
                final isClaimed = progress.claimedAchievementIds.contains(ach.id);
                final canClaim = isAchieved && !isClaimed;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: canClaim
                        ? const Color(0xFF1E2838)
                        : const Color(0xFF161824),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: canClaim
                          ? const Color(0xFFFFD700)
                          : (isClaimed
                              ? const Color(0xFF10B981).withOpacity(0.5)
                              : Colors.white.withOpacity(0.08)),
                      width: canClaim ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon Badge
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: canClaim
                              ? const Color(0xFFFFD700).withOpacity(0.2)
                              : (isClaimed
                                  ? const Color(0xFF10B981).withOpacity(0.15)
                                  : Colors.white.withOpacity(0.06)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ach.icon,
                          color: canClaim
                              ? const Color(0xFFFFD700)
                              : (isClaimed
                                  ? const Color(0xFF10B981)
                                  : Colors.white30),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ach.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isAchieved
                                    ? Colors.white
                                    : Colors.white60,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ach.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Claim Action / Reward Badge
                      if (canClaim)
                        ElevatedButton.icon(
                          onPressed: () {
                            AudioManager.instance.playStar();
                            ProgressService.instance.claimAchievement(
                              ach.id,
                              ach.rewardCoins,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Claimed +${ach.rewardCoins} Coins!',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.monetization_on, size: 16),
                          label: Text('+${ach.rewardCoins}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: const Color(0xFF212121),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                        )
                      else if (isClaimed)
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Claimed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                size: 14,
                                color: Colors.white38,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${ach.rewardCoins}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
