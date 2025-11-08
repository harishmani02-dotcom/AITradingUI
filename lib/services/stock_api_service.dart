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
  // Yahoo Finance API endpoints
  static const String _quoteUrl = 'https://query1.finance.yahoo.com/v7/finance/quote';
  
  // Top 200 NSE stocks (NIFTY 200 constituents)
  static final List<String> top200Symbols = [
    // NIFTY 50
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
    
    // NIFTY NEXT 50
    'ADANIGREEN.NS', 'ACC.NS', 'AMBUJACEM.NS', 'BANDHANBNK.NS', 'BERGEPAINT.NS',
    'BEL.NS', 'CANBK.NS', 'CHOLAFIN.NS', 'COLPAL.NS', 'DLF.NS',
    'DABUR.NS', 'DMART.NS', 'GAIL.NS', 'GODREJCP.NS', 'GLAND.NS',
    'HAVELLS.NS', 'HDFCAMC.NS', 'HDFCLIFE.NS', 'HINDPETRO.NS', 'ICICIPRULI.NS',
    'IDEA.NS', 'IPCALAB.NS', 'IRCTC.NS', 'IGL.NS', 'JINDALSTEL.NS',
    'LTI.NS', 'LICHSGFIN.NS', 'MCDOWELL-N.NS', 'MARICO.NS', 'MUTHOOTFIN.NS',
    'NMDC.NS', 'NAUKRI.NS', 'OFSS.NS', 'PAGEIND.NS', 'PETRONET.NS',
    'PIIND.NS', 'PFC.NS', 'PGHH.NS', 'RAMCOCEM.NS', 'RECLTD.NS',
    'SRF.NS', 'SBICARD.NS', 'SIEMENS.NS', 'TATAPOWER.NS', 'TORNTPHARM.NS',
    'TRENT.NS', 'MPHASIS.NS', 'VEDL.NS', 'VOLTAS.NS', 'ZEEL.NS',
    
    // Additional High Volume Stocks (Next 100)
    'YESBANK.NS', 'BANKBARODA.NS', 'BANKINDIA.NS', 'PNB.NS', 'UNIONBANK.NS',
    'SUZLON.NS', 'SAIL.NS', 'RPOWER.NS', 'AUROPHARMA.NS', 'BIOCON.NS',
    'CADILAHC.NS', 'LUPIN.NS', 'ALKEM.NS', 'GODREJPROP.NS', 'OBEROIRLTY.NS',
    'PRESTIGE.NS', 'PHOENIXLTD.NS', 'BRIGADE.NS', 'ASHOKLEY.NS', 'ESCORTS.NS',
    'MOTHERSON.NS', 'EXIDEIND.NS', 'APOLLOTYRE.NS', 'MRF.NS', 'CEAT.NS',
    'BALKRISIND.NS', 'AMARAJABAT.NS', 'BOSCHLTD.NS', 'BHEL.NS', 'ABB.NS',
    'CROMPTON.NS', 'FEDERALBNK.NS', 'IDFCFIRSTB.NS', 'RBLBANK.NS', 'EQUITAS.NS',
    'AUBANK.NS', 'JUBLFOOD.NS', 'TATACOMM.NS', 'MFSL.NS', 'LTTS.NS',
    'COFORGE.NS', 'PERSISTENT.NS', 'MINDTREE.NS', 'L&TFH.NS', 'PEL.NS',
    'WHIRLPOOL.NS', 'BATAINDIA.NS', 'TATAELXSI.NS', 'ABCAPITAL.NS', 'AARTIIND.NS',
    'ATUL.NS', 'BALRAMCHIN.NS', 'DEEPAKNTR.NS', 'GNFC.NS', 'GUJGASLTD.NS',
    'INDHOTEL.NS', 'INDUSTOWER.NS', 'IRFC.NS', 'JKCEMENT.NS', 'JSWENERGY.NS',
    'KAJARIACER.NS', 'KEI.NS', 'CONCOR.NS', 'ABFRL.NS', 'APLAPOLLO.NS',
    'ASTRAL.NS', 'CUMMINSIND.NS', 'DIXON.NS', 'EMAMILTD.NS', 'ENDURANCE.NS',
    'FORTIS.NS', 'GLENMARK.NS', 'GMRINFRA.NS', 'GODREJIND.NS', 'GRAPHITE.NS',
    'HATSUN.NS', 'IBREALEST.NS', 'ICICIGI.NS', 'IDFC.NS', 'INOXLEISUR.NS',
    'IOB.NS', 'IRCON.NS', 'JBCHEPHARM.NS', 'JKLAKSHMI.NS', 'KANSAINER.NS',
    'KPITTECH.NS', 'LALPATHLAB.NS', 'LINDEINDIA.NS', 'MANAPPURAM.NS', 'MAXHEALTH.NS',
    'METROBRAND.NS', 'NATCOPHARM.NS', 'NATIONALUM.NS', 'NBCC.NS', 'NESCO.NS',
    'NETWORK18.NS', 'NFL.NS', 'ORIENTELEC.NS', 'PAGEIND.NS', 'POLICYBZR.NS',
  ];
  
  /// Main method: Fetch Top Gainers
  Future<List<StockMover>> fetchTopGainers() async {
    List<StockMover> allStocks = await _fetchAllStocksBatch();
    
    if (allStocks.isEmpty) {
      print('⚠️ No data fetched from Yahoo Finance');
      return [];
    }
    
    print('✅ Analyzing ${allStocks.length} stocks for top gainers...');
    
    // Filter only positive movers and sort
    allStocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
    
    return allStocks
        .where((stock) => stock.changePercent > 0)
        .take(15)
        .toList();
  }
  
  /// Main method: Fetch Top Losers
  Future<List<StockMover>> fetchTopLosers() async {
    List<StockMover> allStocks = await _fetchAllStocksBatch();
    
    if (allStocks.isEmpty) {
      print('⚠️ No data fetched from Yahoo Finance');
      return [];
    }
    
    print('✅ Analyzing ${allStocks.length} stocks for top losers...');
    
    // Filter only negative movers and sort
    allStocks.sort((a, b) => a.changePercent.compareTo(b.changePercent));
    
    return allStocks
        .where((stock) => stock.changePercent < 0)
        .take(15)
        .toList();
  }
  
  /// Main method: Fetch Volume Buzzers
  Future<List<StockMover>> fetchVolumeBuzzers() async {
    List<StockMover> allStocks = await _fetchAllStocksBatch();
    
    if (allStocks.isEmpty) {
      print('⚠️ No data fetched from Yahoo Finance');
      return [];
    }
    
    print('✅ Analyzing ${allStocks.length} stocks for volume buzzers...');
    
    // Sort by volume
    allStocks.sort((a, b) => 
      _parseVolume(b.volume).compareTo(_parseVolume(a.volume))
    );
    
    return allStocks.take(15).toList();
  }
  
  /// Core API call - Fetches all 200 stocks in batches
  Future<List<StockMover>> _fetchAllStocksBatch() async {
    try {
      // Yahoo Finance allows up to 100 symbols per request
      // So we'll split into multiple batches
      List<StockMover> allStocks = [];
      
      int batchSize = 100;
      int totalBatches = (top200Symbols.length / batchSize).ceil();
      
      print('🔄 Fetching ${top200Symbols.length} stocks in $totalBatches batches...');
      
      for (int i = 0; i < totalBatches; i++) {
        int start = i * batchSize;
        int end = (start + batchSize > top200Symbols.length) 
            ? top200Symbols.length 
            : start + batchSize;
        
        List<String> batchSymbols = top200Symbols.sublist(start, end);
        
        print('📦 Fetching batch ${i + 1}/$totalBatches (${batchSymbols.length} stocks)...');
        
        List<StockMover> batchStocks = await _fetchBatch(batchSymbols);
        allStocks.addAll(batchStocks);
        
        // Small delay between batches to be respectful to API
        if (i < totalBatches - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      print('✅ Successfully fetched ${allStocks.length} stocks!');
      return allStocks;
      
    } catch (e) {
      print('❌ Error fetching stocks: $e');
      return [];
    }
  }
  
  /// Fetch a single batch of stocks
  Future<List<StockMover>> _fetchBatch(List<String> symbols) async {
    try {
      String symbolsParam = symbols.join(',');
      
      final url = Uri.parse('$_quoteUrl?symbols=$symbolsParam');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timeout'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if response has valid structure
        if (data['quoteResponse'] == null || data['quoteResponse']['result'] == null) {
          print('⚠️ Invalid API response structure');
          return [];
        }
        
        final results = data['quoteResponse']['result'] as List;
        
        List<StockMover> stocks = [];
        
        for (var quote in results) {
          try {
            // Extract data with null safety
            double? currentPrice = _toDouble(quote['regularMarketPrice']);
            double? previousClose = _toDouble(quote['regularMarketPreviousClose']);
            
            // Skip if essential data is missing
            if (currentPrice == null || previousClose == null || 
                currentPrice == 0 || previousClose == 0) {
              continue;
            }
            
            double change = currentPrice - previousClose;
            double changePercent = (change / previousClose) * 100;
            
            int volume = _toInt(quote['regularMarketVolume']) ?? 0;
            String symbol = quote['symbol']?.toString() ?? '';
            String name = quote['shortName']?.toString() ?? 
                         quote['longName']?.toString() ?? 
                         symbol;
            
            // Clean up symbol (remove .NS)
            symbol = symbol.replaceAll('.NS', '');
            
            // Create stock object
            stocks.add(StockMover(
              symbol: symbol,
              name: name,
              price: currentPrice,
              change: change,
              changePercent: changePercent,
              volume: _formatVolume(volume),
              signal: _generateSignal(changePercent),
            ));
            
          } catch (e) {
            // Skip problematic stocks silently
            continue;
          }
        }
        
        return stocks;
        
      } else if (response.statusCode == 429) {
        print('⚠️ Rate limited - waiting before retry...');
        await Future.delayed(const Duration(seconds: 2));
        return [];
      } else {
        print('❌ API returned status ${response.statusCode}');
        return [];
      }
      
    } on SocketException {
      print('❌ No internet connection');
      return [];
    } on TimeoutException {
      print('❌ Request timed out');
      return [];
    } catch (e) {
      print('❌ Error in batch fetch: $e');
      return [];
    }
  }
  
  /// Helper: Safely convert to double
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// Helper: Safely convert to int
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  /// Generate trading signal based on price change
  String _generateSignal(double changePercent) {
    if (changePercent > 2.0) return 'Buy';
    if (changePercent < -2.0) return 'Sell';
    return 'Hold';
  }
  
  /// Format volume to human-readable string
  String _formatVolume(int volume) {
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(1)}Cr';
    } else if (volume >= 100000) {
      return '${(volume / 100000).toStringAsFixed(1)}L';
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
    
    if (volume.contains('Cr')) return num * 10000000;
    if (volume.contains('L')) return num * 100000;
    if (volume.contains('M')) return num * 1000000;
    if (volume.contains('K')) return num * 1000;
    return num;
  }
}
