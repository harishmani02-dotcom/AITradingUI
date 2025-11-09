// dart
import 'package:flutter/foundation.dart';

class StockMover {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final int volume;
  final String signal;

  StockMover({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.volume,
    required this.signal,
  });

  factory StockMover.fromJson(Map<String, dynamic> json) {
    // Adjust field names according to your API response
    return StockMover(
      symbol: json['symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price']),
      changePercent: _toDouble(json['changePercent']),
      volume: _toInt(json['volume']),
      signal: json['signal']?.toString() ?? 'Neutral',
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
