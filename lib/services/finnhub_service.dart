import 'dart:convert';
import 'package:http/http.dart' as http;
 
class FinnhubService {
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with your key
  static const String _baseUrl = 'https://finnhub.io/api/v1';
 
  Future<List<Map<String, dynamic>>> getTopMovers(String type) async {
    String url = '';
 
    switch (type) {
      case 'gainers':
        url = '$_baseUrl/scan/technical-indicator?symbol=AAPL&resolution=D&token=$_apiKey';
        break;
      case 'losers':
        url = '$_baseUrl/news?category=forex&token=$_apiKey';
        break;
      default:
        url = '$_baseUrl/stock/symbol?exchange=NS&token=$_apiKey';
    }
 
    final response = await http.get(Uri.parse(url));
 
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }
}
 
