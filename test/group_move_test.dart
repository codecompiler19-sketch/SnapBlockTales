import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_3d_adventure/game/puzzle_edge_generator.dart';
import 'package:jigsaw_3d_adventure/models/puzzle_piece.dart';

void main() {
  test('Simulate 5-piece group move up', () {
    final pieces = PuzzleEdgeGenerator.generatePieces(rows: 3, cols: 3, seed: 1000);
    // In user screenshot:
    // Group is slots: 3, 4, 5, 6, 7
    final groupSlots = {3, 4, 5, 6, 7};
    final dRow = -1;
    final dCol = 0;

    final Map<int, int> groupSlotMoves = {};
    for (final s in groupSlots) {
      final r = s ~/ 3 + dRow;
      final c = s % 3 + dCol;
      groupSlotMoves[s] = r * 3 + c;
    }

    final targetSlots = groupSlotMoves.values.toSet();
    final vacatedSlots = groupSlots.where((s) => !targetSlots.contains(s)).toList();
    final displacedSlots = targetSlots.where((s) => !groupSlots.contains(s)).toList();

    print('groupSlotMoves: $groupSlotMoves');
    print('targetSlots: $targetSlots');
    print('vacatedSlots: $vacatedSlots');
    print('displacedSlots: $displacedSlots');

    final Map<int, int> displacedSlotMoves = {};
    for (final dSlot in displacedSlots) {
      final naturalVacated = (dSlot ~/ 3 - dRow) * 3 + (dSlot % 3 - dCol);
      if (vacatedSlots.contains(naturalVacated)) {
        displacedSlotMoves[dSlot] = naturalVacated;
      }
    }

    final remainingVacated = vacatedSlots.where((s) => !displacedSlotMoves.values.contains(s)).toList();
    final remainingDisplaced = displacedSlots.where((s) => !displacedSlotMoves.containsKey(s)).toList();
    for (int i = 0; i < remainingDisplaced.length; i++) {
      displacedSlotMoves[remainingDisplaced[i]] = remainingVacated[i];
    }

    print('displacedSlotMoves: $displacedSlotMoves');

    final groupPieces = groupSlots.map((s) => pieces.firstWhere((p) => p.currentSlot == s)).toList();
    final displacedPieces = displacedSlots.map((s) => pieces.firstWhere((p) => p.currentSlot == s)).toList();

    for (final p in groupPieces) {
      p.currentSlot = groupSlotMoves[p.currentSlot]!;
    }
    for (final p in displacedPieces) {
      p.currentSlot = displacedSlotMoves[p.currentSlot]!;
    }

    final allSlots = pieces.map((p) => p.currentSlot).toList();
    print('All piece slots after move: $allSlots');
    expect(allSlots.toSet().length, 9, reason: 'Must have all 9 unique slots');
  });
}
