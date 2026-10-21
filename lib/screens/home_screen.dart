import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../models/puzzle_level.dart';
import '../services/audio_manager.dart';
import '../services/progress_service.dart';
import '../widgets/floating_pieces_background.dart';
import 'achievements_screen.dart';
import 'coins_shop_screen.dart';
import 'daily_challenge_screen.dart';
import 'photo_puzzle_screen.dart';
import 'puzzle_game_screen.dart';
import 'section_selection_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Start ambient background music
    AudioManager.instance.startBgm();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _playNextLevel() {
    AudioManager.instance.playTap();
    final progress = ProgressService.instance.progress;
    final currentLevel =
        PuzzleLevel.getLevelById(progress.highestUnlockedLevel);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzleGameScreen(
          level: currentLevel,
          gameMode: GameMode.classic,
        ),
      ),
    );
  }

  void _resumeSavedGame() {
    AudioManager.instance.playTap();
    final progress = ProgressService.instance.progress;
    final saved = progress.activeSavedGame;
    if (saved == null) return;

    final level = PuzzleLevel.getLevelById(saved.levelId);
    final mode = GameMode.values.firstWhere(
      (m) => m.name == saved.gameMode,
      orElse: () => GameMode.classic,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzleGameScreen(
          level: level,
          gameMode: mode,
          resumeState: saved,
          customPhotoPath: saved.customImagePath,
        ),
      ),
    );
  }

  void _showModeSelectionSheet() {
    AudioManager.instance.playTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1E30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final progress = ProgressService.instance.progress;
        final currentLevel =
            PuzzleLevel.getLevelById(progress.highestUnlockedLevel);

        final modes = [
          (GameMode.classic, Icons.map, const Color(0xFF3B82F6)),
          (GameMode.relax, Icons.spa, const Color(0xFF10B981)),
          (GameMode.timed, Icons.timer, const Color(0xFFF59E0B)),
          (GameMode.mystery, Icons.psychology, const Color(0xFF8B5CF6)),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Select Game Mode',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ...modes.map((item) {
                  final mode = item.$1;
                  final icon = item.$2;
                  final color = item.$3;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () {
                        AudioManager.instance.playTap();
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PuzzleGameScreen(
                              level: currentLevel,
                              gameMode: mode,
                            ),
                          ),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      title: Text(
                        mode.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        mode.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white38,
                        size: 16,
                      ),
                      tileColor: Colors.white.withOpacity(0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingPiecesBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: ProgressService.instance,
            builder: (context, _) {
              final progress = ProgressService.instance.progress;
              final hasActiveGame = progress.activeSavedGame != null;

              return Column(
                children: [
                  // Top Status Header: Coins & Stars & Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Coin Balance (Tappable -> Opens Coins Shop)
                        InkWell(
                          onTap: () {
                            AudioManager.instance.playTap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoinsShopScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(19),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/3d/panel_header_currency.png'),
                                fit: BoxFit.fill,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/3d/icon_coin_gold_3d.png',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${progress.coins}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFE082),
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFF78350F),
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFD700),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 10,
                                    color: Color(0xFF78350F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Stars Count
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amberAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/3d/icon_star_gold_3d.png',
                                width: 22,
                                height: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${progress.totalStars}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right action buttons: 3D Shop & 3D Settings
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                AudioManager.instance.playTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CoinsShopScreen(),
                                  ),
                                );
                              },
                              child: Tooltip(
                                message: 'Coins Shop',
                                child: Image.asset(
                                  'assets/images/3d/btn_shop_3d.png',
                                  width: 36,
                                  height: 36,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                AudioManager.instance.playTap();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                              child: Tooltip(
                                message: 'Settings',
                                child: Image.asset(
                                  'assets/images/3d/btn_menu_settings_3d.png',
                                  width: 36,
                                  height: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Center Artwork & Title
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 3D Logo / Badge
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_pulseController.value * 0.03),
                                  child: Container(
                                    width: 170,
                                    height: 170,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1)
                                              .withOpacity(0.4),
                                          blurRadius: 36,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(85),
                                      child: Image.asset(
                                        'assets/images/logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // 3D Game Title Logo
                            Image.asset(
                              'assets/images/3d/title_logo_3d.png',
                              width: 280,
                              height: 80,
                              fit: BoxFit.contain,
                              semanticLabel: 'SnapBlockTales',
                            ),
                            const SizedBox(height: 24),

                            // Large Primary 3D PLAY Button (clean button without text overwrite)
                            GestureDetector(
                              onTap: _playNextLevel,
                              child: Container(
                                width: 220,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(36),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/3d/btn_play_3d.png',
                                  width: 220,
                                  height: 72,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Game level shown clearly below the play button in middle of screen
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFFD700).withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                'LEVEL ${progress.highestUnlockedLevel}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Continue Saved Game Button (if exists)
                            if (hasActiveGame)
                              SizedBox(
                                width: 240,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _resumeSavedGame,
                                  icon: const Icon(
                                    Icons.replay_rounded,
                                    color: Color(0xFF81C784),
                                    size: 20,
                                  ),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Continue Level ${progress.activeSavedGame!.levelId}',
                                      style: const TextStyle(
                                        color: Color(0xFF81C784),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF81C784),
                                      width: 1.8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    backgroundColor:
                                        const Color(0xFF2E7D32).withOpacity(0.18),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Game Mode Selector Button
                            TextButton.icon(
                              onPressed: _showModeSelectionSheet,
                              icon: const Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: Color(0xFF64B5F6),
                              ),
                              label: const Text(
                                'Change Game Mode',
                                style: TextStyle(
                                  color: Color(0xFF64B5F6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Grid of Quick Feature Buttons
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Section Selection
                        _buildNavButton(
                          title: 'Sections',
                          icon: Icons.grid_view_rounded,
                          color: const Color(0xFF3B82F6),
                          image3d: 'assets/images/3d/btn_sections_3d.png',
                          onTap: () {
                            AudioManager.instance.playTap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SectionSelectionScreen(),
                              ),
                            );
                          },
                        ),

                        // My Photo Puzzle
                        _buildNavButton(
                          title: 'My Photo',
                          icon: Icons.add_photo_alternate_rounded,
                          color: const Color(0xFFEC4899),
                          image3d: 'assets/images/3d/btn_custom_photo_3d.png',
                          onTap: () {
                            AudioManager.instance.playTap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PhotoPuzzleScreen(),
                              ),
                            );
                          },
                        ),

                        // Daily Challenge
                        _buildNavButton(
                          title: 'Daily Puzzle',
                          icon: Icons.calendar_month_rounded,
                          color: const Color(0xFFF59E0B),
                          image3d: 'assets/images/3d/btn_daily_challenge_3d.png',
                          onTap: () {
                            AudioManager.instance.playTap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DailyChallengeScreen(),
                              ),
                            );
                          },
                        ),

                        // Achievements
                        _buildNavButton(
                          title: 'Rewards',
                          icon: Icons.emoji_events_rounded,
                          color: const Color(0xFF10B981),
                          image3d: 'assets/images/3d/btn_achievements_3d.png',
                          onTap: () {
                            AudioManager.instance.playTap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AchievementsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required String title,
    required IconData icon,
    required Color color,
    String? image3d,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image3d != null)
              Image.asset(
                image3d,
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              )
            else
              Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
