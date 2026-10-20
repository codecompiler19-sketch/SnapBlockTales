import 'dart:math';
import 'dart:ui';
import '../models/puzzle_piece.dart';

class PuzzleEdgeGenerator {
  /// Generates a grid of interlocking pieces deterministically using levelId as seed.
  static List<PuzzlePiece> generatePieces({
    required int rows,
    required int cols,
    required int seed,
  }) {
    final rand = Random(seed);
    final List<PuzzlePiece> pieces = [];

    // Horizontal edges matrix: [rows - 1][cols]
    // Value: true = tab points down (+1 from row r to r+1), false = points up (-1)
    final List<List<bool>> horizTabs = List.generate(
      rows - 1,
      (_) => List.generate(cols, (_) => rand.nextBool()),
    );

    // Vertical edges matrix: [rows][cols - 1]
    // Value: true = tab points right (+1 from col c to c+1), false = points left (-1)
    final List<List<bool>> vertTabs = List.generate(
      rows,
      (_) => List.generate(cols - 1, (_) => rand.nextBool()),
    );

    int idCounter = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Top edge
        EdgeShape top;
        if (r == 0) {
          top = EdgeShape.none;
        } else {
          // If the horizontal edge above pointed down, this piece receives an inTab
          top = horizTabs[r - 1][c] ? EdgeShape.inTab : EdgeShape.outTab;
        }

        // Bottom edge
        EdgeShape bottom;
        if (r == rows - 1) {
          bottom = EdgeShape.none;
        } else {
          // If this horizontal edge points down, bottom of piece r is outTab
          bottom = horizTabs[r][c] ? EdgeShape.outTab : EdgeShape.inTab;
        }

        // Left edge
        EdgeShape left;
        if (c == 0) {
          left = EdgeShape.none;
        } else {
          // If the vertical edge to the left pointed right, this piece receives inTab
          left = vertTabs[r][c - 1] ? EdgeShape.inTab : EdgeShape.outTab;
        }

        // Right edge
        EdgeShape right;
        if (c == cols - 1) {
          right = EdgeShape.none;
        } else {
          // If this vertical edge points right, right of piece c is outTab
          right = vertTabs[r][c] ? EdgeShape.outTab : EdgeShape.inTab;
        }

        pieces.add(
          PuzzlePiece(
            id: idCounter++,
            row: r,
            col: c,
            topEdge: top,
            rightEdge: right,
            bottomEdge: bottom,
            leftEdge: left,
            normX: c / cols,
            normY: r / rows,
            normWidth: 1.0 / cols,
            normHeight: 1.0 / rows,
          ),
        );
      }
    }

    return pieces;
  }

  /// Builds the closed interlocking jigsaw path for a piece within its local bounding box.
  static Path buildPiecePath({
    required double width,
    required double height,
    required EdgeShape top,
    required EdgeShape right,
    required EdgeShape bottom,
    required EdgeShape left,
  }) {
    final path = Path();
    path.moveTo(0, 0);

    // Top edge: (0, 0) -> (width, 0)
    _appendEdge(
      path: path,
      start: const Offset(0, 0),
      end: Offset(width, 0),
      shape: top,
    );

    // Right edge: (width, 0) -> (width, height)
    _appendEdge(
      path: path,
      start: Offset(width, 0),
      end: Offset(width, height),
      shape: right,
    );

    // Bottom edge: (width, height) -> (0, height)
    _appendEdge(
      path: path,
      start: Offset(width, height),
      end: Offset(0, height),
      shape: bottom,
    );

    // Left edge: (0, height) -> (0, 0)
    _appendEdge(
      path: path,
      start: Offset(0, height),
      end: const Offset(0, 0),
      shape: left,
    );

    path.close();
    return path;
  }

  static void _appendEdge({
    required Path path,
    required Offset start,
    required Offset end,
    required EdgeShape shape,
  }) {
    if (shape == EdgeShape.none) {
      path.lineTo(end.dx, end.dy);
      return;
    }

    final v = end - start;
    final length = v.distance;
    final u = v / length; // tangent
    // Normal vector pointing strictly outward for clockwise perimeter
    final n = Offset(u.dy, -u.dx);

    final sign = (shape == EdgeShape.outTab) ? 1.0 : -1.0;
    // Tab height is 22% of edge length
    final tabHeight = length * 0.22;

    Offset pt(double t, double d) {
      return start + (u * (t * length)) + (n * (d * tabHeight * sign));
    }

    // Straight baseline to neck start
    path.lineTo(pt(0.35, 0.0).dx, pt(0.35, 0.0).dy);

    // Neck waist curve
    path.cubicTo(
      pt(0.36, -0.06).dx, pt(0.36, -0.06).dy,
      pt(0.38, 0.08).dx, pt(0.38, 0.08).dy,
      pt(0.40, 0.32).dx, pt(0.40, 0.32).dy,
    );

    // Bulb head apex
    path.cubicTo(
      pt(0.42, 0.82).dx, pt(0.42, 0.82).dy,
      pt(0.45, 1.05).dx, pt(0.45, 1.05).dy,
      pt(0.50, 1.05).dx, pt(0.50, 1.05).dy,
    );

    // Bulb other side
    path.cubicTo(
      pt(0.55, 1.05).dx, pt(0.55, 1.05).dy,
      pt(0.58, 0.82).dx, pt(0.58, 0.82).dy,
      pt(0.60, 0.32).dx, pt(0.60, 0.32).dy,
    );

    // Neck returning to baseline
    path.cubicTo(
      pt(0.62, 0.08).dx, pt(0.62, 0.08).dy,
      pt(0.64, -0.06).dx, pt(0.64, -0.06).dy,
      pt(0.65, 0.0).dx, pt(0.65, 0.0).dy,
    );

    // Baseline to end
    path.lineTo(end.dx, end.dy);
  }
}
