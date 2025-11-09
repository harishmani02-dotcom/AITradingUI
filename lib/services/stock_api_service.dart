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
}

class StockApiService {
  // Replace with your Alpha Vantage API key
  static const String _apiKey = 'W3YWTWU0LQMF83KQ';
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  
  // Top Indian stocks
  static final List<Map<String, String>> indianStocks = [
    {'symbol': 'RELIANCE.BSE', 'name': 'Reliance Industries'},
    {'symbol': 'TCS.BSE', 'name': 'Tata Consultancy Services'},
    {'symbol': 'HDFCBANK.BSE', 'name': 'HDFC Bank'},
    {'symbol': 'INFY.BSE', 'name': 'Infosys Ltd'},
    {'symbol': 'ICICIBANK.BSE', 'name': 'ICICI Bank'},
    {'symbol': 'HINDUNILVR.BSE', 'name': 'Hindustan Unilever'},
    {'symbol': 'ITC.BSE', 'name': 'ITC Ltd'},
    {'symbol': 'SBIN.BSE', 'name': 'State Bank of India'},
    {'symbol': 'BHARTIARTL.BSE', 'name': 'Bharti Airtel'},
    {'symbol': 'KOTAKBANK.BSE', 'name': 'Kotak Mahindra Bank'},
    {'symbol': 'LT.BSE', 'name': 'Larsen & Toubro'},
    {'symbol': 'AXISBANK.BSE', 'name': 'Axis Bank'},
    {'symbol': 'ASIANPAINT.BSE', 'name': 'Asian Paints'},
    {'symbol': 'MARUTI.BSE', 'name': 'Maruti Suzuki'},
    {'symbol': 'SUNPHARMA.BSE', 'name': 'Sun Pharmaceutical'},
  ];
  
  Future<List<StockMover>> fetchTopGainers() async {
    List<StockMover> allStocks = await _fetchAllStocks();
    if (allStocks.isEmpty) return [];
    
    allStocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
    return allStocks.where((s) => s.changePercent > 0).take(10).toList();
  }
  
  Future<List<StockMover>> fetchTopLosers() async {
    List<StockMover> allStocks = await _fetchAllStocks();
    if (allStocks.isEmpty) return [];
    
    allStocks.sort((a, b) => a.changePercent.compareTo(b.changePercent));
    return allStocks.where((s) => s.changePercent < 0).take(10).toList();
  }
  
  Future<List<StockMover>> fetchVolumeBuzzers() async {
    List<StockMover> allStocks = await _fetchAllStocks();
    if (allStocks.isEmpty) return [];
    
    allStocks.sort((a, b) => _parseVolume(b.volume).compareTo(_parseVolume(a.volume)));
    return allStocks.take(10).toList();
  }
  
  Future<List<StockMover>> _fetchAllStocks() async {
    List<StockMover> stocks = [];
    
    // Fetch only 5 stocks to avoid rate limit (adjust based on your needs)
    for (int i = 0; i < 5 && i < indianStocks.length; i++) {
      try {
        final stock = await _fetchStockData(
          indianStocks[i]['symbol']!,
          indianStocks[i]['name']!
        );
        
        if (stock != null) {
          stocks.add(stock);
        }
        
        // Delay to respect rate limit (5 calls per minute)
        await Future.delayed(Duration(seconds: 13));
      } catch (e) {
        print('Error fetching ${indianStocks[i]['symbol']}: $e');
      }
    }
    
    return stocks;
  }
  
  Future<StockMover?> _fetchStockData(String symbol, String name) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey'
      );
      
      print('🔄 Fetching $symbol...');
      
      final response = await http.get(url).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('Global Quote')) {
          final quote = data['Global Quote'];
          
          double price = double.tryParse(quote['05. price'] ?? '0') ?? 0;
          double change = double.tryParse(quote['09. change'] ?? '0') ?? 0;
          String changePctStr = quote['10. change percent'] ?? '0%';
          double changePct = double.tryParse(changePctStr.replaceAll('%', '')) ?? 0;
          int volume = int.tryParse(quote['06. volume'] ?? '0') ?? 0;
          
          if (price > 0) {
            print('✅ Got $symbol: ₹$price');
            return StockMover(
              symbol: symbol.split('.').first,
              name: name,
              price: price,
              change: change,
              changePercent: changePct,
              volume: _formatVolume(volume),
              signal: _generateSignal(changePct),
            );
          }
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error: $e');
      return null;
    }
  }
  
  String _generateSignal(double changePercent) {
    if (changePercent > 2.0) return 'Buy';
    if (changePercent < -2.0) return 'Sell';
    return 'Hold';
  }
  
  String _formatVolume(int volume) {
    if (volume >= 10000000) return '${(volume / 10000000).toStringAsFixed(1)}Cr';
    if (volume >= 100000) return '${(volume / 100000).toStringAsFixed(1)}L';
    if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(1)}K';
    return volume.toString();
  }
  
  double _parseVolume(String volume) {
    if (volume.isEmpty) return 0;
    String numPart = volume.replaceAll(RegExp(r'[^0-9.]'), '');
    double num = double.tryParse(numPart) ?? 0;
    if (volume.contains('Cr')) return num * 10000000;
    if (volume.contains('L')) return num * 100000;
    if (volume.contains('K')) return num * 1000;
    return num;
  }
}
