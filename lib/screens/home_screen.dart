import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/signals_provider.dart';
import '../widgets/signal_card.dart';
import 'news_screen.dart';
import 'movers_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'ai_chat_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSignals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Navigate to different screens
    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewsScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MoversScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AlertsScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final signalsProvider = Provider.of<SignalsProvider>(context);
    final isPremium = authProvider.userProfile?.isSubscriptionActive ?? false;

    final filteredSignals = _searchQuery.isEmpty
        ? signalsProvider.signals
        : signalsProvider.signals
            .where((signal) => signal.symbol.toUpperCase().contains(_searchQuery))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Today's Signals",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSignals,
        child: Column(
          children: [
            // AI Trend Radar Widget (Top Banner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.radar,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Trend Radar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPremium
                              ? 'Market is Bullish 🔥'
                              : 'Upgrade for AI Insights',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPremium)
                    const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 24,
                    ),
                ],
              ),
            ),

            // Premium Status Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
              ),
              child: Row(
                children: [
                  Icon(
                    isPremium ? Icons.workspace_premium : Icons.trending_up,
                    color: isPremium ? const Color(0xFF7C3AED) : const Color(0xFF10B981),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'Premium Active ✨' : 'Live AI Signals',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const Text(
                          'Updated daily at 6 PM IST',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
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
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search stocks (e.g., RELIANCE, TCS, INFY)',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF1E40AF),
                  ),
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

            // Search Results Info
            if (_searchQuery.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Found ${filteredSignals.length} result${filteredSignals.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Summary Stats
            if (signalsProvider.signals.isNotEmpty && _searchQuery.isEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '🟢 Buy',
                      signalsProvider.buySignalsCount.toString(),
                      const Color(0xFF10B981),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStatItem(
                      '🔴 Sell',
                      signalsProvider.sellSignalsCount.toString(),
                      const Color(0xFFEF4444),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStatItem(
                      '⚪ Hold',
                      signalsProvider.holdSignalsCount.toString(),
                      const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Signals List
            Expanded(
              child: signalsProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSignals.isEmpty
                      ? _buildEmptyState(_searchQuery.isNotEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: filteredSignals.length,
                          itemBuilder: (context, index) {
                            final signal = filteredSignals[index];
                            return SignalCard(
                              signal: signal,
                              showDetails: isPremium,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AIChatScreen()),
          );
        },
        backgroundColor: const Color(0xFF7C3AED),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E40AF),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Movers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.info_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'No signals found for "$_searchQuery"'
                : 'No signals available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try searching for another stock'
                : 'Signals update daily at 6 PM IST',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (isSearching) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

