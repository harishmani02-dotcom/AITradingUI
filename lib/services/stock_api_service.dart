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
  // Free Yahoo Finance API endpoint
  static const String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  
  // Indian stock symbols (NSE)
  static final List<Map<String, String>> nseStocks = [
    {'symbol': 'TCS.NS', 'name': 'Tata Consultancy Services'},
    {'symbol': 'RELIANCE.NS', 'name': 'Reliance Industries'},
    {'symbol': 'INFY.NS', 'name': 'Infosys Ltd'},
    {'symbol': 'HDFCBANK.NS', 'name': 'HDFC Bank'},
    {'symbol': 'ICICIBANK.NS', 'name': 'ICICI Bank'},
    {'symbol': 'TATASTEEL.NS', 'name': 'Tata Steel'},
    {'symbol': 'HINDALCO.NS', 'name': 'Hindalco Industries'},
    {'symbol': 'JSWSTEEL.NS', 'name': 'JSW Steel'},
    {'symbol': 'COALINDIA.NS', 'name': 'Coal India'},
    {'symbol': 'VEDL.NS', 'name': 'Vedanta Ltd'},
    {'symbol': 'YESBANK.NS', 'name': 'Yes Bank'},
    {'symbol': 'BANKBARODA.NS', 'name': 'Bank of Baroda'},
    {'symbol': 'IDEA.NS', 'name': 'Vodafone Idea'},
    {'symbol': 'SUZLON.NS', 'name': 'Suzlon Energy'},
    {'symbol': 'TATAMOTORS.NS', 'name': 'Tata Motors'},
  ];
  
  /// Fetch Top Gainers
  Future<List<StockMover>> fetchTopGainers() async {
    List<StockMover> allStocks = await _fetchAllStocks();
    allStocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
    return allStocks.take(5).toList();
  }
  
  /// Fetch Top Losers
  Future<List<StockMover>> fetchTopLosers() async {
    List<StockMover> allStocks = await _fetchAllStocks();
    allStocks.sort((a, b) => a.changePercent.compareTo(b.changePercent));
    return allStocks.take(5).toList();
  }
  
  /// Fetch Volume Buzzers
  Future<List<StockMover>> fetchVolumeBuzzers() async {
    List<StockMover> allStocks = await _fetchAllStocks();
    allStocks.sort((a, b) => _parseVolume(b.volume).compareTo(_parseVolume(a.volume)));
    return allStocks.take(5).toList();
  }
  
  /// Fetch all stocks data
  Future<List<StockMover>> _fetchAllStocks() async {
    List<StockMover> stocks = [];
    
    for (var stock in nseStocks) {
      try {
        final stockData = await _fetchStockData(stock['symbol']!, stock['name']!);
        if (stockData != null) {
          stocks.add(stockData);
        }
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('Error fetching ${stock['symbol']}: $e');
      }
    }
    
    return stocks;
  }
  
  /// Fetch individual stock data from Yahoo Finance
  Future<StockMover?> _fetchStockData(String symbol, String name) async {
    try {
      final url = Uri.parse('$_baseUrl/$symbol?interval=1d&range=1d');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract quote data
        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final indicators = result['indicators']['quote'][0];
        
        double currentPrice = (meta['regularMarketPrice'] ?? 0).toDouble();
        double previousClose = (meta['previousClose'] ?? 0).toDouble();
        
        if (currentPrice == 0 || previousClose == 0) {
          return null;
        }
        
        double change = currentPrice - previousClose;
        double changePercent = (change / previousClose) * 100;
        
        // Volume data
        List<dynamic>? volumes = indicators['volume'];
        int totalVolume = 0;
        
        if (volumes != null && volumes.isNotEmpty) {
          for (var vol in volumes) {
            if (vol != null && vol is int) {
              totalVolume += vol;
            }
          }
        }
        
        return StockMover(
          symbol: symbol.replaceAll('.NS', ''),
          name: name,
          price: currentPrice,
          change: change,
          changePercent: changePercent,
          volume: _formatVolume(totalVolume),
          signal: _generateSignal(changePercent),
        );
      } else {
        print('API Error for $symbol: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception fetching $symbol: $e');
      return null;
    }
  }
  
  /// Generate Buy/Hold/Sell signal based on change percentage
  String _generateSignal(double changePercent) {
    if (changePercent > 2.0) return 'Buy';
    if (changePercent < -2.0) return 'Sell';
    return 'Hold';
  }
  
  /// Format volume to readable string (e.g., 1.5M, 250K)
  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }
  
  /// Parse volume string back to number for sorting
  double _parseVolume(String volume) {
    if (volume.isEmpty) return 0;
    
    String numPart = volume.replaceAll(RegExp(r'[^0-9.]'), '');
    double num = double.tryParse(numPart) ?? 0;
    
    if (volume.contains('M')) return num * 1000000;
    if (volume.contains('K')) return num * 1000;
    return num;
  }
}
 
