import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    );

    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _progress.serialize());
    } catch (_) {}
  }

  Future<void> addCoins(int amount) async {
    _progress.coins += amount;
    notifyListeners();
    await _save();
  }

  Future<bool> spendCoins(int amount) async {
    if (_progress.coins < amount) return false;
    _progress.coins -= amount;
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> completeLevel(int levelId, int stars, int timeSeconds, int earnedCoins) async {
    _progress.coins += earnedCoins;
    _progress.completeLevel(levelId, stars, timeSeconds);
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
  }) async {
    if (bgmVolume != null) _progress.bgmVolume = bgmVolume;
    if (sfxVolume != null) _progress.sfxVolume = sfxVolume;
    if (isMuted != null) _progress.isMuted = isMuted;
    if (hapticEnabled != null) _progress.hapticEnabled = hapticEnabled;

    AudioManager.instance.updateSettings(
      bgmVolume: _progress.bgmVolume,
      sfxVolume: _progress.sfxVolume,
      isMuted: _progress.isMuted,
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
