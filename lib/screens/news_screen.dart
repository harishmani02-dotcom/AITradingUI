import 'package:flutter/material.dart';
import 'dart:async';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _autoRefresh = true;
  Timer? _refreshTimer;
  DateTime _lastRefresh = DateTime.now();

  // Sample news data - Replace with actual API call
  List<NewsItem> _allNews = [];

  @override
  void initState() {
    super.initState();
    _loadNews();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
        _loadNews();
      });
    }
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);
    
    // Simulate API call - Replace with actual API
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _allNews = _getSampleNews();
      _lastRefresh = DateTime.now();
      _isLoading = false;
    });
  }

  List<NewsItem> _getSampleNews() {
    return [
      NewsItem(
        symbol: 'RELIANCE',
        title: 'Reliance Q4 Earnings Beat Estimates',
        summary: 'Reliance Industries posts strong quarterly results with revenue growth of 15% YoY. Jio subscriber additions exceed expectations.',
        sentiment: 'Bullish',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        source: 'Economic Times',
      ),
      NewsItem(
        symbol: 'TCS',
        title: 'TCS Wins Major Cloud Deal',
        summary: 'Tata Consultancy Services secures multi-year cloud transformation contract worth \$500M with global banking major.',
        sentiment: 'Bullish',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        source: 'Business Standard',
      ),
      NewsItem(
        symbol: 'INFY',
        title: 'Infosys Raises Revenue Guidance',
        summary: 'Infosys increases FY25 revenue growth guidance to 3.5-4.5% in constant currency terms on strong deal pipeline.',
        sentiment: 'Bullish',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        source: 'Mint',
      ),
      NewsItem(
        symbol: 'HDFCBANK',
        title: 'HDFC Bank Reports Margin Pressure',
        summary: 'Net interest margin contracts by 15 bps QoQ to 3.4%. Management cites deposit competition and loan mix changes.',
        sentiment: 'Neutral',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        source: 'Moneycontrol',
      ),
      NewsItem(
        symbol: 'TATASTEEL',
        title: 'Tata Steel Faces Demand Headwinds',
        summary: 'Steel demand remains subdued in domestic market. Company announces temporary production cuts to manage inventory.',
        sentiment: 'Bearish',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        source: 'Reuters',
      ),
    ];
  }

  List<NewsItem> get _filteredNews {
    if (_searchQuery.isEmpty) return _allNews;
    return _allNews.where((news) =>
      news.symbol.toUpperCase().contains(_searchQuery) ||
      news.title.toUpperCase().contains(_searchQuery)
    ).toList();
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return const Color(0xFF10B981);
      case 'Bearish':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return Icons.trending_up;
      case 'Bearish':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stock News AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        actions: [
          IconButton(
            icon: Icon(
              _autoRefresh ? Icons.autorenew : Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _autoRefresh = !_autoRefresh;
              });
              if (_autoRefresh) {
                _startAutoRefresh();
              } else {
                _refreshTimer?.cancel();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        child: Column(
          children: [
            // Status Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFDBEAFE),
              child: Row(
                children: [
                  Icon(
                    Icons.article,
                    color: const Color(0xFF1E40AF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI-Summarized Market News',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        Text(
                          'Last updated: ${_getTimeAgo(_lastRefresh)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_autoRefresh)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Auto-refresh: ON',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toUpperCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search news by stock or keyword',
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
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
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

            // News List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredNews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No news available'
                                    : 'No news found for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _filteredNews.length,
                          itemBuilder: (context, index) {
                            final news = _filteredNews[index];
                            return _buildNewsCard(news);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem news) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getSentimentColor(news.sentiment).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    news.symbol,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _getSentimentIcon(news.sentiment),
                  color: _getSentimentColor(news.sentiment),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  news.sentiment,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getSentimentColor(news.sentiment),
                  ),
                ),
                const Spacer(),
                Text(
                  _getTimeAgo(news.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  news.summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.source,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      news.source,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Open full article
                      },
                      child: const Text(
                        'Read More',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewsItem {
  final String symbol;
  final String title;
  final String summary;
  final String sentiment;
  final DateTime timestamp;
  final String source;

  NewsItem({
    required this.symbol,
    required this.title,
    required this.summary,
    required this.sentiment,
    required this.timestamp,
    required this.source,
  });
}
