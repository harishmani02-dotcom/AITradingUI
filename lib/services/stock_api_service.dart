import 'dart:convert';
import 'dart:io';
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
  // Using RapidAPI's Yahoo Finance endpoint (more reliable)
  static const String _baseUrl = 'https://query1.finance.yahoo.com/v7/finance/quote';
  
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
    List<StockMover> allStocks = await _fetchAllStocksBatch();
    
    if (allStocks.isEmpty) {
      print('⚠️ No stocks fetched. Using fallback data.');
      return _getFallbackGainers();
    }
    
    allStocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
    return allStocks.take(5).toList();
  }
  
  /// Fetch Top Losers
  Future<List<StockMover>> fetchTopLosers() async {
    List<StockMover> allStocks = await _fetchAllStocksBatch();
    
    if (allStocks.isEmpty) {
      print('⚠️ No stocks fetched. Using fallback data.');
      return _getFallbackLosers();
    }
    
    allStocks.sort((a, b) => a.changePercent.compareTo(b.changePercent));
    return allStocks.take(5).toList();
  }
  
  /// Fetch Volume Buzzers
  Future<List<StockMover>> fetchVolumeBuzzers() async {
    List<StockMover> allStocks = await _fetchAllStocksBatch();
    
    if (allStocks.isEmpty) {
      print('⚠️ No stocks fetched. Using fallback data.');
      return _getFallbackVolumeBuzzers();
    }
    
    allStocks.sort((a, b) => _parseVolume(b.volume).compareTo(_parseVolume(a.volume)));
    return allStocks.take(5).toList();
  }
  
  /// Fetch all stocks in a single batch request (faster & more reliable)
  Future<List<StockMover>> _fetchAllStocksBatch() async {
    try {
      // Get all symbols as comma-separated string
      String symbols = nseStocks.map((s) => s['symbol']).join(',');
      
      final url = Uri.parse('$_baseUrl?symbols=$symbols');
      
      print('🔄 Fetching stock data...');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw HttpException('Request timeout');
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['quoteResponse']['result'] as List;
        
        print('✅ Received ${results.length} stocks');
        
        List<StockMover> stocks = [];
        
        for (var quote in results) {
          try {
            double currentPrice = (quote['regularMarketPrice'] ?? 0).toDouble();
            double previousClose = (quote['regularMarketPreviousClose'] ?? 0).toDouble();
            
            if (currentPrice == 0 || previousClose == 0) continue;
            
            double change = currentPrice - previousClose;
            double changePercent = (change / previousClose) * 100;
            
            int volume = (quote['regularMarketVolume'] ?? 0);
            String symbol = quote['symbol'] ?? '';
            String name = quote['shortName'] ?? quote['longName'] ?? symbol;
            
            stocks.add(StockMover(
              symbol: symbol.replaceAll('.NS', ''),
              name: name,
              price: currentPrice,
              change: change,
              changePercent: changePercent,
              volume: _formatVolume(volume),
              signal: _generateSignal(changePercent),
            ));
          } catch (e) {
            print('⚠️ Error parsing stock: $e');
            continue;
          }
        }
        
        return stocks;
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } on SocketException {
      print('❌ No internet connection');
      return [];
    } on HttpException catch (e) {
      print('❌ HTTP Error: $e');
      return [];
    } catch (e) {
      print('❌ Unexpected error: $e');
      return [];
    }
  }
  
  /// Generate Buy/Hold/Sell signal
  String _generateSignal(double changePercent) {
    if (changePercent > 2.0) return 'Buy';
    if (changePercent < -2.0) return 'Sell';
    return 'Hold';
  }
  
  /// Format volume to readable string
  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }
  
  /// Parse volume string back to number
  double _parseVolume(String volume) {
    if (volume.isEmpty) return 0;
    
    String numPart = volume.replaceAll(RegExp(r'[^0-9.]'), '');
    double num = double.tryParse(numPart) ?? 0;
    
    if (volume.contains('M')) return num * 1000000;
    if (volume.contains('K')) return num * 1000;
    return num;
  }
  
  // ========== FALLBACK DATA (When API fails) ==========
  
  List<StockMover> _getFallbackGainers() {
    return [
      StockMover(
        symbol: 'TCS',
        name: 'Tata Consultancy',
        price: 3456.75,
        change: 112.50,
        changePercent: 3.36,
        volume: '2.5M',
        signal: 'Buy',
      ),
      StockMover(
        symbol: 'RELIANCE',
        name: 'Reliance Industries',
        price: 2456.80,
        change: 68.30,
        changePercent: 2.86,
        volume: '4.2M',
        signal: 'Buy',
      ),
      StockMover(
        symbol: 'INFY',
        name: 'Infosys Ltd',
        price: 1432.60,
        change: 29.40,
        changePercent: 2.09,
        volume: '3.1M',
        signal: 'Hold',
      ),
      StockMover(
        symbol: 'HDFCBANK',
        name: 'HDFC Bank',
        price: 1645.25,
        change: 31.75,
        changePercent: 1.97,
        volume: '5.8M',
        signal: 'Buy',
      ),
      StockMover(
        symbol: 'ICICIBANK',
        name: 'ICICI Bank',
        price: 987.50,
        change: 17.80,
        changePercent: 1.84,
        volume: '6.3M',
        signal: 'Buy',
      ),
    ];
  }
  
  List<StockMover> _getFallbackLosers() {
    return [
      StockMover(
        symbol: 'TATASTEEL',
        name: 'Tata Steel',
        price: 125.40,
        change: -4.60,
        changePercent: -3.54,
        volume: '8.2M',
        signal: 'Sell',
      ),
      StockMover(
        symbol: 'HINDALCO',
        name: 'Hindalco Industries',
        price: 412.30,
        change: -13.70,
        changePercent: -3.22,
        volume: '4.5M',
        signal: 'Sell',
      ),
      StockMover(
        symbol: 'JSWSTEEL',
        name: 'JSW Steel',
        price: 756.80,
        change: -19.20,
        changePercent: -2.47,
        volume: '3.9M',
        signal: 'Hold',
      ),
      StockMover(
        symbol: 'COALINDIA',
        name: 'Coal India',
        price: 234.50,
        change: -5.50,
        changePercent: -2.29,
        volume: '5.1M',
        signal: 'Sell',
      ),
      StockMover(
        symbol: 'VEDL',
        name: 'Vedanta Ltd',
        price: 298.75,
        change: -6.25,
        changePercent: -2.05,
        volume: '7.4M',
        signal: 'Sell',
      ),
    ];
  }
  
  List<StockMover> _getFallbackVolumeBuzzers() {
    return [
      StockMover(
        symbol: 'YESBANK',
        name: 'Yes Bank',
        price: 18.45,
        change: 0.35,
        changePercent: 1.93,
        volume: '125M',
        signal: 'Hold',
      ),
      StockMover(
        symbol: 'BANKBARODA',
        name: 'Bank of Baroda',
        price: 187.60,
        change: -2.40,
        changePercent: -1.26,
        volume: '45M',
        signal: 'Hold',
      ),
      StockMover(
        symbol: 'IDEA',
        name: 'Vodafone Idea',
        price: 9.75,
        change: 0.15,
        changePercent: 1.56,
        volume: '98M',
        signal: 'Sell',
      ),
      StockMover(
        symbol: 'SUZLON',
        name: 'Suzlon Energy',
        price: 45.30,
        change: 1.80,
        changePercent: 4.14,
        volume: '67M',
        signal: 'Buy',
      ),
      StockMover(
        symbol: 'TATAMOTORS',
        name: 'Tata Motors',
        price: 678.90,
        change: 12.40,
        changePercent: 1.86,
        volume: '38M',
        signal: 'Buy',
      ),
    ];
  }
}
