import '../models/puzzle_level.dart';

class LevelRewardResult {
  final int stars;
  final int baseCoins;
  final int starBonusCoins;
  final int speedBonusCoins;
  final int totalCoins;
  final bool isNewSectionUnlocked;

  const LevelRewardResult({
    required this.stars,
    required this.baseCoins,
    required this.starBonusCoins,
    required this.speedBonusCoins,
    required this.totalCoins,
    required this.isNewSectionUnlocked,
  });
}

class RewardService {
  static LevelRewardResult calculateReward({
    required PuzzleLevel level,
    required int timeElapsedSeconds,
    required int hintsUsed,
    required int currentUnlockedSection,
  }) {
    // Stars calculation:
    // 3 Stars: Time <= targetTime and <= 1 hint used
    // 2 Stars: Time <= targetTime * 1.5 or <= 2 hints used
    // 1 Star:  Completed
    int stars;
    if (timeElapsedSeconds <= level.targetTimeSeconds && hintsUsed <= 1) {
      stars = 3;
    } else if (timeElapsedSeconds <= (level.targetTimeSeconds * 1.5).round() &&
        hintsUsed <= 3) {
      stars = 2;
    } else {
      stars = 1;
    }

    final baseCoins = level.coinReward;
    final starBonusCoins = stars * 15;

    // Speed bonus if beat target time
    int speedBonusCoins = 0;
    if (timeElapsedSeconds < level.targetTimeSeconds) {
      final remaining = level.targetTimeSeconds - timeElapsedSeconds;
      speedBonusCoins = (remaining ~/ 10) * 5;
    }

    final totalCoins = baseCoins + starBonusCoins + speedBonusCoins;

    // Check if level was subLevel 10 (which unlocks next section)
    final isLevelTenOfSection = (level.id % 10 == 0);
    final willUnlockNextSection = isLevelTenOfSection &&
        level.sectionId == currentUnlockedSection &&
        currentUnlockedSection < 5;

    return LevelRewardResult(
      stars: stars,
      baseCoins: baseCoins,
      starBonusCoins: starBonusCoins,
      speedBonusCoins: speedBonusCoins,
      totalCoins: totalCoins,
      isNewSectionUnlocked: willUnlockNextSection,
    );
  }
}
