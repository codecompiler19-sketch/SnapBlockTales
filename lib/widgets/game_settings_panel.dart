import 'package:flutter/material.dart';
import '../screens/coins_shop_screen.dart';
import '../services/audio_manager.dart';
import '../services/progress_service.dart';

class GameSettingsPanel extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback? onSkipLevel;
  final VoidCallback? onRestartLevel;
  final VoidCallback? onHome;
  final bool isInGame;

  const GameSettingsPanel({
    super.key,
    this.onClose,
    this.onSkipLevel,
    this.onRestartLevel,
    this.onHome,
    this.isInGame = false,
  });

  void _showInfoDialog(BuildContext context, String title, String message, bool isDark) {
    AudioManager.instance.playTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF222632) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFFFD700) : const Color(0xFFFF9800),
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFaqDialog(BuildContext context, bool isDark) {
    AudioManager.instance.playTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF222632) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.quiz_rounded, color: isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706), size: 22),
            const SizedBox(width: 8),
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Q: How does puzzle swapping work?',
                style: TextStyle(color: isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'A: Tap two pieces to swap them, or drag a piece directly into any slot. Matching neighbors seamlessly merge together!',
                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4B5563), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                'Q: How do hints work?',
                style: TextStyle(color: isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'A: Tap "Hint" to highlight a piece\'s true slot, or "Auto" to place a piece into position instantly.',
                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4B5563), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                'Q: Does the game work offline?',
                style: TextStyle(color: isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'A: Yes! All 50 levels and custom photo puzzles are 100% playable offline.',
                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4B5563), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFFFD700) : const Color(0xFFFF9800),
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSkipReasonDialog(BuildContext context, VoidCallback onConfirmSkip, bool isDark) {
    AudioManager.instance.playTap();
    int selectedReasonIndex = 0;
    final reasons = [
      'Level is too difficult / challenging',
      'Technical issue or glitch encountered',
      'Just want to try the next puzzle',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF222632) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Row(
                children: [
                  const Icon(Icons.skip_next_rounded, color: Color(0xFFFF8E00), size: 26),
                  const SizedBox(width: 8),
                  Text(
                    'Skip Level',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please tell us why you are skipping this puzzle:',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(reasons.length, (index) {
                    final isSelected = selectedReasonIndex == index;
                    return InkWell(
                      onTap: () {
                        AudioManager.instance.playTap();
                        setDialogState(() {
                          selectedReasonIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0x22FFD700) : const Color(0x15FF9800))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: const Color(0xFFFF9800).withOpacity(0.5))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: selectedReasonIndex,
                              activeColor: const Color(0xFFFF8E00),
                              onChanged: (val) {
                                if (val != null) {
                                  AudioManager.instance.playTap();
                                  setDialogState(() {
                                    selectedReasonIndex = val;
                                  });
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                reasons[index],
                                style: TextStyle(
                                  color: isDark
                                      ? (isSelected ? Colors.white : Colors.white70)
                                      : (isSelected ? const Color(0xFF111827) : const Color(0xFF4B5563)),
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    AudioManager.instance.playTap();
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    AudioManager.instance.playTap();
                    Navigator.pop(ctx); // Close dialog
                    onConfirmSkip();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8E00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm & Skip', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final progress = ProgressService.instance.progress;
        final isDark = progress.darkMode;

        final bgColor = isDark ? const Color(0xFF191B22) : const Color(0xFFF1F3F7);
        final cardColor = isDark ? const Color(0xFF242831) : Colors.white;
        final titleColor = isDark ? const Color(0xFFF2ECE1) : const Color(0xFF1F2937);
        final textPrimaryColor = isDark ? const Color(0xFFF0EBE1) : const Color(0xFF1F2937);
        final iconColor = isDark ? Colors.white70 : const Color(0xFF4B5563);
        final dividerColor = isDark ? Colors.white12 : const Color(0xFFE5E7EB);
        final borderSideColor = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);

        return Container(
          width: 330,
          color: bgColor,
          child: SafeArea(
            child: Column(
              children: [
                // Header (Matching Screenshot 2: > Settings)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                          size: 22,
                        ),
                        onPressed: onClose ?? () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Setting Cards
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: [
                      // CARD 1: Audio & Theme Toggles (Sounds, Music, Vibrations, Dark Mode, Congrats)
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderSideColor),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            // Sounds
                            _buildToggleTile(
                              icon: Icons.volume_up_rounded,
                              title: 'Sounds',
                              value: progress.soundEnabled,
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onChanged: (val) {
                                AudioManager.instance.playTap();
                                ProgressService.instance.updateGameSettings(soundEnabled: val);
                              },
                            ),
                            _buildDivider(dividerColor),

                            // Music
                            _buildToggleTile(
                              icon: Icons.music_note_rounded,
                              title: 'Music',
                              value: progress.musicEnabled,
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onChanged: (val) {
                                AudioManager.instance.playTap();
                                ProgressService.instance.updateGameSettings(musicEnabled: val);
                              },
                            ),
                            _buildDivider(dividerColor),

                            // Vibrations
                            _buildToggleTile(
                              icon: Icons.vibration_rounded,
                              title: 'Vibrations',
                              value: progress.hapticEnabled,
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onChanged: (val) {
                                AudioManager.instance.playTap();
                                ProgressService.instance.updateGameSettings(vibrationsEnabled: val);
                              },
                            ),
                            _buildDivider(dividerColor),

                            // Dark Mode
                            _buildToggleTile(
                              icon: Icons.nightlight_round,
                              title: 'Dark Mode',
                              value: progress.darkMode,
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onChanged: (val) {
                                AudioManager.instance.playTap();
                                ProgressService.instance.updateGameSettings(darkMode: val);
                              },
                            ),
                            _buildDivider(dividerColor),

                            // Congrats Pop-up
                            _buildToggleTile(
                              icon: Icons.celebration_rounded,
                              title: 'Congrats Pop-up',
                              value: progress.congratsPopup,
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onChanged: (val) {
                                AudioManager.instance.playTap();
                                ProgressService.instance.updateGameSettings(congratsPopup: val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CARD 2: Store, Policy & Support (Matching Screenshot 2)
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderSideColor),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            // Coins Shop
                            _buildActionTile(
                              icon: Icons.monetization_on_rounded,
                              title: 'Coins Shop',
                              iconColor: const Color(0xFFFFD700),
                              textColor: textPrimaryColor,
                              onTap: () {
                                AudioManager.instance.playTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CoinsShopScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(dividerColor),

                            // Restore Purchase
                            _buildActionTile(
                              icon: Icons.restore_rounded,
                              title: 'Restore Purchase',
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onTap: () {
                                AudioManager.instance.playTap();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Purchases restored successfully!'),
                                    backgroundColor: Color(0xFF10B981),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(dividerColor),

                            // Remove Ads
                            _buildActionTile(
                              icon: Icons.block_rounded,
                              title: 'Remove Ads',
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onTap: () {
                                AudioManager.instance.playTap();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ad-Free Mode is Active! Enjoy uninterrupted play.'),
                                    backgroundColor: Color(0xFF3B82F6),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(dividerColor),

                            // Privacy Policy
                            _buildActionTile(
                              icon: Icons.shield_outlined,
                              title: 'Privacy Policy',
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onTap: () => _showInfoDialog(
                                context,
                                'Privacy Policy',
                                'Your privacy is our priority.\n\n'
                                '• No personal information is gathered or shared.\n'
                                '• Game saves, progress, and records remain entirely on your device.\n'
                                '• Zero third-party trackers.\n'
                                '• Completely safe and secure.',
                                isDark,
                              ),
                            ),
                            _buildDivider(dividerColor),

                            // FAQ
                            _buildActionTile(
                              icon: Icons.help_outline_rounded,
                              title: 'FAQ',
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onTap: () => _showFaqDialog(context, isDark),
                            ),
                            _buildDivider(dividerColor),

                            // Help & Support
                            _buildActionTile(
                              icon: Icons.mail_outline_rounded,
                              title: 'Help & Support',
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onTap: () => _showInfoDialog(
                                context,
                                'Help & Support',
                                'Need assistance or have feedback?\n\n'
                                'Contact our support team at:\nsupport@pictureblocksgame.com\n\n'
                                'Version: Picture Blocks v1.0.0\n'
                                'Thank you for playing!',
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CARD 3: Level Navigation & Controls (Skip Level with Reason, Restart, Home)
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderSideColor),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            if (onHome != null) ...[
                              _buildActionTile(
                                icon: Icons.home_rounded,
                                title: 'Back to Home',
                                iconColor: iconColor,
                                textColor: textPrimaryColor,
                                onTap: onHome!,
                              ),
                              _buildDivider(dividerColor),
                            ],

                            // Skip Level (Opens Reason Dialog with 3 options)
                            _buildActionTile(
                              icon: Icons.skip_next_rounded,
                              title: 'Skip Level',
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onTap: isInGame && onSkipLevel != null
                                  ? () => _showSkipReasonDialog(context, onSkipLevel!, isDark)
                                  : () {
                                      AudioManager.instance.playTap();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Skip is available during active puzzle gameplay.'),
                                        ),
                                      );
                                    },
                            ),
                            _buildDivider(dividerColor),

                            // Restart Level
                            _buildActionTile(
                              icon: Icons.refresh_rounded,
                              title: 'Restart Level',
                              iconColor: iconColor,
                              textColor: textPrimaryColor,
                              onTap: isInGame && onRestartLevel != null
                                  ? onRestartLevel!
                                  : () {
                                      AudioManager.instance.playTap();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Restart is available during active puzzle gameplay.'),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer version (Matching Screenshot 3)
                      Center(
                        child: Text(
                          'Picture Blocks · v1.0.0',
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required Color iconColor,
    required Color textColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF2196F3),
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.black38,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(
      color: color,
      height: 1,
      thickness: 0.8,
      indent: 14,
      endIndent: 14,
    );
  }
}
