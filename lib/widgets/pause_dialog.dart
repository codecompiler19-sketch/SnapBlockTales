import 'package:flutter/material.dart';
import '../services/audio_manager.dart';
import '../services/progress_service.dart';

class PauseDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSettings;
  final VoidCallback onExit;

  const PauseDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onSettings,
    required this.onExit,
  });

  @override
  State<PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<PauseDialog> {
  late bool _isMuted;

  @override
  void initState() {
    super.initState();
    _isMuted = ProgressService.instance.progress.isMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x90000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME PAUSED',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),

            // Mute / Unmute Quick Toggle Button
            IconButton(
              iconSize: 32,
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: _isMuted ? Colors.redAccent : const Color(0xFFFFD700),
              ),
              onPressed: () {
                AudioManager.instance.playTap();
                setState(() {
                  _isMuted = !_isMuted;
                });
                ProgressService.instance.updateAudioSettings(isMuted: _isMuted);
              },
            ),
            const SizedBox(height: 12),

            // Resume Button
            _buildDialogButton(
              title: 'Resume',
              icon: Icons.play_arrow_rounded,
              isPrimary: true,
              onTap: () {
                AudioManager.instance.playTap();
                widget.onResume();
              },
            ),
            const SizedBox(height: 10),

            // Restart Button
            _buildDialogButton(
              title: 'Restart Level',
              icon: Icons.refresh_rounded,
              isPrimary: false,
              onTap: () {
                AudioManager.instance.playTap();
                widget.onRestart();
              },
            ),
            const SizedBox(height: 10),

            // Settings Button
            _buildDialogButton(
              title: 'Settings',
              icon: Icons.settings,
              isPrimary: false,
              onTap: () {
                AudioManager.instance.playTap();
                widget.onSettings();
              },
            ),
            const SizedBox(height: 10),

            // Exit Button
            _buildDialogButton(
              title: 'Save & Exit',
              icon: Icons.exit_to_app_rounded,
              isPrimary: false,
              color: Colors.redAccent.withOpacity(0.8),
              onTap: () {
                AudioManager.instance.playTap();
                widget.onExit();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String title,
    required IconData icon,
    required bool isPrimary,
    Color? color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? const Color(0xFFFFD700)
              : (color ?? Colors.white.withOpacity(0.08)),
          foregroundColor: isPrimary ? const Color(0xFF212121) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: isPrimary ? 4 : 0,
        ),
      ),
    );
  }
}
