import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_3d_adventure/app.dart';
import 'package:jigsaw_3d_adventure/game/puzzle_edge_generator.dart';
import 'package:jigsaw_3d_adventure/models/player_progress.dart';
import 'package:jigsaw_3d_adventure/models/puzzle_level.dart';
import 'package:jigsaw_3d_adventure/models/puzzle_piece.dart';
import 'package:jigsaw_3d_adventure/services/reward_service.dart';

void main() {
  testWidgets('App smoke test loads HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const JigsawAdventureApp());
    expect(find.text('3D JIGSAW'), findsOneWidget);
    expect(find.text('ADVENTURE'), findsOneWidget);
  });

  group('Puzzle Edge Generator Tests', () {
    test('Generates exact piece count for 3x3 grid', () {
      final pieces = PuzzleEdgeGenerator.generatePieces(
        rows: 3,
        cols: 3,
        seed: 12345,
      );
      expect(pieces.length, 9);
    });

    test('All outer border edges are flat EdgeShape.none', () {
      final pieces = PuzzleEdgeGenerator.generatePieces(
        rows: 4,
        cols: 5,
        seed: 42,
      );

      for (final p in pieces) {
        if (p.row == 0) expect(p.topEdge, EdgeShape.none);
        if (p.row == 3) expect(p.bottomEdge, EdgeShape.none);
        if (p.col == 0) expect(p.leftEdge, EdgeShape.none);
        if (p.col == 4) expect(p.rightEdge, EdgeShape.none);
      }
    });

    test('Adjacent pieces have matching interlocking tabs and blanks', () {
      final pieces = PuzzleEdgeGenerator.generatePieces(
        rows: 4,
        cols: 4,
        seed: 999,
      );

      // Check horizontal adjacency (right of piece (r, c) matches left of piece (r, c+1))
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 3; c++) {
          final pLeft = pieces.firstWhere((p) => p.row == r && p.col == c);
          final pRight = pieces.firstWhere((p) => p.row == r && p.col == c + 1);

          if (pLeft.rightEdge == EdgeShape.outTab) {
            expect(pRight.leftEdge, EdgeShape.inTab);
          } else {
            expect(pLeft.rightEdge, EdgeShape.inTab);
            expect(pRight.leftEdge, EdgeShape.outTab);
          }
        }
      }

      // Check vertical adjacency (bottom of piece (r, c) matches top of piece (r+1, c))
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 4; c++) {
          final pTop = pieces.firstWhere((p) => p.row == r && p.col == c);
          final pBottom = pieces.firstWhere((p) => p.row == r + 1 && p.col == c);

          if (pTop.bottomEdge == EdgeShape.outTab) {
            expect(pBottom.topEdge, EdgeShape.inTab);
          } else {
            expect(pTop.bottomEdge, EdgeShape.inTab);
            expect(pBottom.topEdge, EdgeShape.outTab);
          }
        }
      }
    });
  });

  group('Progress and Rewards Tests', () {
    test('All 50 levels exist and match specifications', () {
      final allLevels = PuzzleLevel.getAllLevels();
      expect(allLevels.length, 50);

      // Level 1: 3x3 = 9 pieces
      expect(allLevels[0].rows, 3);
      expect(allLevels[0].cols, 3);
      expect(allLevels[0].pieceCount, 9);

      // Level 10: 6x7 = 42 pieces
      expect(allLevels[9].rows, 6);
      expect(allLevels[9].cols, 7);
      expect(allLevels[9].pieceCount, 42);
    });

    test('Reward calculation awards stars correctly', () {
      final level = PuzzleLevel.getLevelById(1);
      final fastReward = RewardService.calculateReward(
        level: level,
        timeElapsedSeconds: 30,
        hintsUsed: 0,
        currentUnlockedSection: 1,
      );
      expect(fastReward.stars, 3);
      expect(fastReward.totalCoins, greaterThan(level.coinReward));
    });

    test('Player progress serialization preserves data', () {
      final progress = PlayerProgress(coins: 450, highestUnlockedLevel: 7);
      progress.completeLevel(1, 3, 40);

      final serialized = progress.serialize();
      final restored = PlayerProgress.deserialize(serialized);

      expect(restored.coins, 450);
      expect(restored.getStarsForLevel(1), 3);
      expect(restored.getBestTimeForLevel(1), 40);
    });
  });
}
