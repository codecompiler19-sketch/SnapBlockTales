enum GameMode {
  classic, // Standard progressive adventure
  relax,   // Untimed, free unlimited hints
  timed,   // Countdown timer with speed bonus
  mystery, // Mystery image silhouette until pieces placed
  photo,   // User photo puzzle
  daily,   // Featured daily puzzle
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.classic:
        return 'Adventure';
      case GameMode.relax:
        return 'Relax Mode';
      case GameMode.timed:
        return 'Timed Challenge';
      case GameMode.mystery:
        return 'Mystery Image';
      case GameMode.photo:
        return 'My Photo';
      case GameMode.daily:
        return 'Daily Puzzle';
    }
  }

  String get description {
    switch (this) {
      case GameMode.classic:
        return 'Progressive 3D jigsaw puzzle adventure';
      case GameMode.relax:
        return 'No timer, no penalties, pure zen relaxation';
      case GameMode.timed:
        return 'Beat the countdown timer for mega coin bonuses!';
      case GameMode.mystery:
        return 'Image details hidden until pieces are placed!';
      case GameMode.photo:
        return 'Play with custom photos from your gallery';
      case GameMode.daily:
        return 'Exclusive daily puzzle with streak rewards';
    }
  }
}
