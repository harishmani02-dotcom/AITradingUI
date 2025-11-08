import 'dart:math';

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
  final Random _random = Random();
  
  // Top 200 NSE stocks with real base prices
  static final List<Map<String, dynamic>> stocksDatabase = [
    // NIFTY 50 - Banking
    {'symbol': 'HDFCBANK', 'name': 'HDFC Bank', 'basePrice': 1645.50, 'sector': 'Banking'},
    {'symbol': 'ICICIBANK', 'name': 'ICICI Bank', 'basePrice': 1050.75, 'sector': 'Banking'},
    {'symbol': 'SBIN', 'name': 'State Bank of India', 'basePrice': 625.30, 'sector': 'Banking'},
    {'symbol': 'KOTAKBANK', 'name': 'Kotak Mahindra Bank', 'basePrice': 1780.20, 'sector': 'Banking'},
    {'symbol': 'AXISBANK', 'name': 'Axis Bank', 'basePrice': 1095.40, 'sector': 'Banking'},
    
    // IT Sector
    {'symbol': 'TCS', 'name': 'Tata Consultancy Services', 'basePrice': 3650.80, 'sector': 'IT'},
    {'symbol': 'INFY', 'name': 'Infosys Ltd', 'basePrice': 1505.25, 'sector': 'IT'},
    {'symbol': 'WIPRO', 'name': 'Wipro Ltd', 'basePrice': 445.60, 'sector': 'IT'},
    {'symbol': 'HCLTECH', 'name': 'HCL Technologies', 'basePrice': 1255.90, 'sector': 'IT'},
    {'symbol': 'TECHM', 'name': 'Tech Mahindra', 'basePrice': 1145.30, 'sector': 'IT'},
    
    // Oil & Gas
    {'symbol': 'RELIANCE', 'name': 'Reliance Industries', 'basePrice': 2485.70, 'sector': 'Oil & Gas'},
    {'symbol': 'IOC', 'name': 'Indian Oil Corporation', 'basePrice': 98.45, 'sector': 'Oil & Gas'},
    {'symbol': 'BPCL', 'name': 'Bharat Petroleum', 'basePrice': 342.60, 'sector': 'Oil & Gas'},
    {'symbol': 'ONGC', 'name': 'Oil & Natural Gas Corp', 'basePrice': 185.30, 'sector': 'Oil & Gas'},
    {'symbol': 'HINDPETRO', 'name': 'Hindustan Petroleum', 'basePrice': 325.80, 'sector': 'Oil & Gas'},
    
    // Automobiles
    {'symbol': 'TATAMOTORS', 'name': 'Tata Motors', 'basePrice': 685.20, 'sector': 'Auto'},
    {'symbol': 'MARUTI', 'name': 'Maruti Suzuki', 'basePrice': 10850.50, 'sector': 'Auto'},
    {'symbol': 'M&M', 'name': 'Mahindra & Mahindra', 'basePrice': 1865.40, 'sector': 'Auto'},
    {'symbol': 'BAJAJ-AUTO', 'name': 'Bajaj Auto', 'basePrice': 9250.30, 'sector': 'Auto'},
    {'symbol': 'EICHERMOT', 'name': 'Eicher Motors', 'basePrice': 3650.80, 'sector': 'Auto'},
    
    // Pharma
    {'symbol': 'SUNPHARMA', 'name': 'Sun Pharmaceutical', 'basePrice': 1645.90, 'sector': 'Pharma'},
    {'symbol': 'DRREDDY', 'name': 'Dr Reddy\'s Laboratories', 'basePrice': 5280.40, 'sector': 'Pharma'},
    {'symbol': 'CIPLA', 'name': 'Cipla Ltd', 'basePrice': 1385.60, 'sector': 'Pharma'},
    {'symbol': 'DIVISLAB', 'name': 'Divi\'s Laboratories', 'basePrice': 3650.20, 'sector': 'Pharma'},
    {'symbol': 'BIOCON', 'name': 'Biocon Ltd', 'basePrice': 285.70, 'sector': 'Pharma'},
    
    // Metals & Mining
    {'symbol': 'TATASTEEL', 'name': 'Tata Steel', 'basePrice': 128.50, 'sector': 'Metals'},
    {'symbol': 'JSWSTEEL', 'name': 'JSW Steel', 'basePrice': 785.30, 'sector': 'Metals'},
    {'symbol': 'HINDALCO', 'name': 'Hindalco Industries', 'basePrice': 425.80, 'sector': 'Metals'},
    {'symbol': 'VEDL', 'name': 'Vedanta Ltd', 'basePrice': 305.60, 'sector': 'Metals'},
    {'symbol': 'COALINDIA', 'name': 'Coal India', 'basePrice': 238.90, 'sector': 'Metals'},
    
    // Power & Energy
    {'symbol': 'NTPC', 'name': 'NTPC Ltd', 'basePrice': 285.40, 'sector': 'Power'},
    {'symbol': 'POWERGRID', 'name': 'Power Grid Corporation', 'basePrice': 248.70, 'sector': 'Power'},
    {'symbol': 'TATAPOWER', 'name': 'Tata Power', 'basePrice': 365.20, 'sector': 'Power'},
    {'symbol': 'ADANIPOWER', 'name': 'Adani Power', 'basePrice': 485.60, 'sector': 'Power'},
    {'symbol': 'SUZLON', 'name': 'Suzlon Energy', 'basePrice': 48.35, 'sector': 'Power'},
    
    // FMCG
    {'symbol': 'HINDUNILVR', 'name': 'Hindustan Unilever', 'basePrice': 2485.90, 'sector': 'FMCG'},
    {'symbol': 'ITC', 'name': 'ITC Ltd', 'basePrice': 445.80, 'sector': 'FMCG'},
    {'symbol': 'NESTLEIND', 'name': 'Nestle India', 'basePrice': 24850.60, 'sector': 'FMCG'},
    {'symbol': 'BRITANNIA', 'name': 'Britannia Industries', 'basePrice': 4850.30, 'sector': 'FMCG'},
    {'symbol': 'DABUR', 'name': 'Dabur India', 'basePrice': 525.70, 'sector': 'FMCG'},
    
    // Telecom
    {'symbol': 'BHARTIARTL', 'name': 'Bharti Airtel', 'basePrice': 1285.50, 'sector': 'Telecom'},
    {'symbol': 'IDEA', 'name': 'Vodafone Idea', 'basePrice': 9.85, 'sector': 'Telecom'},
    
    // Infrastructure
    {'symbol': 'LT', 'name': 'Larsen & Toubro', 'basePrice': 3485.90, 'sector': 'Infrastructure'},
    {'symbol': 'ADANIPORTS', 'name': 'Adani Ports', 'basePrice': 1285.40, 'sector': 'Infrastructure'},
    {'symbol': 'GRASIM', 'name': 'Grasim Industries', 'basePrice': 2485.60, 'sector': 'Infrastructure'},
    
    // Cement
    {'symbol': 'ULTRACEMCO', 'name': 'UltraTech Cement', 'basePrice': 9850.30, 'sector': 'Cement'},
    {'symbol': 'SHREECEM', 'name': 'Shree Cement', 'basePrice': 27850.70, 'sector': 'Cement'},
    {'symbol': 'ACC', 'name': 'ACC Ltd', 'basePrice': 2185.40, 'sector': 'Cement'},
    
    // Finance
    {'symbol': 'BAJFINANCE', 'name': 'Bajaj Finance', 'basePrice': 6850.90, 'sector': 'Finance'},
    {'symbol': 'BAJAJFINSV', 'name': 'Bajaj Finserv', 'basePrice': 1685.30, 'sector': 'Finance'},
    {'symbol': 'SBILIFE', 'name': 'SBI Life Insurance', 'basePrice': 1485.60, 'sector': 'Finance'},
    
    // Consumer Goods
    {'symbol': 'TITAN', 'name': 'Titan Company', 'basePrice': 3250.80, 'sector': 'Consumer'},
    {'symbol': 'ASIANPAINT', 'name': 'Asian Paints', 'basePrice': 2885.40, 'sector': 'Consumer'},
    
    // More High Volume Stocks
    {'symbol': 'YESBANK', 'name': 'Yes Bank', 'basePrice': 18.65, 'sector': 'Banking'},
    {'symbol': 'BANKBARODA', 'name': 'Bank of Baroda', 'basePrice': 195.80, 'sector': 'Banking'},
    {'symbol': 'PNB', 'name': 'Punjab National Bank', 'basePrice': 98.45, 'sector': 'Banking'},
    {'symbol': 'UNIONBANK', 'name': 'Union Bank of India', 'basePrice': 115.30, 'sector': 'Banking'},
    {'symbol': 'CANBK', 'name': 'Canara Bank', 'basePrice': 105.60, 'sector': 'Banking'},
    
    // Add 140+ more stocks for total 200...
    {'symbol': 'SAIL', 'name': 'Steel Authority of India', 'basePrice': 118.40, 'sector': 'Metals'},
    {'symbol': 'NMDC', 'name': 'NMDC Ltd', 'basePrice': 185.70, 'sector': 'Metals'},
    {'symbol': 'JINDALSTEL', 'name': 'Jindal Steel & Power', 'basePrice': 885.30, 'sector': 'Metals'},
    {'symbol': 'GAIL', 'name': 'GAIL India', 'basePrice': 195.60, 'sector': 'Oil & Gas'},
    {'symbol': 'PETRONET', 'name': 'Petronet LNG', 'basePrice': 285.90, 'sector': 'Oil & Gas'},
    {'symbol': 'INDUSINDBK', 'name': 'IndusInd Bank', 'basePrice': 985.40, 'sector': 'Banking'},
    {'symbol': 'FEDERALBNK', 'name': 'Federal Bank', 'basePrice': 145.80, 'sector': 'Banking'},
    {'symbol': 'RBLBANK', 'name': 'RBL Bank', 'basePrice': 185.30, 'sector': 'Banking'},
    {'symbol': 'LUPIN', 'name': 'Lupin Ltd', 'basePrice': 1685.50, 'sector': 'Pharma'},
    {'symbol': 'AUROPHARMA', 'name': 'Aurobindo Pharma', 'basePrice': 1285.70, 'sector': 'Pharma'},
    {'symbol': 'HEROMOTOCO', 'name': 'Hero MotoCorp', 'basePrice': 4850.20, 'sector': 'Auto'},
    {'symbol': 'APOLLOTYRE', 'name': 'Apollo Tyres', 'basePrice': 485.60, 'sector': 'Auto'},
    {'symbol': 'MRF', 'name': 'MRF Ltd', 'basePrice': 128500.30, 'sector': 'Auto'},
    {'symbol': 'TATACONSUM', 'name': 'Tata Consumer Products', 'basePrice': 985.40, 'sector': 'FMCG'},
    {'symbol': 'MARICO', 'name': 'Marico Ltd', 'basePrice': 585.70, 'sector': 'FMCG'},
    {'symbol': 'GODREJCP', 'name': 'Godrej Consumer Products', 'basePrice': 1185.30, 'sector': 'FMCG'},
  ];
  
  /// Fetch Top Gainers
  Future<List<StockMover>> fetchTopGainers() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    List<StockMover> allStocks = _generateLiveStocks();
    allStocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
    
    return allStocks
        .where((stock) => stock.changePercent > 0)
        .take(15)
        .toList();
  }
  
  /// Fetch Top Losers
  Future<List<StockMover>> fetchTopLosers() async {
    await Future.delayed(const Duration(seconds: 2));
    
    List<StockMover> allStocks = _generateLiveStocks();
    allStocks.sort((a, b) => a.changePercent.compareTo(b.changePercent));
    
    return allStocks
        .where((stock) => stock.changePercent < 0)
        .take(15)
        .toList();
  }
  
  /// Fetch Volume Buzzers
  Future<List<StockMover>> fetchVolumeBuzzers() async {
    await Future.delayed(const Duration(seconds: 2));
    
    List<StockMover> allStocks = _generateLiveStocks();
    allStocks.sort((a, b) => _parseVolume(b.volume).compareTo(_parseVolume(a.volume)));
    
    return allStocks.take(15).toList();
  }
  
  /// Generate realistic stock movements
  List<StockMover> _generateLiveStocks() {
    List<StockMover> stocks = [];
    
    for (var stock in stocksDatabase) {
      double basePrice = stock['basePrice'];
      
      // Generate realistic price movements (-5% to +5%)
      // Most stocks move between -2% to +2% (normal distribution)
      double changePercent = _generateRealisticChange();
      double change = (basePrice * changePercent) / 100;
      double currentPrice = basePrice + change;
      
      // Generate realistic volume based on stock price
      int volumeBase = _generateVolume(basePrice);
      
      stocks.add(StockMover(
        symbol: stock['symbol'],
        name: stock['name'],
        price: currentPrice,
        change: change,
        changePercent: changePercent,
        volume: _formatVolume(volumeBase),
        signal: _generateSignal(changePercent),
      ));
    }
    
    return stocks;
  }
  
  /// Generate realistic price change (normal distribution)
  double _generateRealisticChange() {
    // 70% of stocks move between -1% to +1%
    // 20% move between -3% to -1% or +1% to +3%
    // 10% move between -5% to -3% or +3% to +5%
    
    double rand = _random.nextDouble();
    
    if (rand < 0.70) {
      // Normal movement: -1% to +1%
      return (_random.nextDouble() * 2) - 1;
    } else if (rand < 0.90) {
      // Moderate movement: -3% to +3%
      return (_random.nextDouble() * 6) - 3;
    } else {
      // High movement: -5% to +5%
      return (_random.nextDouble() * 10) - 5;
    }
  }
  
  /// Generate volume based on price (lower price = higher volume)
  int _generateVolume(double price) {
    if (price < 50) {
      return _random.nextInt(100000000) + 50000000; // 50M - 150M
    } else if (price < 500) {
      return _random.nextInt(20000000) + 5000000; // 5M - 25M
    } else if (price < 2000) {
      return _random.nextInt(5000000) + 1000000; // 1M - 6M
    } else {
      return _random.nextInt(1000000) + 500000; // 500K - 1.5M
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
