import 'package:flutter/material.dart';

class MoversScreen extends StatefulWidget {
  const MoversScreen({super.key});

  @override
  State<MoversScreen> createState() => _MoversScreenState();
}

class _MoversScreenState extends State<MoversScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  List<StockMover> _getTopGainers() {
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

  List<StockMover> _getTopLosers() {
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

  List<StockMover> _getVolumeBuzzers() {
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
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMoversList(_getTopGainers(), true),
                        _buildMoversList(_getTopLosers(), false),
                        _buildMoversList(_getVolumeBuzzers(), null),
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

  Widget _buildMoversList(List<StockMover> movers, bool? isGainer) {
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
