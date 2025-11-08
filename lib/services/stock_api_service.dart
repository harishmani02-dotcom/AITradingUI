import 'dart:convert';
import 'package:http/http.dart' as http;

class StockMover {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final String volume;
  final String signal;

  StockMover({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.signal,
  });

  factory StockMover.fromJson(Map<String, dynamic> json) {
    return StockMover(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      volume: json['volume'] ?? '0',
      signal: json['signal'] ?? 'Hold',
    );
  }
}

class StockApiService {
  // ⚠️ REPLACE WITH YOUR VERCEL URL
  static const String _apiUrl = 'https://YOUR-APP.vercel.app/api/stocks';
  
  Future<List<StockMover>> fetchTopGainers() async {
    final data = await _fetchData();
    if (data == null) return [];
    return (data['gainers'] as List).map((e) => StockMover.fromJson(e)).toList();
  }
  
  Future<List<StockMover>> fetchTopLosers() async {
    final data = await _fetchData();
    if (data == null) return [];
    return (data['losers'] as List).map((e) => StockMover.fromJson(e)).toList();
  }
  
  Future<List<StockMover>> fetchVolumeBuzzers() async {
    final data = await _fetchData();
    if (data == null) return [];
    return (data['buzzers'] as List).map((e) => StockMover.fromJson(e)).toList();
  }
  
  Future<Map<String, dynamic>?> _fetchData() async {
    try {
      print('🔄 Fetching from backend...');
      final res = await http.get(Uri.parse(_apiUrl)).timeout(Duration(seconds: 15));
      
      if (res.statusCode == 200) {
        print('✅ Got data from backend');
        return json.decode(res.body);
      }
      print('❌ Error: ${res.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error: $e');
      return null;
    }
  }
}
