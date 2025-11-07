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
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Fetch real-time data
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
            _errorMessage = 'No data available. Pull to refresh.';
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
        return const Color(0xFF6B7280);
    }
  }

  IconData _getSignalIcon(String signal) {
    switch (signal) {
      case 'Buy':
        return Icons.arrow_upward;
      case 'Sell':
        return Icons.arrow_downward;
      default:
        return Icons.horizontal_rule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Top Movers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        actions: [
          // Live indicator
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
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
        child: Column(
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFDBEAFE),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF1E40AF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getInfoText(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                  if (_lastUpdated != null)
                    Text(
                      _getTimeAgo(_lastUpdated!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1E40AF),
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
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
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
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading real-time data...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
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
        return _buildMoverCard(movers[index], index + 1, isGainer);
      },
    );
  }

  Widget _buildMoverCard(StockMover mover, int rank, bool? isGainer) {
    final isPositive = mover.changePercent > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? (isGainer == true
                        ? const Color(0xFF10B981)
                        : isGainer == false
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF7C3AED))
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Stock Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mover.symbol,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mover.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Vol: ${mover.volume}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price & Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${mover.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${isPositive ? '+' : ''}${mover.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getSignalColor(mover.signal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getSignalColor(mover.signal).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSignalIcon(mover.signal),
                        size: 10,
                        color: _getSignalColor(mover.signal),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        mover.signal,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getSignalColor(mover.signal),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
