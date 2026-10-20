import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class JigsawAdventureApp extends StatelessWidget {
  const JigsawAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3D Jigsaw Puzzle Adventure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
  }
}
