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
  final _supabase = Supabase.instance.client;
  
  Future<List<StockMover>> fetchTopGainers() async {
    try {
      print('🔄 Fetching gainers from Supabase...');
      
      final response = await _supabase
          .from('stock_data')
          .select('data')
          .eq('category', 'gainers')
          .single();
      
      final List stockList = json.decode(response['data']);
      print('✅ Got ${stockList.length} gainers');
      
      return stockList.map((e) => StockMover.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }
  
  Future<List<StockMover>> fetchTopLosers() async {
    try {
      print('🔄 Fetching losers from Supabase...');
      
      final response = await _supabase
          .from('stock_data')
          .select('data')
          .eq('category', 'losers')
          .single();
      
      final List stockList = json.decode(response['data']);
      print('✅ Got ${stockList.length} losers');
      
      return stockList.map((e) => StockMover.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }
  
  Future<List<StockMover>> fetchVolumeBuzzers() async {
    try {
      print('🔄 Fetching buzzers from Supabase...');
      
      final response = await _supabase
          .from('stock_data')
          .select('data')
          .eq('category', 'buzzers')
          .single();
      
      final List stockList = json.decode(response['data']);
      print('✅ Got ${stockList.length} buzzers');
      
      return stockList.map((e) => StockMover.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }
}
