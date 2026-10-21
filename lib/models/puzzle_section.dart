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
      subtitle: 'Art & Crafts',
      description: 'Painting studios, colorful crafts, and creative workshops.',
      startLevel: 1,
      endLevel: 10,
      gradientColors: [Color(0xFF2E7D32), Color(0xFF00796B)],
      icon: Icons.palette_rounded,
    ),
    PuzzleSection(
      id: 2,
      title: 'Explorer',
      subtitle: 'Vehicles & Travel',
      description: 'Fire trucks, toy trains, farm tractors, and flying rockets.',
      startLevel: 11,
      endLevel: 20,
      gradientColors: [Color(0xFFE65100), Color(0xFFF57C00)],
      icon: Icons.directions_bus_rounded,
    ),
    PuzzleSection(
      id: 3,
      title: 'Adventure',
      subtitle: 'Toyland Fun',
      description: 'Teddy picnics, block castles, dollhouses, and toy workshops.',
      startLevel: 21,
      endLevel: 30,
      gradientColors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
      icon: Icons.smart_toy_rounded,
    ),
    PuzzleSection(
      id: 4,
      title: 'Expert',
      subtitle: 'Cute Animals',
      description: 'Playful puppies, cozy kittens, pandas, and forest celebrations.',
      startLevel: 31,
      endLevel: 40,
      gradientColors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
      icon: Icons.pets_rounded,
    ),
    PuzzleSection(
      id: 5,
      title: 'Master',
      subtitle: 'Grand Puzzles',
      description: 'Intricate master challenges featuring the most vibrant scenes.',
      startLevel: 41,
      endLevel: 50,
      gradientColors: [Color(0xFFB71C1C), Color(0xFFC62828)],
      icon: Icons.military_tech_rounded,
    ),
  ];

  static PuzzleSection getSectionById(int id) {
    return sections.firstWhere((s) => s.id == id, orElse: () => sections.first);
  }

  List<PuzzleLevel> getLevels() {
    return PuzzleLevel.getAllLevels().where((l) => l.sectionId == id).toList();
  }
}
