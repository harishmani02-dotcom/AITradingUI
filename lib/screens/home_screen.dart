import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isRefreshingSubscription = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _refreshSubscriptionStatus();
    await _loadSignals();
  }

  Future<void> _refreshSubscriptionStatus() async {
    if (_isRefreshingSubscription) return;

    setState(() => _isRefreshingSubscription = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        debugPrint('⚠️ No authenticated user');
        setState(() => _isRefreshingSubscription = false);
        return;
      }

      debugPrint('🔄 Refreshing subscription status for user: ${user.id}');

      final response = await Supabase.instance.client
          .from('app_users')
          .select('subscription_status, subscription_end, email')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        final isSubscribed = response['subscription_status'] ?? false;
        final subscriptionEnd = response['subscription_end'];

        debugPrint('✅ Subscription status loaded: $isSubscribed');
        if (subscriptionEnd != null) {
          debugPrint('📅 Subscription ends: $subscriptionEnd');
        }

        await authProvider.refreshUserProfile();

        if (isSubscribed && mounted) {
          _showPremiumWelcome();
        }
      } else {
        debugPrint('📝 Creating user record in app_users...');
        await Supabase.instance.client.from('app_users').insert({
          'user_id': user.id,
          'email': user.email,
          'subscription_status': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        await authProvider.refreshUserProfile();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing subscription: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshingSubscription = false);
      }
    }
  }

  void _showPremiumWelcome() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Welcome back, Premium Member! 🎉',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF7C3AED),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadSignals() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final signalsProvider = Provider.of<SignalsProvider>(context, listen: false);

    final isPremium = authProvider.userProfile?.isSubscriptionActive ?? false;
    
    debugPrint('📊 Loading signals (Premium: $isPremium)');
    
    await signalsProvider.fetchTodaySignals(isPremium: isPremium);
    
    debugPrint('✅ Signals loaded: ${signalsProvider.signals.length}');
  }

  Future<void> _handleRefresh() async {
    await _refreshSubscriptionStatus();
    await _loadSignals();
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

    switch (index) {
      case 0:
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
        ).then((_) {
          setState(() => _currentIndex = 0);
          _handleRefresh();
        });
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
          if (_isRefreshingSubscription)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh subscription status',
              onPressed: _handleRefresh,
            ),
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
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // 1. AI TREND RADAR BANNER - Always visible, clickable for both users
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AIChatScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPremium
                        ? [const Color(0xFF7C3AED), const Color(0xFF9F7AEA)]
                        : [const Color(0xFF059669), const Color(0xFF10B981)],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPremium ? Icons.workspace_premium : Icons.radar,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium ? 'Premium Active' : 'AI Trend Radar',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            isPremium
                                ? 'Full Access Unlocked'
                                : 'AI Insights Available',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isPremium ? Icons.verified : Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: isPremium ? 20 : 16,
                    ),
                  ],
                ),
              ),
            ),

            // 2. UPGRADE BANNER - Only for non-premium users
            if (!isPremium)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded, 
                      color: Colors.white, 
                      size: 16
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '5 Sample Signals',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        ).then((_) {
                          _handleRefresh();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: 6
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Upgrade ₹499/mo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. STATUS BAR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isPremium 
                    ? const Color(0xFFF3E8FF) 
                    : const Color(0xFFDBEAFE),
              ),
              child: Row(
                children: [
                  Icon(
                    isPremium ? Icons.verified : Icons.trending_up,
                    color: isPremium 
                        ? const Color(0xFF7C3AED) 
                        : const Color(0xFF059669),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isPremium 
                          ? 'All Signals Unlocked' 
                          : 'Live AI Signals',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPremium 
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF047857),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isPremium 
                            ? const Color(0xFFE9D5FF)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: const Text(
                      '6 PM IST',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. SEARCH BAR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search stocks...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF9CA3AF),
                            size: 18,
                          ),
                          onPressed: _clearSearch,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
              ),
            ),

            // Search Results Info
            if (_searchQuery.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      'Found ${filteredSignals.length} result${filteredSignals.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearSearch,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 5. SUMMARY STATS
            if (signalsProvider.signals.isNotEmpty && _searchQuery.isEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Buy',
                      signalsProvider.buySignalsCount.toString(),
                      const Color(0xFF059669),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFE5E7EB),
                    ),
                    _buildStatItem(
                      'Sell',
                      signalsProvider.sellSignalsCount.toString(),
                      const Color(0xFFDC2626),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFE5E7EB),
                    ),
                    _buildStatItem(
                      'Hold',
                      signalsProvider.holdSignalsCount.toString(),
                      const Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
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
