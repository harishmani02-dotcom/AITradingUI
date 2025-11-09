import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final supabase = Supabase.instance.client;
  
  Future<List<StockMover>> fetchTopGainers() async {
    final data = await supabase
        .from('stock_movers')
        .select('stocks')
        .eq('category', 'gainers')
        .single();
    
    final List stocks = json.decode(data['stocks']);
    return stocks.map((e) => StockMover.fromJson(e)).toList();
  }
  
  Future<List<StockMover>> fetchTopLosers() async {
    final data = await supabase
        .from('stock_movers')
        .select('stocks')
        .eq('category', 'losers')
        .single();
    
    final List stocks = json.decode(data['stocks']);
    return stocks.map((e) => StockMover.fromJson(e)).toList();
  }
  
  Future<List<StockMover>> fetchVolumeBuzzers() async {
    final data = await supabase
        .from('stock_movers')
        .select('stocks')
        .eq('category', 'buzzers')
        .single();
    
    final List stocks = json.decode(data['stocks']);
    return stocks.map((e) => StockMover.fromJson(e)).toList();
  }
}
