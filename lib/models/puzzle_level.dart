class PuzzleLevel {
  final int id;
  final int sectionId;
  final String title;
  final String category;
  final String imagePath;
  final int rows;
  final int cols;
  final int targetTimeSeconds;
  final int coinReward;
  final bool isCustom;

  const PuzzleLevel({
    required this.id,
    required this.sectionId,
    required this.title,
    required this.category,
    required this.imagePath,
    required this.rows,
    required this.cols,
    required this.targetTimeSeconds,
    required this.coinReward,
    this.isCustom = false,
  });

  int get pieceCount => rows * cols;
  String get dimensionLabel => '${rows}x$cols';

  static List<PuzzleLevel> getAllLevels() {
    return List.generate(50, (index) {
      final id = index + 1;
      final sectionId = ((id - 1) ~/ 10) + 1;
      final subLevel = ((id - 1) % 10) + 1;

      int rows;
      int cols;
      int targetTime;
      int reward = 50 + (sectionId * 25) + (subLevel * 5);

      if (sectionId == 1) {
        // Section 1: Beginner (Exact spec levels 1-10)
        switch (subLevel) {
          case 1:
            rows = 3;
            cols = 3;
            targetTime = 90;
            break;
          case 2:
            rows = 3;
            cols = 3;
            targetTime = 90;
            break;
          case 3:
            rows = 3;
            cols = 4;
            targetTime = 120;
            break;
          case 4:
            rows = 4;
            cols = 4;
            targetTime = 150;
            break;
          case 5:
            rows = 4;
            cols = 4;
            targetTime = 150;
            break;
          case 6:
            rows = 4;
            cols = 5;
            targetTime = 180;
            break;
          case 7:
            rows = 5;
            cols = 5;
            targetTime = 220;
            break;
          case 8:
            rows = 5;
            cols = 6;
            targetTime = 260;
            break;
          case 9:
            rows = 6;
            cols = 6;
            targetTime = 300;
            break;
          case 10:
          default:
            rows = 6;
            cols = 7;
            targetTime = 360;
            break;
        }
      } else if (sectionId == 2) {
        // Section 2: Explorer (Levels 11-20)
        if (subLevel <= 3) {
          rows = 4;
          cols = 4;
          targetTime = 160;
        } else if (subLevel <= 6) {
          rows = 4;
          cols = 5;
          targetTime = 200;
        } else if (subLevel <= 8) {
          rows = 5;
          cols = 5;
          targetTime = 250;
        } else {
          rows = 5;
          cols = 6;
          targetTime = 300;
        }
      } else if (sectionId == 3) {
        // Section 3: Adventure (Levels 21-30)
        if (subLevel <= 3) {
          rows = 5;
          cols = 5;
          targetTime = 240;
        } else if (subLevel <= 6) {
          rows = 5;
          cols = 6;
          targetTime = 280;
        } else if (subLevel <= 8) {
          rows = 6;
          cols = 6;
          targetTime = 340;
        } else {
          rows = 6;
          cols = 7;
          targetTime = 400;
        }
      } else if (sectionId == 4) {
        // Section 4: Expert (Levels 31-40)
        if (subLevel <= 3) {
          rows = 6;
          cols = 6;
          targetTime = 330;
        } else if (subLevel <= 6) {
          rows = 6;
          cols = 7;
          targetTime = 390;
        } else if (subLevel <= 8) {
          rows = 7;
          cols = 7;
          targetTime = 450;
        } else {
          rows = 7;
          cols = 8;
          targetTime = 520;
        }
      } else {
        // Section 5: Master (Levels 41-50)
        if (subLevel <= 3) {
          rows = 6;
          cols = 7;
          targetTime = 380;
        } else if (subLevel <= 6) {
          rows = 7;
          cols = 7;
          targetTime = 440;
        } else if (subLevel <= 8) {
          rows = 7;
          cols = 8;
          targetTime = 520;
        } else {
          rows = 8;
          cols = 8;
          targetTime = 600;
        }
      }

      final titles = [
        // S1
        'Sunset Haven', 'Emerald Woods', 'Lavender Meadow', 'Alpine Peak', 'Autumn Cascade',
        'Bamboo Zen', 'Cherry Blossom', 'Tropical Lagoon', 'Golden Canyon', 'Starry Summit',
        // S2
        'Savanna Horizon', 'Coral Reef', 'Rainforest Canopy', 'Desert Mirage', 'Deep Trench',
        'Zebra Crossing', 'Bioluminescent Cove', 'Cheetah Prowl', 'Mangrove Sanctuary', 'Orca Bay',
        // S3
        'Floating Citadel', 'Dragon Spine Peak', 'Crystal Caverns', 'Enchanted Glen', 'Obsidian Spire',
        'Celestial Keep', 'Whispering Forest', 'Moonlit Bridge', 'Phoenix Nest', 'Starlight Palace',
        // S4
        'Orion Nebula', 'Andromeda Spiral', 'Solar Flare', 'Cosmic Gateway', 'Supernova Cloud',
        'Ringed Giant', 'Interstellar Void', 'Pulsar Beam', 'Quantum Realm', 'Event Horizon',
        // S5
        'Sun God Temple', 'Gilded Pyramid', 'Mayan Observatory', 'Lost Atlantis', 'Taj Reverie',
        'Colosseum Dawn', 'Angkor Wonder', 'Petra Rose Canyon', 'Stonehenge Solstice', 'Great Citadel of Kings',
      ];

      final categories = [
        'Nature', 'Nature', 'Nature', 'Nature', 'Nature',
        'Nature', 'Nature', 'Nature', 'Nature', 'Nature',
        'Wildlife', 'Ocean', 'Wildlife', 'Desert', 'Ocean',
        'Wildlife', 'Ocean', 'Wildlife', 'Nature', 'Ocean',
        'Fantasy', 'Fantasy', 'Fantasy', 'Fantasy', 'Fantasy',
        'Fantasy', 'Fantasy', 'Fantasy', 'Fantasy', 'Fantasy',
        'Cosmic', 'Cosmic', 'Cosmic', 'Cosmic', 'Cosmic',
        'Cosmic', 'Cosmic', 'Cosmic', 'Cosmic', 'Cosmic',
        'Ancient', 'Ancient', 'Ancient', 'Ancient', 'Ancient',
        'Ancient', 'Ancient', 'Ancient', 'Ancient', 'Ancient',
      ];

      return PuzzleLevel(
        id: id,
        sectionId: sectionId,
        title: titles[index],
        category: categories[index],
        imagePath: 'assets/images/levels/level_$id.png',
        rows: rows,
        cols: cols,
        targetTimeSeconds: targetTime,
        coinReward: reward,
      );
    });
  }

  static PuzzleLevel getLevelById(int id) {
    final all = getAllLevels();
    return all.firstWhere(
      (l) => l.id == id,
      orElse: () => all.first,
    );
  }
}
