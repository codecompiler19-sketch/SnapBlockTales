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
        // Section 1: Beginner (Levels 1-10) - All Square Grids
        if (subLevel <= 5) {
          rows = 3;
          cols = 3; // 3x3 = 9 pieces (Square)
          targetTime = 90;
        } else {
          rows = 4;
          cols = 4; // 4x4 = 16 pieces (Square)
          targetTime = 150;
        }
      } else if (sectionId == 2) {
        // Section 2: Explorer (Levels 11-20) - All Square Grids
        if (subLevel <= 5) {
          rows = 4;
          cols = 4; // 4x4 = 16 pieces (Square)
          targetTime = 160;
        } else {
          rows = 5;
          cols = 5; // 5x5 = 25 pieces (Square)
          targetTime = 240;
        }
      } else if (sectionId == 3) {
        // Section 3: Adventure (Levels 21-30) - All Square Grids
        if (subLevel <= 5) {
          rows = 5;
          cols = 5; // 5x5 = 25 pieces (Square)
          targetTime = 240;
        } else {
          rows = 6;
          cols = 6; // 6x6 = 36 pieces (Square)
          targetTime = 320;
        }
      } else if (sectionId == 4) {
        // Section 4: Expert (Levels 31-40) - All Square Grids
        if (subLevel <= 5) {
          rows = 6;
          cols = 6; // 6x6 = 36 pieces (Square)
          targetTime = 320;
        } else {
          rows = 7;
          cols = 7; // 7x7 = 49 pieces (Square)
          targetTime = 420;
        }
      } else {
        // Section 5: Master (Levels 41-50) - All Square Grids
        if (subLevel <= 5) {
          rows = 7;
          cols = 7; // 7x7 = 49 pieces (Square)
          targetTime = 420;
        } else {
          rows = 8;
          cols = 8; // 8x8 = 64 pieces (Square)
          targetTime = 550;
        }
      }

      final titles = [
        // S1: Art & Crafts (Levels 1-10)
        'Little Artists Studio', 'Colorful Birdhouse', 'Garden Flowers', 'Rainbow Art Room', 'Pottery with Grandma',
        'Sculptor Workshop', 'Colorful Clay Pots', 'Giant Finger Painting', 'Art Exhibition', 'Paper Butterflies',
        // S2: Vehicles & Travel (Levels 11-20)
        'Little Red Fire Truck', 'Adventures on Toy Train', 'Busy Construction Site', 'Friendly School Bus', 'Hot Air Balloon',
        'Airport Adventure', 'Little Farm Tractor', 'City Traffic Scene', 'Sailing at Harbor', 'Space Rocket Launch',
        // S3: Toyland Fun (Levels 21-30)
        'Teddy Bear Picnic', 'Giant Block Tower', 'Toy Shop Adventure', 'Dollhouse Family', 'Toy Car Race',
        'Magical Toy Workshop', 'Block Castle', 'Stuffed Animal Parade', 'Robot Birthday Party', 'Playground Adventure',
        // S4: Cute Animals (Levels 31-40)
        'Farmer & Baby Lambs', 'Puppies in Garden', 'Kittens Butterfly Chase', 'Feeding Ducks at Pond', 'Baby Elephant Bath',
        'Panda Bamboo Picnic', 'Squirrel Acorn Collection', 'Day at Petting Zoo', 'Penguin Snowy Walk', 'Forest Animals Party',
        // S5: Grand Puzzles (Levels 41-50)
        'Grand Balloon Flight', 'Cosmic Rocket Master', 'Toy Workshop Master', 'Robot Galaxy Party', 'Playground Wonderland',
        'Puppy Garden Dream', 'Elephant Oasis', 'Panda Harmony', 'Penguin Ice Kingdom', 'Forest Grand Celebration',
      ];

      final categories = [
        // S1
        'Art', 'Art', 'Art', 'Art', 'Crafts',
        'Crafts', 'Crafts', 'Art', 'Art', 'Crafts',
        // S2
        'Vehicles', 'Vehicles', 'Vehicles', 'Vehicles', 'Travel',
        'Travel', 'Vehicles', 'City', 'Travel', 'Space',
        // S3
        'Toyland', 'Toyland', 'Toyland', 'Toyland', 'Toyland',
        'Toyland', 'Toyland', 'Toyland', 'Toyland', 'Toyland',
        // S4
        'Animals', 'Animals', 'Animals', 'Animals', 'Animals',
        'Animals', 'Animals', 'Animals', 'Animals', 'Animals',
        // S5
        'Master', 'Master', 'Master', 'Master', 'Master',
        'Master', 'Master', 'Master', 'Master', 'Master',
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
