import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/signals_provider.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSignals();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSignals();
    }
  }

  Future<void> _loadSignals() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final signalsProvider = Provider.of<SignalsProvider>(context, listen: false);
    final isPremium = authProvider.userProfile?.isSubscriptionActive ?? false;
    await signalsProvider.fetchTodaySignals(isPremium: isPremium);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toUpperCase();
      _selectedFilter = null;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _filterBySignal(String? signalType) {
    setState(() {
      _selectedFilter = _selectedFilter == signalType ? null : signalType;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _handleSignalAction(String symbol, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action signal for $symbol'),
        backgroundColor: action == 'BUY' 
            ? const Color(0xFF10B981) 
            : action == 'SELL' 
                ? const Color(0xFFEF4444) 
                : const Color(0xFF6B7280),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final signalsProvider = Provider.of<SignalsProvider>(context);
    final isPremium = authProvider.userProfile?.isSubscriptionActive ?? false;

    List<dynamic> filteredSignals = signalsProvider.signals;

    if (_searchQuery.isNotEmpty) {
      filteredSignals = filteredSignals
          .where((signal) => signal.symbol.toUpperCase().contains(_searchQuery))
          .toList();
    }

    if (_selectedFilter != null) {
      filteredSignals = filteredSignals
          .where((signal) => signal.signal.toUpperCase() == _selectedFilter)
          .toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Today's Signals",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Live AI-powered insights",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE0E7FF),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle_rounded,
                  color: Colors.white, size: 30),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSignals,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF059669).withOpacity(0.1),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'Premium Active ✨' : 'Live Signals',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Updated daily at 6 PM IST',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search stocks (e.g., RELIANCE, TCS)',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1E40AF)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            if (signalsProvider.signals.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInteractiveStatCard(
                        'Buy',
                        signalsProvider.buySignalsCount.toString(),
                        const Color(0xFF10B981),
                        Icons.arrow_upward_rounded,
                        () => _filterBySignal('BUY'),
                        _selectedFilter == 'BUY',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInteractiveStatCard(
                        'Sell',
                        signalsProvider.sellSignalsCount.toString(),
                        const Color(0xFFEF4444),
                        Icons.arrow_downward_rounded,
                        () => _filterBySignal('SELL'),
                        _selectedFilter == 'SELL',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInteractiveStatCard(
                        'Hold',
                        signalsProvider.holdSignalsCount.toString(),
                        const Color(0xFF6B7280),
                        Icons.remove_rounded,
                        () => _filterBySignal('HOLD'),
                        _selectedFilter == 'HOLD',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedFilter != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getFilterColor(_selectedFilter!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getFilterColor(_selectedFilter!).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: _getFilterColor(_selectedFilter!),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Showing $_selectedFilter signals',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getFilterColor(_selectedFilter!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _filterBySignal(null),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: _getFilterColor(_selectedFilter!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Expanded(
              child: signalsProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSignals.isEmpty
                      ? _buildEmptyState(_searchQuery.isNotEmpty || _selectedFilter != null)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredSignals.length,
                          itemBuilder: (context, index) {
                            final signal = filteredSignals[index];
                            return EnhancedSignalCard(
                              signal: signal,
                              showDetails: isPremium,
                              onAction: _handleSignalAction,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),

      floatingActionButton: !isPremium
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF7C3AED),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text(
                'Unlock Premium',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'BUY':
        return const Color(0xFF10B981);
      case 'SELL':
        return const Color(0xFFEF4444);
      case 'HOLD':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  Widget _buildInteractiveStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off : Icons.info_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No signals found' : 'No signals available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered ? 'Try a different filter or search' : 'Pull down to refresh',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _clearSearch();
                _filterBySignal(null);
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EnhancedSignalCard extends StatelessWidget {
  final dynamic signal;
  final bool showDetails;
  final Function(String, String) onAction;

  const EnhancedSignalCard({
    super.key,
    required this.signal,
    required this.showDetails,
    required this.onAction,
  });

  Color _getSignalColor(String signalType) {
    switch (signalType.toUpperCase()) {
      case 'BUY':
        return const Color(0xFF10B981);
      case 'SELL':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getSymbol() {
    try {
      return signal.symbol?.toString() ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getPrice() {
    try {
      final price = signal.currentPrice ?? signal.price ?? 0.0;
      return '₹${price.toStringAsFixed(2)}';
    } catch (e) {
      return '₹0.00';
    }
  }

  String _getSignal() {
    try {
      return signal.signal?.toString() ?? 'HOLD';
    } catch (e) {
      return 'HOLD';
    }
  }

  double _getConfidence() {
    try {
      return signal.confidence?.toDouble() ?? 50.0;
    } catch (e) {
      return 50.0;
    }
  }

  String _getRSI() {
    try {
      return signal.rsi?.toStringAsFixed(1) ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String? _getVotes() {
    try {
      return signal.votes?.toString();
    } catch (e) {
      return null;
    }
  }

  List<FlSpot> _generateMockData() {
    return List.generate(7, (i) => FlSpot(i.toDouble(), 40 + (i * 5) + (i % 2 * 10)));
  }

  @override
  Widget build(BuildContext context) {
    final signalColor = _getSignalColor(_getSignal());
    final symbol = _getSymbol();
    final price = _getPrice();
    final signalText = _getSignal();
    final confidence = _getConfidence();
    final rsi = _getRSI();
    final votes = _getVotes();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: signalColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: signalColor, width: 2),
                  ),
                  child: Text(
                    signalText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: signalColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateMockData(),
                    isCurved: true,
                    color: signalColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: signalColor.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),

          if (showDetails)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Confidence:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: confidence / 100,
                            backgroundColor: Colors.grey[200],
                            color: signalColor,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${confidence.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: signalColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analysis Factors:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'RSI: $rsi',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (votes != null)
                          Text(
                            'Votes: $votes',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onAction(symbol, 'BUY'),
                    icon: const Icon(Icons.trending_up, size: 14),
                    label: const Text('Buy', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onAction(symbol, 'HOLD'),
                    icon: const Icon(Icons.remove, size: 14),
                    label: const Text('Hold', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7280),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onAction(symbol, 'SELL'),
                    icon: const Icon(Icons.trending_down, size: 14),
                    label: const Text('Sell', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
