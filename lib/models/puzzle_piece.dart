enum EdgeShape {
  none,   // Flat border
  outTab, // Protruding tab
  inTab,  // Inward blank/socket
}

class PuzzlePiece {
  final int id;
  final int row;
  final int col;
  final EdgeShape topEdge;
  final EdgeShape rightEdge;
  final EdgeShape bottomEdge;
  final EdgeShape leftEdge;

  // Normalized bounds inside original image (0.0 to 1.0)
  final double normX;
  final double normY;
  final double normWidth;
  final double normHeight;

  bool isPlaced;
  int currentSlot; // Slot index on the board (0 .. rows*cols - 1)
  int rotation;

  PuzzlePiece({
    required this.id,
    required this.row,
    required this.col,
    required this.topEdge,
    required this.rightEdge,
    required this.bottomEdge,
    required this.leftEdge,
    required this.normX,
    required this.normY,
    required this.normWidth,
    required this.normHeight,
    this.isPlaced = false,
    int? currentSlot,
    this.rotation = 0,
  }) : currentSlot = currentSlot ?? id;

  bool get isCorrect => currentSlot == id;

  bool get isEdgePiece =>
      topEdge == EdgeShape.none ||
      rightEdge == EdgeShape.none ||
      bottomEdge == EdgeShape.none ||
      leftEdge == EdgeShape.none;

  Map<String, dynamic> toJson() => {
        'id': id,
        'row': row,
        'col': col,
        'isPlaced': isPlaced,
        'currentSlot': currentSlot,
        'rotation': rotation,
      };

  factory PuzzlePiece.fromJson(Map<String, dynamic> json, PuzzlePiece template) {
    return PuzzlePiece(
      id: template.id,
      row: template.row,
      col: template.col,
      topEdge: template.topEdge,
      rightEdge: template.rightEdge,
      bottomEdge: template.bottomEdge,
      leftEdge: template.leftEdge,
      normX: template.normX,
      normY: template.normY,
      normWidth: template.normWidth,
      normHeight: template.normHeight,
      isPlaced: json['isPlaced'] as bool? ?? false,
      currentSlot: json['currentSlot'] as int? ?? template.id,
      rotation: json['rotation'] as int? ?? 0,
    );
  }
}
