import 'package:flutter/material.dart';
import '../models/puzzle_section.dart';
import '../services/audio_manager.dart';
import '../services/progress_service.dart';
import '../widgets/section_card.dart';
import 'level_selection_screen.dart';

class SectionSelectionScreen extends StatelessWidget {
  const SectionSelectionScreen({super.key});

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
          'Select Section',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: ProgressService.instance,
            builder: (context, _) {
              final progress = ProgressService.instance.progress;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.totalStars}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ProgressService.instance,
          builder: (context, _) {
            final progress = ProgressService.instance.progress;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: PuzzleSection.sections.length,
              itemBuilder: (context, index) {
                final section = PuzzleSection.sections[index];
                final isUnlocked = progress.isSectionUnlocked(section.id);

                final sectionLevels = section.getLevels();
                final completedCount = sectionLevels
                    .where((l) => progress.levelStars.containsKey(l.id))
                    .length;

                final earnedStars = sectionLevels.fold(
                  0,
                  (sum, l) => sum + progress.getStarsForLevel(l.id),
                );

                return SectionCardWidget(
                  section: section,
                  isUnlocked: isUnlocked,
                  completedLevelsCount: completedCount,
                  earnedStars: earnedStars,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LevelSelectionScreen(section: section),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
