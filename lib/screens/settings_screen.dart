import 'package:flutter/material.dart';
import '../widgets/game_settings_panel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191B22),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: GameSettingsPanel(
            isInGame: false,
            onClose: () => Navigator.pop(context),
            onHome: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}
