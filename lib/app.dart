import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/progress_service.dart';

class JigsawAdventureApp extends StatelessWidget {
  const JigsawAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final isDark = ProgressService.instance.progress.darkMode;

        return MaterialApp(
          title: 'SnapBlockTales',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF0F2F6),
            primaryColor: const Color(0xFFFF8E00),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF8E00),
              secondary: Color(0xFF2563EB),
              surface: Colors.white,
            ),
            fontFamily: 'Roboto',
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F111A),
            primaryColor: const Color(0xFFFFD700),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              secondary: Color(0xFF3B82F6),
              surface: Color(0xFF1B1D2C),
            ),
            fontFamily: 'Roboto',
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.windows: ZoomPageTransitionsBuilder(),
              },
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
