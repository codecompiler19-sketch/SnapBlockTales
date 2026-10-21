import 'package:flutter/material.dart';
import '../models/coin_transaction.dart';
import '../models/player_progress.dart';
import '../services/ad_service.dart';
import '../services/audio_manager.dart';
import '../services/progress_service.dart';
import 'section_selection_screen.dart';

class CoinsShopScreen extends StatefulWidget {
  const CoinsShopScreen({super.key});

  @override
  State<CoinsShopScreen> createState() => _CoinsShopScreenState();
}

class _CoinsShopScreenState extends State<CoinsShopScreen> {
  bool _isWatchingAd = false;

  final List<int> _dailyRewards = [100, 100, 100, 100, 100, 100, 100];

  void _claimDailyReward() async {
    AudioManager.instance.playTap();
    final reward = await ProgressService.instance.claimDailyReward();
    if (!mounted) return;

    if (reward != null) {
      AudioManager.instance.playVictory();
      _showSuccessSnackBar('🎉 Claimed +$reward Coins Daily Reward!');
    } else {
      _showInfoSnackBar('You have already claimed your daily reward today. Check back tomorrow!');
    }
  }

  void _watchAdAndEarn() async {
    AudioManager.instance.playTap();
    if (!AdService.instance.canWatchAdToday) {
      _showInfoSnackBar('Daily ad limit reached (5/5). Come back tomorrow!');
      return;
    }

    setState(() {
      _isWatchingAd = true;
    });

    final success = await AdService.instance.showRewardedAd(
      context,
      onRewardEarned: () async {
        await ProgressService.instance.claimAdReward();
        if (mounted) {
          _showSuccessSnackBar('🎉 Reward Received! +50 Gold Coins added.');
        }
      },
      onAdClosedEarly: () {
        if (mounted) {
          _showInfoSnackBar('Ad skipped early. No coins awarded.');
        }
      },
    );

    if (mounted) {
      setState(() {
        _isWatchingAd = false;
      });
    }
  }

  void _buyHint() async {
    AudioManager.instance.playTap();
    const cost = 75;
    final progress = ProgressService.instance.progress;

    if (progress.coins < cost) {
      _showAffordabilityDialog(
        title: 'Not Enough Coins',
        content: 'A puzzle hint costs $cost coins. Watch a quick ad or complete puzzles to earn more!',
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Buy Puzzle Hint',
      message: 'Spend $cost coins to purchase 1 puzzle hint?',
      confirmText: 'Buy for $cost Coins',
      confirmColor: const Color(0xFFF59E0B),
    );

    if (confirmed == true) {
      final success = await ProgressService.instance.buyHintInShop();
      if (!mounted) return;
      if (success) {
        AudioManager.instance.playSnap();
        _showSuccessSnackBar('Purchased 1 Puzzle Hint! You now have ${ProgressService.instance.progress.inventoryHints} hints.');
      }
    }
  }

  void _unlockPack(String packId, String packName, int cost) async {
    AudioManager.instance.playTap();
    final progress = ProgressService.instance.progress;

    if (progress.unlockedPacks.contains(packId)) {
      _showInfoSnackBar('$packName is already unlocked!');
      return;
    }

    if (progress.coins < cost) {
      _showAffordabilityDialog(
        title: 'Not Enough Coins',
        content: '$packName costs $cost coins. You currently have ${progress.coins} coins.',
      );
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Unlock $packName',
      message: 'Unlock the complete $packName image collection for $cost coins?',
      confirmText: 'Unlock for $cost Coins',
      confirmColor: const Color(0xFF10B981),
    );

    if (confirmed == true) {
      final success = await ProgressService.instance.unlockImagePack(packId, packName, cost: cost);
      if (!mounted) return;
      if (success) {
        AudioManager.instance.playVictory();
        _showSuccessSnackBar('🎉 Unlocked $packName! Enjoy the new puzzles.');
      }
    }
  }

  void _showTransactionHistory() {
    AudioManager.instance.playTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151828),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final transactions = ProgressService.instance.progress.transactions;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Modal Handle & Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_rounded, color: Color(0xFFFFD700), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Transaction History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),

