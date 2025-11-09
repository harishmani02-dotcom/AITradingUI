import 'dart:convert';
import 'dart:io';
import 'dart:async';
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
  static const String _yahooFinanceUrl = 'https://query1.finance.yahoo.com/v7/finance/quote';
  
  // Top 100 NSE stocks
  static final List<String> nseStocks = [
    'RELIANCE.NS', 'TCS.NS', 'HDFCBANK.NS', 'INFY.NS', 'ICICIBANK.NS',
    'HINDUNILVR.NS', 'ITC.NS', 'SBIN.NS', 'BHARTIARTL.NS', 'KOTAKBANK.NS',
    'LT.NS', 'AXISBANK.NS', 'ASIANPAINT.NS', 'MARUTI.NS', 'SUNPHARMA.NS',
    'TITAN.NS', 'ULTRACEMCO.NS', 'BAJFINANCE.NS', 'NESTLEIND.NS', 'WIPRO.NS',
    'HCLTECH.NS', 'TECHM.NS', 'POWERGRID.NS', 'NTPC.NS', 'ONGC.NS',
    'M&M.NS', 'TATAMOTORS.NS', 'TATASTEEL.NS', 'JSWSTEEL.NS', 'HINDALCO.NS',
    'COALINDIA.NS', 'GRASIM.NS', 'ADANIPORTS.NS', 'BAJAJFINSV.NS', 'INDUSINDBK.NS',
    'DRREDDY.NS', 'DIVISLAB.NS', 'CIPLA.NS', 'EICHERMOT.NS', 'SHREECEM.NS',
    'UPL.NS', 'APOLLOHOSP.NS', 'BRITANNIA.NS', 'HEROMOTOCO.NS', 'BAJAJ-AUTO.NS',
    'SBILIFE.NS', 'BPCL.NS', 'IOC.NS', 'ADANIENT.NS', 'TATACONSUM.NS',
    'YESBANK.NS', 'BANKBARODA.NS', 'PNB.NS', 'UNIONBANK.NS', 'CANBK.NS',
    'SUZLON.NS', 'SAIL.NS', 'NMDC.NS', 'JINDALSTEL.NS', 'VEDL.NS',
    'GAIL.NS', 'PETRONET.NS', 'HINDPETRO.NS', 'FEDERALBNK.NS', 'RBLBANK.NS',
    'LUPIN.NS', 'AUROPHARMA.NS', 'BIOCON.NS', 'CADILAHC.NS', 'TORNTPHARM.NS',
    'APOLLOTYRE.NS', 'MRF.NS', 'CEAT.NS', 'ESCORTS.NS', 'MOTHERSON.NS',
    'GODREJCP.NS', 'MARICO.NS', 'DABUR.NS', 'TATAPOWER.NS', 'ADANIGREEN.NS',
    'ACC.NS', 'AMBUJACEM.NS', 'IDEA.NS', 'BANDHANBNK.NS', 'IDFCFIRSTB.NS',
    'DLF.NS', 'GODREJPROP.NS', 'OBEROIRLTY.NS', 'LTTS.NS', 'MPHASIS.NS',
    'PERSISTENT.NS', 'COFORGE.NS', 'JUBLFOOD.NS', 'TATACOMM.NS', 'DIXON.NS',
    'VOLTAS.NS', 'HAVELLS.NS', 'CROMPTON.NS', 'BATAINDIA.NS', 'PEL.NS',
  ];
  
  // Cache to reduce API calls
  static List<StockMover>? _cachedStocks;
  static DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);
  
  Future<List<StockMover>> fetchTopGainers() async {
    List<StockMover> allStocks = await _fetchAllStocks();
    if (allStocks.isEmpty) return [];
    
    allStocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
    return allStocks.where((s) => s.changePercent > 0).take(15).toList();
  }
  
  Future<List<StockMover>> fetchTopLosers() async {
    List<StockMover> allStocks = await _fetchAllStocks();
    if (allStocks.isEmpty) return [];
    
    allStocks.sort((a, b) => a.changePercent.compareTo(b.changePercent));
    return allStocks.where((s) => s.changePercent < 0).take(15).toList();
  }
  
  Future<List<StockMover>> fetchVolumeBuzzers() async {
    List<StockMover> allStocks = await _fetchAllStocks();
    if (allStocks.isEmpty) return [];
    
    allStocks.sort((a, b) => _parseVolume(b.volume).compareTo(_parseVolume(a.volume)));
    return allStocks.take(15).toList();
  }
  
  Future<List<StockMover>> _fetchAllStocks() async {
    // Check cache first
    if (_cachedStocks != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      print('✅ Returning cached data');
      return _cachedStocks!;
    }
    
    try {
      print('🔄 Fetching real data from Yahoo Finance...');
      
      // Fetch in single batch for speed
      String symbols = nseStocks.join(',');
      final url = Uri.parse('$_yahooFinanceUrl?symbols=$symbols');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['quoteResponse'] == null || data['quoteResponse']['result'] == null) {
          print('❌ Invalid response structure');
          return _cachedStocks ?? [];
        }
        
        final results = data['quoteResponse']['result'] as List;
        print('✅ Received ${results.length} stocks from Yahoo Finance');
        
        List<StockMover> stocks = [];
        
        for (var quote in results) {
          try {
            double? currentPrice = _toDouble(quote['regularMarketPrice']);
            double? previousClose = _toDouble(quote['regularMarketPreviousClose']);
            
            if (currentPrice == null || previousClose == null || 
                currentPrice == 0 || previousClose == 0) {
              continue;
            }
            
            double change = currentPrice - previousClose;
            double changePercent = (change / previousClose) * 100;
            int volume = _toInt(quote['regularMarketVolume']) ?? 0;
            
            stocks.add(StockMover(
              symbol: quote['symbol'].toString().replaceAll('.NS', ''),
              name: quote['shortName']?.toString() ?? 
                    quote['longName']?.toString() ?? 
                    quote['symbol'].toString(),
              price: currentPrice,
              change: change,
              changePercent: changePercent,
              volume: _formatVolume(volume),
              signal: _generateSignal(changePercent),
            ));
          } catch (e) {
            continue;
          }
        }
        
        if (stocks.isNotEmpty) {
          _cachedStocks = stocks;
          _lastFetchTime = DateTime.now();
          print('✅ Successfully parsed ${stocks.length} stocks!');
        }
        
        return stocks;
        
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return _cachedStocks ?? [];
      }
      
    } on SocketException {
      print('❌ No internet connection');
      return _cachedStocks ?? [];
    } on TimeoutException {
      print('❌ Request timeout');
      return _cachedStocks ?? [];
    } catch (e) {
      print('❌ Error: $e');
      return _cachedStocks ?? [];
    }
  }
  
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
