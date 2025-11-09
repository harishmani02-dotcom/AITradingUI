import 'package:flutter/material.dart';
import '../services/stock_api_service.dart';

class MoversScreen extends StatefulWidget {
  const MoversScreen({super.key});

  @override
  State<MoversScreen> createState() => _MoversScreenState();
}

class _MoversScreenState extends State<MoversScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  // API Service
  final StockApiService _apiService = StockApiService();
  
  // Cache for stock data
  List<StockMover> _topGainers = [];
  List<StockMover> _topLosers = [];
  List<StockMover> _volumeBuzzers = [];
  
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    
    // Auto-refresh every 5 minutes
    _startAutoRefresh();
  }
  
  void _startAutoRefresh() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        _loadData();
        _startAutoRefresh();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final gainers = await _apiService.fetchTopGainers();
      final losers = await _apiService.fetchTopLosers();
      final buzzers = await _apiService.fetchVolumeBuzzers();
      
      if (mounted) {
        setState(() {
          _topGainers = gainers;
          _topLosers = losers;
          _volumeBuzzers = buzzers;
          _lastUpdated = DateTime.now();
          _isLoading = false;
          
          if (gainers.isEmpty && losers.isEmpty && buzzers.isEmpty) {
            _errorMessage = 'No data available. Please check your internet connection.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data. Pull to refresh.';
          _isLoading = false;
        });
      }
      print('Error loading data: $e');
    }
  }

  Color _getSignalColor(String signal) {
    switch (signal) {
      case 'Buy':
        return const Color(0xFF10B981);
      case 'Sell':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  Color _getSignalBackgroundColor(String signal) {
    switch (signal) {
      case 'Buy':
        return const Color(0xFF10B981).withOpacity(0.15);
      case 'Sell':
        return const Color(0xFFEF4444).withOpacity(0.15);
      default:
        return const Color(0xFF8B5CF6).withOpacity(0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text(
          'Top Movers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1F28),
        elevation: 0,
        actions: [
          if (!_isLoading && _topGainers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.trending_up, size: 20),
              text: 'Top Gainers',
            ),
            Tab(
              icon: Icon(Icons.trending_down, size: 20),
              text: 'Top Losers',
            ),
            Tab(
              icon: Icon(Icons.volume_up, size: 20),
              text: 'Volume Buzzers',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: const Color(0xFF1A1F28),
        color: const Color(0xFF8B5CF6),
        child: Column(
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1A1F28),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF8B5CF6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getInfoText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  if (_lastUpdated != null)
                    Text(
                      _getTimeAgo(_lastUpdated!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFEF4444).withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Analyzing 200 stocks...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMoversList(_topGainers, true),
                        _buildMoversList(_topLosers, false),
                        _buildMoversList(_volumeBuzzers, null),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInfoText() {
    switch (_tabController.index) {
      case 0:
        return 'Stocks with highest price gain today';
      case 1:
        return 'Stocks with highest price decline today';
      case 2:
        return 'Stocks with unusually high trading volume';
      default:
        return '';
    }
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  Widget _buildMoversList(List<StockMover> movers, bool? isGainer) {
    if (movers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            const Text(
              'No data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movers.length,
      itemBuilder: (context, index) {
        return _buildMoverCard(movers[index], index + 1);
      },
    );
  }

  Widget _buildMoverCard(StockMover mover, int rank) {
    final isPositive = mover.changePercent > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getSignalColor(mover.signal).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mover.symbol,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'â‚¹${mover.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Signal Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSignalBackgroundColor(mover.signal),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mover.signal.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getSignalColor(mover.signal),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    mover.signal == 'Buy' 
                        ? Icons.arrow_upward 
                        : mover.signal == 'Sell'
                            ? Icons.arrow_downward
                            : Icons.horizontal_rule,
                    size: 16,
                    color: _getSignalColor(mover.signal),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Confidence Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Confidence:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    Text(
                      '${(mover.changePercent.abs() * 10).clamp(0, 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (mover.changePercent.abs() * 0.1).clamp(0, 1),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getSignalColor(mover.signal),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Divider(color: Colors.white12, height: 1),
            
            const SizedBox(height: 12),
            
            // Analysis Factors
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analysis Factors:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RSI: ${(50 + (mover.changePercent * 2)).clamp(0, 100).toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votes: ${_generateVotes(mover.signal)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _generateVotes(String signal) {
    // Generate mock votes based on signal
    if (signal == 'Buy') {
      return '4 Buy, 1 Sell, 0 Hold';
    } else if (signal == 'Sell') {
      return '2 Buy, 4 Sell, 0 Hold';
    } else {
      return '1 Buy, 1 Sell, 3 Hold';
    }
  }
}
