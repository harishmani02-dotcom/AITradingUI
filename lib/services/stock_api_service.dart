// dart
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

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString();
    return double.tryParse(s) ?? 0.0;
  }

  factory StockMover.fromJson(Map<String, dynamic> json) {
    return StockMover(
      symbol: (json['symbol'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: _toDouble(json['price']),
      change: _toDouble(json['change']),
      changePercent: _toDouble(json['changePercent']),
      volume: (json['volume'] ?? '0').toString(),
      signal: (json['signal'] ?? 'Hold').toString(),
    );
  }
}

class StockApiService {
  final _supabase = Supabase.instance.client;

  /// Generic helper that fetches the row where category = [categoryKey]
  /// and returns parsed List<Map<String,dynamic>> from the `data` column.
  Future<List<Map<String, dynamic>>> _fetchDataArray(String categoryKey) async {
    try {
      print('🔄 Fetching $categoryKey from Supabase...');

      // The supabase client may return different shapes:
      // - a Map<String, dynamic> directly (row)
      // - an object with a `.data` property (PostgrestResponse-like)
      // Use the result as-is and extract the 'data' field.
      final response = await _supabase
          .from('stock_data')
          .select('data')
          .eq('category', categoryKey)
          .single();

      dynamic raw;
      // response might be a Map
      if (response is Map && response.containsKey('data')) {
        raw = response['data'];
      } else {
        // Some versions return object with .data property
        try {
          final maybeData = (response as dynamic).data;
          raw = maybeData ?? response;
        } catch (e) {
          raw = response;
        }
      }

      if (raw == null) {
        print('✅ No data found for category=$categoryKey (raw is null)');
        return [];
      }

      // raw might already be a List (parsed JSON), or a JSON string, or a single Map
      List<Map<String, dynamic>> parsedList = [];

      if (raw is String) {
        // stored as JSON string -> decode
        final decoded = json.decode(raw);
        if (decoded is List) {
          parsedList = decoded
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else if (decoded is Map) {
          parsedList = [Map<String, dynamic>.from(decoded)];
        } else {
          parsedList = [];
        }
      } else if (raw is List) {
        // already parsed as a List
        parsedList = raw
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (raw is Map) {
        parsedList = [Map<String, dynamic>.from(raw)];
      } else {
        // Unknown shape: try to stringify then decode
        try {
          final decodeAttempt = json.decode(raw.toString());
          if (decodeAttempt is List) {
            parsedList = decodeAttempt
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else if (decodeAttempt is Map) {
            parsedList = [Map<String, dynamic>.from(decodeAttempt)];
          }
        } catch (_) {
          parsedList = [];
        }
      }

      print('✅ Parsed ${parsedList.length} items for category=$categoryKey');
      return parsedList;
    } catch (e, st) {
      print('❌ Error fetching category=$categoryKey : $e');
      print(st);
      return [];
    }
  }

  Future<List<StockMover>> fetchTopGainers() async {
    final parsed = await _fetchDataArray('gainers');
    return parsed.map((e) => StockMover.fromJson(e)).toList();
  }

  Future<List<StockMover>> fetchTopLosers() async {
    final parsed = await _fetchDataArray('losers');
    return parsed.map((e) => StockMover.fromJson(e)).toList();
  }

  Future<List<StockMover>> fetchVolumeBuzzers() async {
    final parsed = await _fetchDataArray('buzzers');
    return parsed.map((e) => StockMover.fromJson(e)).toList();
  }
}
