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
            // 1. PROFESSIONAL COMPACT TOP BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPremium
                      ? [const Color(0xFF7C3AED), const Color(0xFF9F7AEA)]
                      : [const Color(0xFF10B981), const Color(0xFF059669)],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPremium ? Icons.workspace_premium : Icons.radar,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'Premium Active' : 'AI Trend Radar',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isPremium
                              ? 'Full Access Unlocked'
                              : 'Upgrade for AI Insights',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPremium)
                    const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 18,
                    ),
                ],
              ),
            ),

            // 2. PROFESSIONAL COMPACT PREMIUM BANNER
            if (!isPremium)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded, 
                      color: Colors.white, 
                      size: 14
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        '5 Sample Signals',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
                          horizontal: 8, 
                          vertical: 4
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        'Upgrade ₹499/mo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. PROFESSIONAL COMPACT STATUS BAR
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPremium 
                    ? const Color(0xFFF3E8FF) 
                    : const Color(0xFFDBEAFE),
                border: Border(
                  bottom: BorderSide(
                    color: isPremium 
                        ? const Color(0xFFE9D5FF)
                        : const Color(0xFFBFDBFE),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPremium ? Icons.verified : Icons.trending_up,
                    color: isPremium 
                        ? const Color(0xFF7C3AED) 
                        : const Color(0xFF10B981),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPremium 
                          ? 'All Signals Unlocked' 
                          : 'Live AI Signals',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPremium 
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF1E40AF),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '6 PM IST',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. PROFESSIONAL COMPACT SEARCH BAR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search stocks...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF9CA3AF),
                            size: 16,
                          ),
                          onPressed: _clearSearch,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
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
                        fontSize: 11,
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
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // 5. PROFESSIONAL COMPACT SUMMARY STATS
            if (signalsProvider.signals.isNotEmpty && _searchQuery.isEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Buy',
                      signalsProvider.buySignalsCount.toString(),
                      const Color(0xFF10B981),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFE5E7EB),
                    ),
                    _buildStatItem(
                      'Sell',
                      signalsProvider.sellSignalsCount.toString(),
                      const Color(0xFFEF4444),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFE5E7EB),
                    ),
                    _buildStatItem(
                      'Hold',
                      signalsProvider.holdSignalsCount.toString(),
                      const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
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
