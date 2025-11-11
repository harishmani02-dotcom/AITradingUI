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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshingSubscription = false;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
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
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Welcome back, Premium fam! ✨',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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

  Future<Map<String, dynamic>> _fetchMarketSentiment() async {
    try {
      final response = await Supabase.instance.client
          .from('market_sentiment')
          .select('sentiment, sentiment_score, last_updated')
          .order('last_updated', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return {
          'sentiment': response['sentiment'] ?? 'NEUTRAL',
          'score': response['sentiment_score'] ?? 50.0,
          'lastUpdated': response['last_updated'],
        };
      }
    } catch (e) {
      debugPrint('❌ Error fetching market sentiment: $e');
    }
    return {
      'sentiment': 'NEUTRAL',
      'score': 50.0,
      'lastUpdated': null,
    };
  }

  Future<void> _handleRefresh() async {
    await _refreshSubscriptionStatus();
    await _loadSignals();
  }
  
  // New method to handle navigation to the Subscription Screen
  void _navigateToSubscriptionScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(),
      ),
    ).then((_) {
      _handleRefresh();
    });
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
    
    // NOTE: The index logic below has been updated to remove the Alerts screen 
    // (formerly index 3). The new indices are:
    // 0: Home
    // 1: News
    // 2: Movers
    // 3: Profile (formerly 4)
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
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ).then((_) {
          setState(() => _currentIndex = 0);
          _handleRefresh();
        });
        break;
      default: // Added default case to prevent crashes if index is out of range
        setState(() => _currentIndex = 0);
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
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPremium
                      ? [const Color(0xFF8B5CF6), const Color(0xFFC084FC)]
                      : [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Signals",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isRefreshingSubscription)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPremium ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4),
                  ),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: _handleRefresh,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: isPremium ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
          ),
          child: SafeArea(
            child: signalsProvider.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isPremium ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            // 1. AI TREND RADAR BANNER
                            FutureBuilder<Map<String, dynamic>>(
                              future: _fetchMarketSentiment(),
                              builder: (context, snapshot) {
                                final sentiment = snapshot.data?['sentiment'] ?? 'NEUTRAL';
                                final score = snapshot.data?['score'] ?? 50.0;
                                final isBullish = sentiment == 'BULLISH';
                                final isBearish = sentiment == 'BEARISH';
                                Color primaryColor;
                                Color secondaryColor;
                                IconData sentimentIcon;
                                String sentimentText;
                                String sentimentEmoji;

                                if (isBullish) {
                                  primaryColor = const Color(0xFF10B981);
                                  secondaryColor = const Color(0xFF059669);
                                  sentimentIcon = Icons.trending_up_rounded;
                                  sentimentEmoji = '📈';
                                  sentimentText = isPremium ? 'Premium - Bullish Market' : 'Market Bullish';
                                } else if (isBearish) {
                                  primaryColor = const Color(0xFFEF4444);
                                  secondaryColor = const Color(0xFFDC2626);
                                  sentimentIcon = Icons.trending_down_rounded;
                                  sentimentEmoji = '📉';
                                  sentimentText = isPremium ? 'Premium - Bearish Market' : 'Market Bearish';
                                } else {
                                  primaryColor = const Color(0xFF06B6D4);
                                  secondaryColor = const Color(0xFF0EA5E9);
                                  sentimentIcon = Icons.remove_rounded;
                                  sentimentEmoji = '➡️';
                                  sentimentText = isPremium ? 'Premium - Neutral Market' : 'Market Neutral';
                                }

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => AIChatScreen()),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          primaryColor.withOpacity(0.9),
                                          secondaryColor.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2 + (_pulseController.value * 0.1)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                sentimentIcon,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '$sentimentEmoji AI Trend Radar',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white70,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                  if (isPremium) ...[
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF8B5CF6),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        'PRO',
                                                        style: TextStyle(
                                                          fontSize: 7,
                                                          fontWeight: FontWeight.w900,
                                                          color: Colors.white,
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      sentimentText,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: -0.3,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.25),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '${score.toStringAsFixed(0)}%',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w900,
                                                        color: Colors.white,
                                                        letterSpacing: -0.2,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // 2. UPGRADE BANNER
                            if (!isPremium)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2DD4BF),
                                      Color(0xFF06B6D4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF06B6D4).withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.stars_rounded, color: Colors.white, size: 15),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '5 Sample Signals',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          Text(
                                            'Unlock All Features',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _navigateToSubscriptionScreen();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF0891B2),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        elevation: 0,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        '₹499/mo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // 3. STATUS BAR
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: (isPremium ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4))
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      isPremium ? Icons.verified_rounded : Icons.whatshot_rounded,
                                      color: isPremium ? const Color(0xFFA78BFA) : const Color(0xFF22D3EE),
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isPremium ? 'All Signals Unlocked' : 'Live AI Signals',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isPremium ? const Color(0xFFA78BFA) : const Color(0xFF22D3EE),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 11,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '6 PM IST',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.white.withOpacity(0.8),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 4. SEARCH BAR
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search stocks...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 18,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: Colors.white.withOpacity(0.6),
                                            size: 16,
                                          ),
                                          onPressed: _clearSearch,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),

                            // Search Results Info
                            if (_searchQuery.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      'Found ${filteredSignals.length} result${filteredSignals.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _clearSearch,
                                      style: TextButton.styleFrom(
                                        foregroundColor: isPremium ? const Color(0xFFA78BFA) : const Color(0xFF22D3EE),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // 5. SUMMARY STATS (COMPACT LAYOUT)
                            if (signalsProvider.signals.isNotEmpty && _searchQuery.isEmpty) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      'Buy',
                                      signalsProvider.buySignalsCount.toString(),
                                      const Color(0xFF10B981),
                                      Icons.trending_up_rounded,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    _buildStatItem(
                                      'Sell',
                                      signalsProvider.sellSignalsCount.toString(),
                                      const Color(0xFFEF4444),
                                      Icons.trending_down_rounded,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    _buildStatItem(
                                      'Hold',
                                      signalsProvider.holdSignalsCount.toString(),
                                      const Color(0xFF8B5CF6),
                                      Icons.remove_rounded,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ],
                        ),
                      ),

                      // Signals List
                      filteredSignals.isEmpty
                          ? SliverFillRemaining(
                              child: _buildEmptyState(_searchQuery.isNotEmpty, isPremium),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final signal = filteredSignals[index];
                                  return SignalCard(
                                    signal: signal,
                                    showDetails: isPremium,
                                    // Pass the subscription navigation handler for locked cards
                                    onTap: isPremium ? null : _navigateToSubscriptionScreen,
                                  );
                                },
                                childCount: filteredSignals.length,
                              ),
                            ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isPremium
                ? [const Color(0xFF8B5CF6), const Color(0xFFC084FC)]
                : [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isPremium ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4))
                  .withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AIChatScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.chat_bubble_rounded, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: isPremium ? const Color(0xFFA78BFA) : const Color(0xFF22D3EE),
          unselectedItemColor: Colors.white.withOpacity(0.4),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_rounded),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_rounded),
              label: 'Movers',
            ),
            // REMOVED: Alerts Item (formerly index 3)
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isSearching, bool isPremium) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.info_outline_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? 'No signals found' : 'No signals available',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isSearching ? 'Try a different stock symbol' : 'Signals update daily at 6 PM IST',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (isSearching) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: isPremium
                      ? [const Color(0xFF8B5CF6), const Color(0xFFC084FC)]
                      : [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isPremium ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4))
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

