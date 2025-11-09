// dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'stock_mover.dart';

class StockApiService {
  final String? apiKey;

  StockApiService({this.apiKey});

  // Replace these endpoints with real provider endpoints
  static const _gainersUrl = 'https://api.example.com/top_gainers';
  static const _losersUrl = 'https://api.example.com/top_losers';
  static const _volumeUrl = 'https://api.example.com/volume_buzzers';

  Future<List<StockMover>> fetchTopGainers() async {
    return _fetchList(_gainersUrl);
  }

  Future<List<StockMover>> fetchTopLosers() async {
    return _fetchList(_losersUrl);
  }

  Future<List<StockMover>> fetchVolumeBuzzers() async {
    return _fetchList(_volumeUrl);
  }

  Future<List<StockMover>> _fetchList(String url) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      };
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        // Expect an array at top-level or adjust according to API
        final list = body is List ? body : (body['data'] ?? []);
        if (list is List) {
          return list
              .map((item) => StockMover.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else {
        // You can parse error message here if the API returns structured errors
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Log error in development; return empty list so UI can handle empty state
      // print('API fetch error for $url : $e');
    }
    return [];
  }
}
