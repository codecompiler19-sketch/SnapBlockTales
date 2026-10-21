import 'dart:convert';
import 'coin_transaction.dart';

class SavedGameState {
  final int levelId;
  final String gameMode;
  final int elapsedSeconds;
  final List<int> placedPieceIds;
  final String? customImagePath;
  final int rows;
  final int cols;

  SavedGameState({
    required this.levelId,
    required this.gameMode,
    required this.elapsedSeconds,
    required this.placedPieceIds,
    this.customImagePath,
    required this.rows,
    required this.cols,
  });

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'gameMode': gameMode,
        'elapsedSeconds': elapsedSeconds,
        'placedPieceIds': placedPieceIds,
        'customImagePath': customImagePath,
        'rows': rows,
        'cols': cols,
      };

  factory SavedGameState.fromJson(Map<String, dynamic> json) => SavedGameState(
        levelId: json['levelId'] as int? ?? 1,
        gameMode: json['gameMode'] as String? ?? 'classic',
        elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
        placedPieceIds: (json['placedPieceIds'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        customImagePath: json['customImagePath'] as String?,
        rows: json['rows'] as int? ?? 3,
        cols: json['cols'] as int? ?? 3,
      );
}

class PlayerProgress {
  int coins;
  int highestUnlockedLevel;
  int highestUnlockedSection;
  Map<int, int> levelStars; // levelId -> stars (1..3)
  Map<int, int> levelBestTimes; // levelId -> seconds
  double bgmVolume;
  double sfxVolume;
  bool isMuted;
  bool hapticEnabled;
  bool leftHanded;
  bool reducedMotion;
  bool soundEnabled;
  bool musicEnabled;
  bool darkMode;
  bool colorBlindMode;
  bool congratsPopup;
  bool notificationsEnabled;
  SavedGameState? activeSavedGame;
  String? lastDailyDate;
  int dailyStreak;
  List<String> claimedAchievementIds;

  // Coins & Economy
  List<CoinTransaction> transactions;
  int inventoryHints;
  List<String> unlockedPacks;
  List<String> unlockedCosmetics;
  int dailyRewardDay;
  String? lastDailyRewardClaimDate;
  int adsWatchedToday;
  String? lastAdWatchedDate;

  PlayerProgress({
    this.coins = 500, // Starter bonus: 500 Coins
    this.highestUnlockedLevel = 1,
    this.highestUnlockedSection = 1,
    Map<int, int>? levelStars,
    Map<int, int>? levelBestTimes,
    this.bgmVolume = 0.8,
    this.sfxVolume = 1.0,
    this.isMuted = false,
    this.hapticEnabled = true,
    this.leftHanded = false,
    this.reducedMotion = false,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.darkMode = true,
    this.colorBlindMode = false,
    this.congratsPopup = true,
    this.notificationsEnabled = true,
    this.activeSavedGame,
    this.lastDailyDate,
    this.dailyStreak = 0,
    List<String>? claimedAchievementIds,
    List<CoinTransaction>? transactions,
    this.inventoryHints = 3,
    List<String>? unlockedPacks,
    List<String>? unlockedCosmetics,
    this.dailyRewardDay = 1,
    this.lastDailyRewardClaimDate,
    this.adsWatchedToday = 0,
    this.lastAdWatchedDate,
  })  : levelStars = levelStars ?? {},
        levelBestTimes = levelBestTimes ?? {},
        claimedAchievementIds = claimedAchievementIds ?? [],
        transactions = transactions ?? [],
        unlockedPacks = unlockedPacks ?? ['classic_starter'],
        unlockedCosmetics = unlockedCosmetics ?? ['default_frame'];

  bool get canClaimDailyRewardToday {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastDailyRewardClaimDate != today;
  }

  int get effectiveAdsWatchedToday {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastAdWatchedDate != today) {
      return 0;
    }
    return adsWatchedToday;
  }

  int get totalStars =>
      levelStars.values.fold(0, (sum, stars) => sum + stars);

  int get completedLevelsCount => levelStars.length;

  bool isLevelUnlocked(int levelId) => levelId <= highestUnlockedLevel;
  bool isSectionUnlocked(int sectionId) => sectionId <= highestUnlockedSection;

  int getStarsForLevel(int levelId) => levelStars[levelId] ?? 0;
  int? getBestTimeForLevel(int levelId) => levelBestTimes[levelId];

  void skipLevel(int levelId) {
    // Unlock next level without awarding stars or completion coins
    if (levelId == highestUnlockedLevel && levelId < 50) {
      highestUnlockedLevel = levelId + 1;
    }
    // Clear active saved game
    if (activeSavedGame?.levelId == levelId) {
      activeSavedGame = null;
    }
  }

  void completeLevel(int levelId, int stars, int timeSeconds) {
    // Record stars (keep best)
    final existingStars = levelStars[levelId] ?? 0;
    if (stars > existingStars) {
      levelStars[levelId] = stars;
    }
    // Record best time (keep fastest)
    final existingTime = levelBestTimes[levelId];
    if (existingTime == null || timeSeconds < existingTime) {
      levelBestTimes[levelId] = timeSeconds;
    }

    // Unlock next level
    if (levelId == highestUnlockedLevel && levelId < 50) {
      highestUnlockedLevel = levelId + 1;
    }

    // Check section unlock: 10 levels per section
    final completedInSection =
        levelStars.keys.where((id) => id >= (highestUnlockedSection - 1) * 10 + 1 && id <= highestUnlockedSection * 10).length;
    if (completedInSection >= 10 && highestUnlockedSection < 5) {
      highestUnlockedSection += 1;
    }

    // Clear active saved game if it was this level
    if (activeSavedGame?.levelId == levelId) {
      activeSavedGame = null;
    }
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'highestUnlockedLevel': highestUnlockedLevel,
        'highestUnlockedSection': highestUnlockedSection,
        'levelStars': levelStars.map((k, v) => MapEntry(k.toString(), v)),
        'levelBestTimes':
            levelBestTimes.map((k, v) => MapEntry(k.toString(), v)),
        'bgmVolume': bgmVolume,
        'sfxVolume': sfxVolume,
        'isMuted': isMuted,
        'hapticEnabled': hapticEnabled,
        'leftHanded': leftHanded,
        'reducedMotion': reducedMotion,
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
        'darkMode': darkMode,
        'colorBlindMode': colorBlindMode,
        'congratsPopup': congratsPopup,
        'notificationsEnabled': notificationsEnabled,
        'activeSavedGame': activeSavedGame?.toJson(),
        'lastDailyDate': lastDailyDate,
        'dailyStreak': dailyStreak,
        'claimedAchievementIds': claimedAchievementIds,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'inventoryHints': inventoryHints,
        'unlockedPacks': unlockedPacks,
        'unlockedCosmetics': unlockedCosmetics,
        'dailyRewardDay': dailyRewardDay,
        'lastDailyRewardClaimDate': lastDailyRewardClaimDate,
        'adsWatchedToday': effectiveAdsWatchedToday,
        'lastAdWatchedDate': lastAdWatchedDate,
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    final rawStars = json['levelStars'] as Map<String, dynamic>? ?? {};
    final stars = rawStars.map((k, v) => MapEntry(int.parse(k), v as int));

    final rawTimes = json['levelBestTimes'] as Map<String, dynamic>? ?? {};
    final times = rawTimes.map((k, v) => MapEntry(int.parse(k), v as int));

    final rawTx = json['transactions'] as List<dynamic>? ?? [];
    final txList = rawTx
        .map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
        .toList();

    return PlayerProgress(
      coins: json['coins'] as int? ?? 1250,
      highestUnlockedLevel: json['highestUnlockedLevel'] as int? ?? 1,
      highestUnlockedSection: json['highestUnlockedSection'] as int? ?? 1,
      levelStars: stars,
      levelBestTimes: times,
      bgmVolume: (json['bgmVolume'] as num?)?.toDouble() ?? 0.8,
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      leftHanded: json['leftHanded'] as bool? ?? false,
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      musicEnabled: json['musicEnabled'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? true,
      colorBlindMode: json['colorBlindMode'] as bool? ?? false,
      congratsPopup: json['congratsPopup'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      activeSavedGame: json['activeSavedGame'] != null
          ? SavedGameState.fromJson(
              json['activeSavedGame'] as Map<String, dynamic>)
          : null,
      lastDailyDate: json['lastDailyDate'] as String?,
      dailyStreak: json['dailyStreak'] as int? ?? 0,
      claimedAchievementIds:
          (json['claimedAchievementIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      transactions: txList,
      inventoryHints: json['inventoryHints'] as int? ?? 3,
      unlockedPacks: (json['unlockedPacks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['classic_starter'],
      unlockedCosmetics: (json['unlockedCosmetics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['default_frame'],
      dailyRewardDay: json['dailyRewardDay'] as int? ?? 1,
      lastDailyRewardClaimDate: json['lastDailyRewardClaimDate'] as String?,
      adsWatchedToday: json['adsWatchedToday'] as int? ?? 0,
      lastAdWatchedDate: json['lastAdWatchedDate'] as String?,
    );
  }

  String serialize() => jsonEncode(toJson());

  factory PlayerProgress.deserialize(String raw) {
    try {
      return PlayerProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerProgress();
    }
  }
}
