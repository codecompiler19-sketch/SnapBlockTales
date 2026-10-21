import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_3d_adventure/game/puzzle_edge_generator.dart';

void main() {
  test('Print piece rows and cols', () {
    final pieces = PuzzleEdgeGenerator.generatePieces(rows: 3, cols: 3, seed: 1003);
    for (final p in pieces) {
      print('Piece ${p.id}: original (row: ${p.row}, col: ${p.col})');
    }
  });
}
