import 'package:flutter/material.dart';
import '../services/audio_manager.dart';
import '../services/progress_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showTutorialDialog(BuildContext context) {
    AudioManager.instance.playTap();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text('How to Play', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Drag & Drop Pieces',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              Text(
                'Touch and hold any puzzle piece from the bottom tray to lift it with realistic 3D depth, then drag it toward its slot on the board.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '2. Magnetic Snapping',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              Text(
                'When you bring a piece close to its exact location, it magnetically snaps into place with haptic vibration and audio feedback.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '3. Hints & Guides',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              Text(
                'Tap the Eye icon for a faint ghost watermark guide. Use the "Hint" button to highlight the slot for a piece, or "Auto" to place it instantly.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '4. Progression & Rewards',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              Text(
                'Earn up to 3 stars per level by completing quickly. Completing 10 levels in a section unlocks the next exciting section!',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Got It!'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    AudioManager.instance.playTap();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset All Progress?',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will erase all unlocked levels, earned stars, coins, and records. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ProgressService.instance.resetAllProgress();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All progress has been reset.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            AudioManager.instance.playTap();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ProgressService.instance,
          builder: (context, _) {
            final progress = ProgressService.instance.progress;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // SECTION: AUDIO
                _buildSectionHeader('AUDIO & HAPTICS'),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D2C),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      // Master Mute
                      SwitchListTile(
                        title: const Text(
                          'Mute All Sounds',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        secondary: Icon(
                          progress.isMuted
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: const Color(0xFFFFD700),
                        ),
                        activeColor: const Color(0xFFFFD700),
                        value: progress.isMuted,
                        onChanged: (val) {
                          AudioManager.instance.playTap();
                          ProgressService.instance.updateAudioSettings(isMuted: val);
                        },
                      ),
                      const Divider(color: Colors.white12, height: 1),

                      // BGM Volume Slider
                      ListTile(
                        leading: const Icon(Icons.music_note, color: Colors.white70),
                        title: const Text(
                          'Music Volume',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Slider(
                          value: progress.bgmVolume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFF3B82F6),
                          inactiveColor: Colors.white12,
                          onChanged: progress.isMuted
                              ? null
                              : (val) {
                                  ProgressService.instance.updateAudioSettings(bgmVolume: val);
                                },
                        ),
                        trailing: Text(
                          '${(progress.bgmVolume * 100).round()}%',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),

                      // SFX Volume Slider
                      ListTile(
                        leading: const Icon(Icons.touch_app, color: Colors.white70),
                        title: const Text(
                          'Sound Effects Volume',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Slider(
                          value: progress.sfxVolume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFF10B981),
                          inactiveColor: Colors.white12,
                          onChanged: progress.isMuted
                              ? null
                              : (val) {
                                  ProgressService.instance.updateAudioSettings(sfxVolume: val);
                                },
                        ),
                        trailing: Text(
                          '${(progress.sfxVolume * 100).round()}%',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),

                      // Haptic Feedback
                      SwitchListTile(
                        title: const Text(
                          'Vibration & Haptics',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Tactile clicks on piece pickup & snapping',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        secondary: const Icon(Icons.vibration, color: Colors.white70),
                        activeColor: const Color(0xFFFFD700),
                        value: progress.hapticEnabled,
                        onChanged: (val) {
                          AudioManager.instance.playTap();
                          ProgressService.instance.updateAudioSettings(hapticEnabled: val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION: ACCESSIBILITY & CONTROLS
                _buildSectionHeader('GAMEPLAY & ACCESSIBILITY'),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D2C),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      // Left-Handed Mode
                      SwitchListTile(
                        title: const Text(
                          'Left-Handed Layout',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Adjusts tray controls for easy left-thumb access',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        secondary: const Icon(Icons.pan_tool, color: Colors.white70),
                        activeColor: const Color(0xFFFFD700),
                        value: progress.leftHanded,
                        onChanged: (val) {
                          AudioManager.instance.playTap();
                          ProgressService.instance.updatePreferences(leftHanded: val);
                        },
                      ),
                      const Divider(color: Colors.white12, height: 1),

                      // Reduced Motion
                      SwitchListTile(
                        title: const Text(
                          'Reduced Motion',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Minimizes background animations and particle effects',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        secondary: const Icon(Icons.motion_photos_off, color: Colors.white70),
                        activeColor: const Color(0xFFFFD700),
                        value: progress.reducedMotion,
                        onChanged: (val) {
                          AudioManager.instance.playTap();
                          ProgressService.instance.updatePreferences(reducedMotion: val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION: HELP & DATA
                _buildSectionHeader('SUPPORT & DATA'),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D2C),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.help_outline, color: Color(0xFFFFD700)),
                        title: const Text(
                          'How to Play Guide',
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                        onTap: () => _showTutorialDialog(context),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        title: const Text(
                          'Reset All Progress',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                        onTap: () => _confirmReset(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Version Info
                const Center(
                  child: Text(
                    '3D Jigsaw Puzzle Adventure v1.0.0 (Build 1)\nProduction Android Edition',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF90A4AE),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
