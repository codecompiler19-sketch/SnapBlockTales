import 'package:flutter/material.dart';
import 'puzzle_level.dart';

class PuzzleSection {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final int startLevel;
  final int endLevel;
  final List<Color> gradientColors;
  final IconData icon;

  const PuzzleSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.startLevel,
    required this.endLevel,
    required this.gradientColors,
    required this.icon,
  });

  int get levelCount => endLevel - startLevel + 1;

  static const List<PuzzleSection> sections = [
    PuzzleSection(
      id: 1,
      title: 'Beginner',
      subtitle: 'Scenic Nature',
      description: 'Gentle grids and peaceful landscapes to start your journey.',
      startLevel: 1,
      endLevel: 10,
      gradientColors: [Color(0xFF2E7D32), Color(0xFF00796B)],
      icon: Icons.eco,
    ),
    PuzzleSection(
      id: 2,
      title: 'Explorer',
      subtitle: 'Wild Horizons',
      description: 'Journey across exotic savannas, deep oceans, and wildlife sanctuaries.',
      startLevel: 11,
      endLevel: 20,
      gradientColors: [Color(0xFFE65100), Color(0xFFF57C00)],
      icon: Icons.explore,
    ),
    PuzzleSection(
      id: 3,
      title: 'Adventure',
      subtitle: 'Mythic Realms',
      description: 'Floating isles, fantasy castles, and mystical luminous worlds.',
      startLevel: 21,
      endLevel: 30,
      gradientColors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
      icon: Icons.auto_awesome,
    ),
    PuzzleSection(
      id: 4,
      title: 'Expert',
      subtitle: 'Deep Cosmos',
      description: 'Glowing nebulae, ringed planets, and cosmic stargates.',
      startLevel: 31,
      endLevel: 40,
      gradientColors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
      icon: Icons.public,
    ),
    PuzzleSection(
      id: 5,
      title: 'Master',
      subtitle: 'Ancient Wonders',
      description: 'Grand pyramids, sacred temples, and timeless monumental architecture.',
      startLevel: 41,
      endLevel: 50,
      gradientColors: [Color(0xFFB71C1C), Color(0xFFC62828)],
      icon: Icons.military_tech,
    ),
  ];

  static PuzzleSection getSectionById(int id) {
    return sections.firstWhere((s) => s.id == id, orElse: () => sections.first);
  }

  List<PuzzleLevel> getLevels() {
    return PuzzleLevel.getAllLevels().where((l) => l.sectionId == id).toList();
  }
}
