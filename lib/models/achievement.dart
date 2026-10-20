import 'package:flutter/material.dart';
import 'player_progress.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int rewardCoins;
  final bool Function(PlayerProgress progress) isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rewardCoins,
    required this.isUnlocked,
  });

  static List<Achievement> getAllAchievements() {
    return [
      Achievement(
        id: 'first_step',
        title: 'First Assembly',
        description: 'Complete your first jigsaw puzzle level.',
        icon: Icons.extension,
        rewardCoins: 50,
        isUnlocked: (p) => p.completedLevelsCount >= 1,
      ),
      Achievement(
        id: 'section_1_master',
        title: 'Nature Explorer',
        description: 'Complete all 10 levels of Section 1 (Beginner).',
        icon: Icons.park,
        rewardCoins: 150,
        isUnlocked: (p) => p.highestUnlockedSection >= 2,
      ),
      Achievement(
        id: 'star_collector_15',
        title: 'Star Gazer',
        description: 'Collect 15 total stars.',
        icon: Icons.star_border,
        rewardCoins: 100,
        isUnlocked: (p) => p.totalStars >= 15,
      ),
      Achievement(
        id: 'star_collector_50',
        title: 'Constellation Champion',
        description: 'Collect 50 total stars across any levels.',
        icon: Icons.auto_awesome,
        rewardCoins: 250,
        isUnlocked: (p) => p.totalStars >= 50,
      ),
      Achievement(
        id: 'three_stars_5',
        title: 'Perfectionist',
        description: 'Earn 3 stars on at least 5 different levels.',
        icon: Icons.military_tech,
        rewardCoins: 120,
        isUnlocked: (p) =>
            p.levelStars.values.where((stars) => stars == 3).length >= 5,
      ),
      Achievement(
        id: 'section_2_master',
        title: 'Wilderness Veteran',
        description: 'Complete all 10 levels of Section 2 (Explorer).',
        icon: Icons.explore,
        rewardCoins: 200,
        isUnlocked: (p) => p.highestUnlockedSection >= 3,
      ),
      Achievement(
        id: 'speed_demon',
        title: 'Speed Assembler',
        description: 'Finish any puzzle in under 45 seconds.',
        icon: Icons.flash_on,
        rewardCoins: 150,
        isUnlocked: (p) =>
            p.levelBestTimes.values.any((time) => time <= 45),
      ),
      Achievement(
        id: 'daily_streak_3',
        title: 'Dedicated Puzzler',
        description: 'Maintain a 3-day Daily Puzzle streak.',
        icon: Icons.calendar_today,
        rewardCoins: 180,
        isUnlocked: (p) => p.dailyStreak >= 3,
      ),
      Achievement(
        id: 'section_3_master',
        title: 'Realm Conqueror',
        description: 'Complete all 10 levels of Section 3 (Adventure).',
        icon: Icons.castle,
        rewardCoins: 300,
        isUnlocked: (p) => p.highestUnlockedSection >= 4,
      ),
      Achievement(
        id: 'coin_hoarder',
        title: 'Treasure Vault',
        description: 'Amass 1,000 coins in your bank.',
        icon: Icons.monetization_on,
        rewardCoins: 200,
        isUnlocked: (p) => p.coins >= 1000,
      ),
      Achievement(
        id: 'puzzle_veteran_25',
        title: 'Halfway Hero',
        description: 'Successfully complete 25 levels.',
        icon: Icons.workspace_premium,
        rewardCoins: 350,
        isUnlocked: (p) => p.completedLevelsCount >= 25,
      ),
      Achievement(
        id: 'grand_master',
        title: 'Grand Jigsaw Master',
        description: 'Unlock Section 5 (Master) and reach level 41+.',
        icon: Icons.emoji_events,
        rewardCoins: 500,
        isUnlocked: (p) => p.highestUnlockedSection >= 5,
      ),
    ];
  }
}