                Expanded(
                  child: transactions.isEmpty
                      ? const Center(
                          child: Text(
                            'No transactions recorded yet.',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isCredit = tx.isCredit;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isCredit
                                          ? const Color(0xFF10B981).withOpacity(0.15)
                                          : const Color(0xFFEF4444).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCredit ? Icons.add_rounded : Icons.remove_rounded,
                                      color: isCredit
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tx.formattedDate,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isCredit ? '+' : ''}${tx.amount}',
                                    style: TextStyle(
                                      color: isCredit
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.monetization_on,
                                    size: 14,
                                    color: Color(0xFFFFD700),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showAffordabilityDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final progress = ProgressService.instance.progress;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final dailyClaimedToday = progress.lastDailyRewardClaimDate == today;
        final adsWatched = AdService.instance.adsWatchedToday;
        final adsMaxReached = adsWatched >= 5;

        return Scaffold(
          backgroundColor: const Color(0xFF0F111E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F111E),
            elevation: 0,
            leading: IconButton(
              icon: Image.asset(
                'assets/images/3d/btn_back_3d.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
              onPressed: () {
                AudioManager.instance.playTap();
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'Coins Shop',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white70),
                tooltip: 'Transaction History',
                onPressed: _showTransactionHistory,
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // 1. YOUR BALANCE CARD
                  _buildBalanceCard(progress),

                  const SizedBox(height: 24),

                  // 2. DAILY REWARDS SECTION
                  _buildDailyRewardsSection(progress, dailyClaimedToday),

                  const SizedBox(height: 24),

                  // 3. WATCH ADS & EARN COINS
                  _buildRewardedAdCard(adsWatched, adsMaxReached),

                  const SizedBox(height: 24),

                  // 4. EARN MORE COINS SECTION
                  _buildEarnMoreSection(),

                  const SizedBox(height: 24),

                  // 5. SPEND YOUR COINS SECTION
                  _buildSpendCoinsSection(progress),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(PlayerProgress progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E2310),
            Color(0xFF1B192A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'YOUR BALANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/3d/icon_coin_stack_3d.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                '${progress.coins}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.receipt_long_rounded, size: 16),
            label: const Text('View History', style: TextStyle(fontSize: 12)),
            onPressed: _showTransactionHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRewardsSection(PlayerProgress progress, bool dailyClaimedToday) {
    final currentDay = progress.dailyRewardDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Rewards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final amount = _dailyRewards[index];
              final isCurrent = dayNum == currentDay;
              final isPast = dayNum < currentDay;

              return Container(
                margin: const EdgeInsets.only(right: 10),
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFFF59E0B).withOpacity(0.2)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.08),
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$amount',
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFFFFD700) : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Image.asset(
                      isPast
                          ? 'assets/images/3d/gift_box_open_3d.png'
                          : 'assets/images/3d/gift_box_closed_3d.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'DAY $dayNum',
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFFFFD700) : Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dailyClaimedToday
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: dailyClaimedToday ? 0 : 3,
            ),
            onPressed: dailyClaimedToday ? null : _claimDailyReward,
            child: Text(
              dailyClaimedToday ? 'CLAIMED TODAY' : 'CLAIM DAILY REWARD',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
                color: dailyClaimedToday ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardedAdCard(int adsWatched, bool adsMaxReached) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1D2840),
            const Color(0xFF151829),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/3d/btn_watch_ad_3d.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Watch Ads & Earn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '+50 Coins per ad',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Daily counter pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: adsMaxReached
                      ? const Color(0xFFEF4444).withOpacity(0.2)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: adsMaxReached
                        ? const Color(0xFFEF4444)
                        : Colors.white24,
                  ),
                ),
                child: Text(
                  adsMaxReached ? '5/5 (Limit)' : '$adsWatched/5 Today',
                  style: TextStyle(
                    color: adsMaxReached ? const Color(0xFFF87171) : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Watch a short video ad to earn instant coins. Complete the video to receive your reward.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: adsMaxReached
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: adsMaxReached || _isWatchingAd ? null : _watchAdAndEarn,
              child: _isWatchingAd
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          adsMaxReached ? Icons.block_rounded : Icons.ondemand_video_rounded,
                          size: 18,
                          color: adsMaxReached ? Colors.white38 : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          adsMaxReached
                              ? 'Daily Limit Reached'
                              : 'Watch Ad & Earn (+50 Coins)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: adsMaxReached ? Colors.white38 : Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnMoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earn More Coins',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Item 1: Complete a puzzle
        _buildEarnTile(
          icon: Icons.extension_rounded,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Complete a puzzle',
          subtitle: 'Earn 30–120 coins',
          actionText: 'Play',
          onTap: () {
            AudioManager.instance.playTap();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SectionSelectionScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        // Item 2: Daily bonus
        _buildEarnTile(
          icon: Icons.card_giftcard_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Daily bonus',
          subtitle: 'Free coins every day',
          actionText: 'Check',
          onTap: () {
            _claimDailyReward();
          },
        ),
      ],
    );
  }

  Widget _buildEarnTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF38BDF8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            onPressed: onTap,
            child: Text(actionText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendCoinsSection(PlayerProgress progress) {
    final hasNaturePack = progress.unlockedPacks.contains('pack_nature');
    final hasFantasyPack = progress.unlockedPacks.contains('pack_fantasy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spend Your Coins',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Puzzle Hint
        _buildSpendCard(
          icon: Icons.lightbulb_rounded,
          image3d: 'assets/images/3d/btn_hint_3d.png',
          iconColor: const Color(0xFFF59E0B),
          title: 'Puzzle Hint',
          cost: 75,
          subtitle: 'Reveals and places a piece automatically. Inventory: ${progress.inventoryHints}',
          buttonLabel: 'BUY HINT',
          isUnlocked: false,
          onTap: _buyHint,
        ),

        const SizedBox(height: 12),

        // 2. Nature Image Pack
        _buildSpendCard(
          icon: Icons.landscape_rounded,
          image3d: 'assets/images/3d/pack_nature_cover.png',
          iconColor: const Color(0xFF10B981),
          title: 'Nature Pack (10 Images)',
          cost: 500,
          subtitle: 'Unlock breathtaking nature & wildlife jigsaw puzzles.',
          buttonLabel: hasNaturePack ? 'UNLOCKED' : 'UNLOCK',
          isUnlocked: hasNaturePack,
          onTap: () => _unlockPack('pack_nature', 'Nature Pack', 500),
        ),

        const SizedBox(height: 12),

        // 3. Fantasy Art Pack
        _buildSpendCard(
          icon: Icons.auto_awesome_rounded,
          image3d: 'assets/images/3d/pack_fantasy_cover.png',
          iconColor: const Color(0xFFA855F7),
          title: 'Fantasy Pack (10 Images)',
          cost: 500,
          subtitle: 'Mythical castles, dragons, and magical landscapes.',
          buttonLabel: hasFantasyPack ? 'UNLOCKED' : 'UNLOCK',
          isUnlocked: hasFantasyPack,
          onTap: () => _unlockPack('pack_fantasy', 'Fantasy Pack', 500),
        ),
      ],
    );
  }

  Widget _buildSpendCard({
    required IconData icon,
    String? image3d,
    required Color iconColor,
    required String title,
    required int cost,
    required String subtitle,
    required String buttonLabel,
    required bool isUnlocked,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFF10B981).withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: image3d != null
                ? Image.asset(image3d, width: 34, height: 34, fit: BoxFit.contain)
                : Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/3d/icon_coin_gold_3d.png',
                      width: 14,
                      height: 14,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$cost coins',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isUnlocked
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : const Color(0xFFF59E0B),
              foregroundColor: isUnlocked ? const Color(0xFF10B981) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: isUnlocked ? null : onTap,
            child: Text(
              buttonLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
