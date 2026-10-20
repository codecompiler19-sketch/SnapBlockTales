import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_3d_adventure/game/puzzle_edge_generator.dart';
import 'package:jigsaw_3d_adventure/game/puzzle_piece_renderer.dart';

void main() {
  test('Test painting all 9 pieces on a canvas with dummy image', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Create a 300x300 image
    final picRecorder = ui.PictureRecorder();
    final c = Canvas(picRecorder);
    c.drawRect(const Rect.fromLTWH(0, 0, 300, 300), Paint()..color = Colors.blue);
    final dummyImg = await picRecorder.endRecording().toImage(300, 300);

    final pieces = PuzzleEdgeGenerator.generatePieces(rows: 3, cols: 3, seed: 1003);

    for (int i = 0; i < pieces.length; i++) {
      final p = pieces[i];
      final painter = PuzzlePiecePainter(
        image: dummyImg,
        piece: p,
        pieceWidth: 100,
        pieceHeight: 100,
        boardWidth: 300,
        boardHeight: 300,
        showNumberBadge: true,
      );
      expect(() => painter.paint(canvas, const Size(100, 100)), returnsNormally);
    }
  });

  test('Test with actual level_1.png file bytes', () async {
    final file = File('assets/images/levels/level_1.png');
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;

    print('Level 1 image dimensions: ${img.width}x${img.height}');

    final pieces = PuzzleEdgeGenerator.generatePieces(rows: 3, cols: 3, seed: 1003);
    for (int i = 0; i < pieces.length; i++) {
      final p = pieces[i];
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = PuzzlePiecePainter(
        image: img,
        piece: p,
        pieceWidth: 100,
        pieceHeight: 100,
        boardWidth: 300,
        boardHeight: 300,
        showNumberBadge: true,
      );
      painter.paint(canvas, const Size(100, 100));
      final picture = recorder.endRecording();
      final pieceImage = await picture.toImage(100, 100);
      expect(pieceImage.width, 100);
      expect(pieceImage.height, 100);
    }
  });
}
