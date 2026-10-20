import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/audio_manager.dart';
import 'services/progress_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Immersive edge-to-edge system UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F111A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock orientation to portrait for optimal mobile puzzle ergonomics
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize persistent player progress & audio manager
  final progressService = ProgressService.instance;
  await progressService.init();

  await AudioManager.instance.init(
    bgmVolume: progressService.progress.bgmVolume,
    sfxVolume: progressService.progress.sfxVolume,
    isMuted: progressService.progress.isMuted,
    hapticEnabled: progressService.progress.hapticEnabled,
  );

  runApp(const JigsawAdventureApp());
}
