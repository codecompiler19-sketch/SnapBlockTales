class CoinTransaction {
  final String id;
  final String title;
  final int amount; // positive for earn, negative for spend
  final DateTime timestamp;
  final String category; // 'level', 'daily', 'ad', 'hint', 'pack', 'cosmetic', 'mission'

  const CoinTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
    required this.category,
  });

  bool get isCredit => amount >= 0;

  String get formattedDate {
    final y = timestamp.year;
    final m = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    final h = timestamp.hour.toString().padLeft(2, '0');
    final min = timestamp.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'category': category,
      };

  factory CoinTransaction.fromJson(Map<String, dynamic> json) =>
      CoinTransaction(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        amount: json['amount'] as int? ?? 0,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        category: json['category'] as String? ?? 'general',
      );
}
