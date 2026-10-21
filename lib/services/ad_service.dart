import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'progress_service.dart';

enum AdState { ready, loading, unavailable }

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Official Google AdMob Test IDs
  static const String androidRewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosRewardedTestId =
      'ca-app-pub-3940256099942544/1712485313';

  AdState _state = AdState.ready;
  AdState get state => _state;

  String get rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosRewardedTestId;
    }
    return androidRewardedTestId;
  }

  /// Whether the user can watch an ad today (< 5 per calendar day)
  bool get canWatchAdToday {
    final progress = ProgressService.instance.progress;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (progress.lastAdWatchedDate != today) {
      return true; // New day, limit reset to 0
    }
    return progress.adsWatchedToday < 5;
  }

  int get adsWatchedToday {
    final progress = ProgressService.instance.progress;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (progress.lastAdWatchedDate != today) {
      return 0;
    }
    return progress.adsWatchedToday;
  }

  /// Shows the Rewarded Ad modal
  Future<bool> showRewardedAd(
    BuildContext context, {
    required VoidCallback onRewardEarned,
    VoidCallback? onAdClosedEarly,
    VoidCallback? onAdUnavailable,
  }) async {
    if (!canWatchAdToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily rewarded ad limit reached (5/5). Come back tomorrow!'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    _state = AdState.loading;

    // Show interactive Google AdMob Rewarded Test Video Player Modal
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _GoogleAdMobRewardedTestDialog(
        unitId: rewardedAdUnitId,
      ),
    );

    _state = AdState.ready;

    if (result == true) {
      onRewardEarned();
      return true;
    } else {
      onAdClosedEarly?.call();
      return false;
    }
  }
}

class _GoogleAdMobRewardedTestDialog extends StatefulWidget {
  final String unitId;

  const _GoogleAdMobRewardedTestDialog({
    required this.unitId,
  });

  @override
  State<_GoogleAdMobRewardedTestDialog> createState() =>
      _GoogleAdMobRewardedTestDialogState();
}

class _GoogleAdMobRewardedTestDialogState
    extends State<_GoogleAdMobRewardedTestDialog> {
  int _secondsLeft = 5;
  Timer? _timer;
  bool _rewardUnlocked = false;
  bool _rewardClaimed = false; // Prevents duplicate reward callbacks

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _rewardUnlocked = true;
        });
        AudioManager.instance.playSnap();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleEarlyClose() {
    AudioManager.instance.playTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Leave Early?', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'If you close this ad early, you will NOT earn your +50 Coins reward.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Resume Ad', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close confirmation
              Navigator.pop(context, false); // Dismiss ad with no reward
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _claimRewardAndClose() {
    if (_rewardClaimed) return; // Strict duplicate protection
    _rewardClaimed = true;
    AudioManager.instance.playVictory();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F111D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _rewardUnlocked
                    ? const Color(0xFF10B981)
                    : const Color(0xFF3B82F6).withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top AdMob Banner Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: const Color(0xFF1B1F33),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Ad',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Google AdMob Test Rewarded Ad',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Unit: ${widget.unitId}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Close / Skip Button (3D)
                        IconButton(
                          icon: Image.asset(
                            'assets/images/3d/btn_close_3d.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                          onPressed: _rewardUnlocked
                              ? _claimRewardAndClose
                              : _handleEarlyClose,
                        ),
                      ],
                    ),
                  ),

                  // Ad Content / Video Simulation
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Video screen preview container
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _rewardUnlocked
                                  ? [
                                      const Color(0xFF065F46),
                                      const Color(0xFF047857),
                                    ]
                                  : [
                                      const Color(0xFF1E293B),
                                      const Color(0xFF0F172A),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!_rewardUnlocked) ...[
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.play_circle_fill_rounded,
                                      size: 54,
                                      color: Color(0xFF38BDF8),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Reward in $_secondsLeft s',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Watch the full test video to earn +50 coins',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                // Bottom Progress Line
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: LinearProgressIndicator(
                                    value: (5 - _secondsLeft) / 5.0,
                                    backgroundColor: Colors.white10,
                                    valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFF38BDF8)),
                                    minHeight: 4,
                                  ),
                                ),
                              ] else ...[
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Reward Granted!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '+50 Gold Coins Ready',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Reward summary & status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/3d/icon_coin_gold_3d.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '+50 Coins',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _rewardUnlocked
                              ? 'Tap Claim below to add +50 coins to your balance.'
                              : 'Do not close until the countdown finishes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _rewardUnlocked
                                ? const Color(0xFF34D399)
                                : Colors.white60,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _rewardUnlocked
                                  ? const Color(0xFF10B981)
                                  : Colors.white.withOpacity(0.12),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: _rewardUnlocked ? 4 : 0,
                            ),
                            onPressed: _rewardUnlocked
                                ? _claimRewardAndClose
                                : _handleEarlyClose,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _rewardUnlocked
                                      ? Icons.card_giftcard_rounded
                                      : Icons.cancel_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _rewardUnlocked
                                      ? 'Claim +50 Coins'
                                      : 'Cancel & Skip',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
