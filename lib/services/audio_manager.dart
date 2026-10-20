import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._internal();
  AudioManager._internal();

  AudioPlayer? _bgmPlayer;
  AudioPlayer? _sfxPlayer;

  double _bgmVolume = 0.8;
  double _sfxVolume = 1.0;
  bool _isMuted = false;
  bool _hapticEnabled = true;
  bool _isInitialized = false;

  Future<void> init({
    double bgmVolume = 0.8,
    double sfxVolume = 1.0,
    bool isMuted = false,
    bool hapticEnabled = true,
  }) async {
    _bgmVolume = bgmVolume;
    _sfxVolume = sfxVolume;
    _isMuted = isMuted;
    _hapticEnabled = hapticEnabled;

    try {
      _bgmPlayer = AudioPlayer();
      _sfxPlayer = AudioPlayer();

      await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer?.setVolume(_isMuted ? 0.0 : _bgmVolume);
      await _sfxPlayer?.setVolume(_isMuted ? 0.0 : _sfxVolume);
      _isInitialized = true;
    } catch (e) {
      // Graceful fallback if platform audio has issues
      _isInitialized = false;
    }
  }

  void updateSettings({
    double? bgmVolume,
    double? sfxVolume,
    bool? isMuted,
    bool? hapticEnabled,
  }) {
    if (bgmVolume != null) _bgmVolume = bgmVolume;
    if (sfxVolume != null) _sfxVolume = sfxVolume;
    if (isMuted != null) _isMuted = isMuted;
    if (hapticEnabled != null) _hapticEnabled = hapticEnabled;

    if (_isInitialized) {
      _bgmPlayer?.setVolume(_isMuted ? 0.0 : _bgmVolume);
      _sfxPlayer?.setVolume(_isMuted ? 0.0 : _sfxVolume);
    }
  }

  Future<void> startBgm() async {
    if (!_isInitialized || _isMuted) return;
    try {
      await _bgmPlayer?.play(AssetSource('audio/bgm_loop.wav'));
    } catch (_) {}
  }

  Future<void> pauseBgm() async {
    if (!_isInitialized) return;
    try {
      await _bgmPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!_isInitialized || _isMuted) return;
    try {
      await _bgmPlayer?.resume();
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    if (!_isInitialized) return;
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  Future<void> playTap() async {
    triggerHaptic(HapticFeedbackType.light);
    _playSfx('audio/tap.wav');
  }

  Future<void> playPickup() async {
    triggerHaptic(HapticFeedbackType.selection);
    _playSfx('audio/pickup.wav');
  }

  Future<void> playDrop() async {
    triggerHaptic(HapticFeedbackType.selection);
    _playSfx('audio/drop.wav');
  }

  Future<void> playSnap() async {
    triggerHaptic(HapticFeedbackType.medium);
    _playSfx('audio/snap.wav');
  }

  Future<void> playHint() async {
    triggerHaptic(HapticFeedbackType.selection);
    _playSfx('audio/hint.wav');
  }

  Future<void> playStar() async {
    triggerHaptic(HapticFeedbackType.light);
    _playSfx('audio/star.wav');
  }

  Future<void> playLevelStart() async {
    _playSfx('audio/level_start.wav');
  }

  Future<void> playVictory() async {
    triggerHaptic(HapticFeedbackType.heavy);
    _playSfx('audio/victory.wav');
  }

  void triggerHaptic(HapticFeedbackType type) {
    if (!_hapticEnabled) return;
    try {
      switch (type) {
        case HapticFeedbackType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.selection:
          HapticFeedback.selectionClick();
          break;
      }
    } catch (_) {}
  }

  Future<void> _playSfx(String assetPath) async {
    if (!_isInitialized || _isMuted || _sfxVolume <= 0.01) return;
    try {
      // Reuse sfx player or play asset source
      await _sfxPlayer?.stop();
      await _sfxPlayer?.setVolume(_sfxVolume);
      await _sfxPlayer?.play(AssetSource(assetPath));
    } catch (_) {}
  }

  void dispose() {
    _bgmPlayer?.dispose();
    _sfxPlayer?.dispose();
  }
}

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}
