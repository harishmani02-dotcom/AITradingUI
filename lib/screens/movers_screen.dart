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

  Color _getHeaderColor() {
    switch (_tabController.index) {
      case 0:
        return const Color(0xFF10B981); // Green for gainers
      case 1:
        return const Color(0xFFEF4444); // Red for losers
      case 2:
        return const Color(0xFF3B82F6); // Blue for volume
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getHeaderIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.trending_up;
      case 1:
        return Icons.trending_down;
      case 2:
        return Icons.bar_chart;
      default:
        return Icons.show_chart;
    }
  }

  String _getHeaderTitle() {
    switch (_tabController.index) {
      case 0:
        return 'Top gainers';
      case 1:
        return 'Top losers';
      case 2:
        return 'Volume shockers';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text(
          'Screeners',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1A1F28),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onTap: (index) {
            setState(() {}); // Refresh to update header color
          },
          tabs: const [
            Tab(text: 'Top gainers'),
            Tab(text: 'Top losers'),
            Tab(text: 'Volume shockers'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Colored Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getHeaderColor(),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getHeaderTitle(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getCurrentList().length} stocks',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _getHeaderIcon(),
                      color: Colors.white,
                      size: 48,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info Box
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getInfoText(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),

          // Stock List Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1A1F28),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Stock List
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
                : RefreshIndicator(
                    onRefresh: _loadData,
                    backgroundColor: const Color(0xFF1A1F28),
                    color: const Color(0xFF8B5CF6),
                    child: _buildStockList(),
                  ),
          ),

          // Subscribe Button
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F1419),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Subscribe to PRO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<StockMover> _getCurrentList() {
    switch (_tabController.index) {
      case 0:
        return _topGainers;
      case 1:
        return _topLosers;
      case 2:
        return _volumeBuzzers;
      default:
        return [];
    }
  }

  String _getInfoText() {
    switch (_tabController.index) {
      case 0:
        return 'Stocks which have gained the most today';
      case 1:
        return 'Stocks which have lost the most today';
      case 2:
        return 'Stocks where the trading volume is atleast 5 times more than the volume of the last trading day';
      default:
        return '';
    }
  }

  Widget _buildStockList() {
    final stocks = _getCurrentList();
    
    if (stocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: stocks.length,
      separatorBuilder: (context, index) => const Divider(
        color: Color(0xFF2D3748),
        height: 1,
        thickness: 1,
      ),
      itemBuilder: (context, index) {
        return _buildStockItem(stocks[index]);
      },
    );
  }

  Widget _buildStockItem(StockMover stock) {
    final isPositive = stock.changePercent > 0;
    final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      color: const Color(0xFF0F1419),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Stock Logo/Initial
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2D3748),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                stock.symbol.substring(0, 1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                  stock.symbol,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stock.name.length > 25 
                      ? '${stock.name.substring(0, 25)}...' 
                      : stock.name,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Price and Change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${stock.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: changeColor,
                ),
              ),
            ],
          ),

          // Bookmark Icon
          const SizedBox(width: 12),
          const Icon(
            Icons.bookmark_border,
            color: Colors.white54,
            size: 24,
          ),
        ],
      ),
    );
  }
}
