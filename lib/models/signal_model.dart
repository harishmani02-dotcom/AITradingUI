import 'dart:ui';

class SignalModel {
  final int id;
  final String symbol;
  final String signal;
  final double confidence;
  final double closePrice;
  final double rsi;
  final int buyVotes;
  final int sellVotes;
  final int holdVotes;
  final DateTime signalDate;
  final DateTime createdAt;
 
  SignalModel({
    required this.id,
    required this.symbol,
    required this.signal,
    required this.confidence,
    required this.closePrice,
    required this.rsi,
    required this.buyVotes,
    required this.sellVotes,
    required this.holdVotes,
    required this.signalDate,
    required this.createdAt,
  });
 
  factory SignalModel.fromJson(Map<String, dynamic> json) {
    return SignalModel(
      id: json['id'] ?? 0,
      symbol: json['symbol'] ?? '',
      signal: json['signal'] ?? 'Hold',
      confidence: (json['confidence'] ?? 0).toDouble(),
      closePrice: (json['close_price'] ?? 0).toDouble(),
      rsi: (json['rsi'] ?? 0).toDouble(),
      buyVotes: json['buy_votes'] ?? 0,
      sellVotes: json['sell_votes'] ?? 0,
      holdVotes: json['hold_votes'] ?? 0,
      signalDate: DateTime.parse(json['signal_date'] ?? DateTime.now().toString()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }
 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'signal': signal,
      'confidence': confidence,
      'close_price': closePrice,
      'rsi': rsi,
      'buy_votes': buyVotes,
      'sell_votes': sellVotes,
      'hold_votes': holdVotes,
      'signal_date': signalDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
 
  // Helper methods
  Color getSignalColor() {
    switch (signal.toLowerCase()) {
      case 'buy':
        return const Color(0xFF10B981); // Green
      case 'sell':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF9CA3AF); // Gray
    }
  }
 
  Color getSignalBackgroundColor() {
    switch (signal.toLowerCase()) {
      case 'buy':
        return const Color(0xFFD1FAE5);
      case 'sell':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }
 
  String getSignalEmoji() {
    switch (signal.toLowerCase()) {
      case 'buy':
        return '⬆️';
      case 'sell':
        return '⬇️';
      default:
        return '➡️';
    }
  }
}