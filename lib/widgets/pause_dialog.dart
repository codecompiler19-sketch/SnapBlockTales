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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Main 3D Pause Board
              Container(
                margin: const EdgeInsets.only(top: 40),
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/3d/panel_pause_board.png'),
                    fit: BoxFit.fill,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mute / Unmute Quick Toggle Button with sound indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1810).withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            iconSize: 28,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: _isMuted ? Colors.redAccent : const Color(0xFFFFD700),
                            ),
                            onPressed: () {
                              AudioManager.instance.playTap();
                              setState(() {
                                _isMuted = !_isMuted;
                              });
                              ProgressService.instance
                                  .updateAudioSettings(isMuted: _isMuted);
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isMuted ? 'Sound Muted' : 'Sound On',
                            style: TextStyle(
                              color: _isMuted ? Colors.redAccent : const Color(0xFFFFE082),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Resume Button (3D Wooden Plank)
                    _buildWoodPlankButton(
                      title: 'Resume',
                      icon: Icons.play_arrow_rounded,
                      textColor: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFFFD54F),
                      onTap: () {
                        AudioManager.instance.playTap();
                        widget.onResume();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Restart Button (3D Wooden Plank)
                    _buildWoodPlankButton(
                      title: 'Restart Level',
                      icon: Icons.refresh_rounded,
                      textColor: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFFFD54F),
                      onTap: () {
                        AudioManager.instance.playTap();
                        widget.onRestart();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Settings Button (3D Wooden Plank)
                    _buildWoodPlankButton(
                      title: 'Settings',
                      icon: Icons.settings_rounded,
                      textColor: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFFFD54F),
                      onTap: () {
                        AudioManager.instance.playTap();
                        widget.onSettings();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Save & Exit Button (3D Wooden Plank)
                    _buildWoodPlankButton(
                      title: 'Save & Exit',
                      icon: Icons.exit_to_app_rounded,
                      textColor: const Color(0xFFFFCDD2),
                      iconColor: const Color(0xFFEF5350),
                      onTap: () {
                        AudioManager.instance.playTap();
                        widget.onExit();
                      },
                    ),
                  ],
                ),
              ),

              // Overhanging 3D Ribbon Banner ("PAUSED")
              Positioned(
                top: 0,
                child: Image.asset(
                  'assets/images/3d/ribbon_paused.png',
                  width: 250,
                  height: 65,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWoodPlankButton({
    required String title,
    required IconData icon,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/3d/btn_wood_wide.png'),
            fit: BoxFit.fill,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF3E2723),
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
