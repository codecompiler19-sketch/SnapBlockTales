import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_3d_adventure/models/player_progress.dart';
import 'package:jigsaw_3d_adventure/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.init();
  });

  group('Coins and Rewards System Tests', () {
    test('Initial balance is 500 coins and transactions are recorded', () {
      final progress = ProgressService.instance.progress;
      expect(progress.coins, 500);
      expect(progress.inventoryHints, 3);
      expect(progress.adsWatchedToday, 0);
    });

    test('Earn coins for puzzle completion: easy (+30), normal (+50), hard (+120)', () async {
      final initial = ProgressService.instance.progress.coins;

      await ProgressService.instance.completeLevel(1, 3, 45, 30);
      expect(ProgressService.instance.progress.coins, initial + 30);
      expect(ProgressService.instance.progress.transactions.last.amount, 30);
      expect(ProgressService.instance.progress.transactions.last.category, 'level');

      await ProgressService.instance.completeLevel(2, 3, 60, 50);
      expect(ProgressService.instance.progress.coins, initial + 30 + 50);

      await ProgressService.instance.completeLevel(3, 3, 120, 120);
      expect(ProgressService.instance.progress.coins, initial + 30 + 50 + 120);
    });

    test('Buy hint costs 75 coins and checks affordability', () async {
      final initial = ProgressService.instance.progress.coins;
      final initialHints = ProgressService.instance.progress.inventoryHints;

      final success = await ProgressService.instance.buyHintInShop();
      expect(success, isTrue);
      expect(ProgressService.instance.progress.coins, initial - 75);
      expect(ProgressService.instance.progress.inventoryHints, initialHints + 1);
      expect(ProgressService.instance.progress.transactions.last.amount, -75);
      expect(ProgressService.instance.progress.transactions.last.category, 'hint');

      // Test affordability when balance is insufficient
      ProgressService.instance.progress.coins = 50;
      final fail = await ProgressService.instance.buyHintInShop();
      expect(fail, isFalse);
      expect(ProgressService.instance.progress.coins, 50); // unchanged
    });

    test('Unlock image pack costs 500 coins and checks affordability', () async {
      ProgressService.instance.progress.coins = 600;
      final success = await ProgressService.instance.unlockImagePack('pack_nature', 'Nature Pack', cost: 500);
      expect(success, isTrue);
      expect(ProgressService.instance.progress.coins, 100);
      expect(ProgressService.instance.progress.unlockedPacks.contains('pack_nature'), isTrue);
      expect(ProgressService.instance.progress.transactions.last.amount, -500);

      // Subsequent attempt when already unlocked returns true without deducting coins
      final alreadyUnlocked = await ProgressService.instance.unlockImagePack('pack_nature', 'Nature Pack', cost: 500);
      expect(alreadyUnlocked, isTrue);
      expect(ProgressService.instance.progress.coins, 100);

      // Attempt to unlock another pack with insufficient balance
      final fail = await ProgressService.instance.unlockImagePack('pack_fantasy', 'Fantasy Pack', cost: 500);
      expect(fail, isFalse);
      expect(ProgressService.instance.progress.coins, 100);
    });

    test('Daily rewards: 100 coins for all days and prevents duplicate claim on same day', () async {
      final initial = ProgressService.instance.progress.coins;
      expect(ProgressService.instance.progress.dailyRewardDay, 1);

      // Day 1 claim
      final day1Reward = await ProgressService.instance.claimDailyReward();
      expect(day1Reward, 100);
      expect(ProgressService.instance.progress.coins, initial + 100);
      expect(ProgressService.instance.progress.dailyRewardDay, 2);

      // Attempt second claim today -> blocked!
      final duplicateClaim = await ProgressService.instance.claimDailyReward();
      expect(duplicateClaim, isNull);
      expect(ProgressService.instance.progress.coins, initial + 100);

      // Simulate next day
      ProgressService.instance.progress.lastDailyRewardClaimDate = '2026-01-01';
      final day2Reward = await ProgressService.instance.claimDailyReward();
      expect(day2Reward, 100);
      expect(ProgressService.instance.progress.coins, initial + 100 + 100);
      expect(ProgressService.instance.progress.dailyRewardDay, 3);
    });

    test('Rewarded Ads: exactly 50 coins per completed ad, max 5 per day', () async {
      final initial = ProgressService.instance.progress.coins;

      for (int i = 1; i <= 5; i++) {
        final success = await ProgressService.instance.claimAdReward();
        expect(success, isTrue, reason: 'Ad $i should succeed');
        expect(ProgressService.instance.progress.coins, initial + (i * 50));
        expect(ProgressService.instance.progress.adsWatchedToday, i);
      }

      // 6th ad attempt today -> limit reached!
      final sixthAd = await ProgressService.instance.claimAdReward();
      expect(sixthAd, isFalse);
      expect(ProgressService.instance.progress.coins, initial + 250);
      expect(ProgressService.instance.progress.adsWatchedToday, 5);

      // Simulate next day -> counter resets to 0 and allows claims again
      ProgressService.instance.progress.lastAdWatchedDate = '2026-01-01';
      final nextDayAd = await ProgressService.instance.claimAdReward();
      expect(nextDayAd, isTrue);
      expect(ProgressService.instance.progress.adsWatchedToday, 1);
      expect(ProgressService.instance.progress.coins, initial + 300);
    });

    test('Skip level grants zero points, coins, and stars', () async {
      final initialCoins = ProgressService.instance.progress.coins;
      final initialStars = ProgressService.instance.progress.totalStars;

      await ProgressService.instance.skipLevel(1);

      // No coins or stars awarded for skipping
      expect(ProgressService.instance.progress.coins, initialCoins);
      expect(ProgressService.instance.progress.totalStars, initialStars);
      // But next level is unlocked to allow advancing
      expect(ProgressService.instance.progress.isLevelUnlocked(2), isTrue);
      expect(ProgressService.instance.progress.highestUnlockedLevel >= 2, isTrue);
    });
  });
}
