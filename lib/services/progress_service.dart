import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin_transaction.dart';
import '../models/player_progress.dart';
import 'audio_manager.dart';

class ProgressService extends ChangeNotifier {
  static final ProgressService instance = ProgressService._internal();
  ProgressService._internal();

  static const String _storageKey = 'jigsaw_player_progress_v1';
  PlayerProgress _progress = PlayerProgress();
  bool _isLoaded = false;

  PlayerProgress get progress => _progress;
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _progress = PlayerProgress.deserialize(raw);
      } else {
        _progress = PlayerProgress();
        await _save();
      }
    } catch (e) {
      _progress = PlayerProgress();
    }
    _isLoaded = true;

    // Synchronize Audio Manager with loaded progress
    AudioManager.instance.updateSettings(
      bgmVolume: _progress.bgmVolume,
      sfxVolume: _progress.sfxVolume,
      isMuted: _progress.isMuted,
      hapticEnabled: _progress.hapticEnabled,
      soundEnabled: _progress.soundEnabled,
      musicEnabled: _progress.musicEnabled,
    );

    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _progress.serialize());
    } catch (_) {}
  }

  void _recordTx(String title, int amount, String category) {
    final tx = CoinTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_progress.transactions.length}',
      title: title,
      amount: amount,
      timestamp: DateTime.now(),
      category: category,
    );
    _progress.transactions.insert(0, tx);
    if (_progress.transactions.length > 100) {
      _progress.transactions.removeLast();
    }
  }

  Future<void> addCoins(int amount, {String reason = 'Coins Earned', String category = 'general'}) async {
    _progress.coins += amount;
    _recordTx(reason, amount, category);
    notifyListeners();
    await _save();
  }

  Future<bool> spendCoins(int amount, {String reason = 'Coins Spent', String category = 'general'}) async {
    if (_progress.coins < amount) return false;
    _progress.coins -= amount;
    _recordTx(reason, -amount, category);
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> completeLevel(int levelId, int stars, int timeSeconds, int earnedCoins) async {
    _progress.coins += earnedCoins;
    _recordTx('Level $levelId Completed (+$earnedCoins coins)', earnedCoins, 'level');
    _progress.completeLevel(levelId, stars, timeSeconds);
    notifyListeners();
    await _save();
  }

  /// Claims today's daily reward (100 coins for all days)
  Future<int?> claimDailyReward() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_progress.lastDailyRewardClaimDate == today) {
      return null; // Already claimed today
    }

    const coinReward = 100; // 100 coins for all days

    _progress.coins += coinReward;
    _recordTx('Day ${_progress.dailyRewardDay} Daily Reward (+$coinReward coins)', coinReward, 'daily');

    _progress.lastDailyRewardClaimDate = today;
    _progress.dailyRewardDay = (_progress.dailyRewardDay % 7) + 1;

    notifyListeners();
    await _save();
    return coinReward;
  }

  /// Uses 1 stored hint from inventory
  Future<bool> useInventoryHint() async {
    if (_progress.inventoryHints <= 0) return false;
    _progress.inventoryHints--;
    notifyListeners();
    await _save();
    return true;
  }

  /// Claims rewarded ad reward (+50 coins, max 5 per day)
  Future<bool> claimAdReward() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_progress.lastAdWatchedDate != today) {
      _progress.adsWatchedToday = 0;
      _progress.lastAdWatchedDate = today;
    }

    if (_progress.adsWatchedToday >= 5) {
      return false; // Limit reached
    }

    _progress.adsWatchedToday += 1;
    _progress.coins += 50;
    _recordTx('Watched Rewarded Ad (+50 coins)', 50, 'ad');

    notifyListeners();
    await _save();
    return true;
  }

  /// Buys 1 Puzzle Hint for 75 coins
  Future<bool> buyHintInShop() async {
    const hintCost = 75;
    if (_progress.coins < hintCost) return false;

    _progress.coins -= hintCost;
    _progress.inventoryHints += 1;
    _recordTx('Bought Puzzle Hint (-$hintCost coins)', -hintCost, 'hint');

    notifyListeners();
    await _save();
    return true;
  }

  /// Unlocks an Image Pack for 500 coins
  Future<bool> unlockImagePack(String packId, String packName, {int cost = 500}) async {
    if (_progress.unlockedPacks.contains(packId)) return true;
    if (_progress.coins < cost) return false;

    _progress.coins -= cost;
    _progress.unlockedPacks.add(packId);
    _recordTx('Unlocked $packName (-$cost coins)', -cost, 'pack');

    notifyListeners();
    await _save();
    return true;
  }

  /// Unlocks a cosmetic theme/frame
  Future<bool> unlockCosmetic(String cosmeticId, String name, int cost) async {
    if (_progress.unlockedCosmetics.contains(cosmeticId)) return true;
    if (_progress.coins < cost) return false;

    _progress.coins -= cost;
    _progress.unlockedCosmetics.add(cosmeticId);
    _recordTx('Unlocked $name (-$cost coins)', -cost, 'cosmetic');

    notifyListeners();
    await _save();
    return true;
  }

  Future<void> skipLevel(int levelId) async {
    _progress.skipLevel(levelId);
    notifyListeners();
    await _save();
  }

  Future<void> saveGameSession(SavedGameState state) async {
    _progress.activeSavedGame = state;
    notifyListeners();
    await _save();
  }

  Future<void> clearSavedSession() async {
    _progress.activeSavedGame = null;
    notifyListeners();
    await _save();
  }

  Future<void> updateAudioSettings({
    double? bgmVolume,
    double? sfxVolume,
    bool? isMuted,
    bool? hapticEnabled,
    bool? soundEnabled,
    bool? musicEnabled,
  }) async {
    if (bgmVolume != null) _progress.bgmVolume = bgmVolume;
    if (sfxVolume != null) _progress.sfxVolume = sfxVolume;
    if (isMuted != null) _progress.isMuted = isMuted;
    if (hapticEnabled != null) _progress.hapticEnabled = hapticEnabled;
    if (soundEnabled != null) _progress.soundEnabled = soundEnabled;
    if (musicEnabled != null) _progress.musicEnabled = musicEnabled;

    AudioManager.instance.updateSettings(
      bgmVolume: _progress.bgmVolume,
      sfxVolume: _progress.sfxVolume,
      isMuted: _progress.isMuted,
      hapticEnabled: _progress.hapticEnabled,
      soundEnabled: _progress.soundEnabled,
      musicEnabled: _progress.musicEnabled,
    );

    notifyListeners();
    await _save();
  }

  Future<void> updateGameSettings({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationsEnabled,
    bool? darkMode,
    bool? colorBlindMode,
    bool? congratsPopup,
    bool? notificationsEnabled,
  }) async {
    if (soundEnabled != null) _progress.soundEnabled = soundEnabled;
    if (musicEnabled != null) _progress.musicEnabled = musicEnabled;
    if (vibrationsEnabled != null) _progress.hapticEnabled = vibrationsEnabled;
    if (darkMode != null) _progress.darkMode = darkMode;
    if (colorBlindMode != null) _progress.colorBlindMode = colorBlindMode;
    if (congratsPopup != null) _progress.congratsPopup = congratsPopup;
    if (notificationsEnabled != null) _progress.notificationsEnabled = notificationsEnabled;

    AudioManager.instance.updateSettings(
      soundEnabled: _progress.soundEnabled,
      musicEnabled: _progress.musicEnabled,
      hapticEnabled: _progress.hapticEnabled,
    );

    notifyListeners();
    await _save();
  }

  Future<void> updatePreferences({
    bool? leftHanded,
    bool? reducedMotion,
  }) async {
    if (leftHanded != null) _progress.leftHanded = leftHanded;
    if (reducedMotion != null) _progress.reducedMotion = reducedMotion;
    notifyListeners();
    await _save();
  }

  Future<bool> claimAchievement(String id, int rewardCoins) async {
    if (_progress.claimedAchievementIds.contains(id)) return false;
    _progress.claimedAchievementIds.add(id);
    _progress.coins += rewardCoins;
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> recordDailyCompletion(String todayDate) async {
    if (_progress.lastDailyDate == null) {
      _progress.dailyStreak = 1;
    } else {
      // Check if previous day
      try {
        final last = DateTime.parse(_progress.lastDailyDate!);
        final now = DateTime.parse(todayDate);
        final diff = now.difference(last).inDays;
        if (diff == 1) {
          _progress.dailyStreak += 1;
        } else if (diff > 1) {
          _progress.dailyStreak = 1;
        }
      } catch (_) {
        _progress.dailyStreak = 1;
      }
    }
    _progress.lastDailyDate = todayDate;
    _progress.coins += 100 + (_progress.dailyStreak * 20);
    notifyListeners();
    await _save();
  }

  Future<void> resetAllProgress() async {
    _progress = PlayerProgress();
    notifyListeners();
    await _save();
  }
}
