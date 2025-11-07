// ============================================
// FILE: lib/screens/news_screen.dart
// ============================================
// Using RSS feeds - COMPLETELY FREE, NO LIMITS, NO API KEY NEEDED!

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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

  List<NewsItem> _allNews = [];

  // RSS Feed Sources - Multiple Indian financial news sources
  final List<NewsSource> _newsSources = [
    NewsSource(
      name: 'Economic Times - Markets',
      url: 'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms',
      category: 'market',
    ),
    NewsSource(
      name: 'Economic Times - Stocks',
      url: 'https://economictimes.indiatimes.com/markets/stocks/rssfeeds/2146842.cms',
      category: 'stocks',
    ),
    NewsSource(
      name: 'Moneycontrol - Markets',
      url: 'https://www.moneycontrol.com/rss/marketreports.xml',
      category: 'market',
    ),
    NewsSource(
      name: 'Moneycontrol - News',
      url: 'https://www.moneycontrol.com/rss/latestnews.xml',
      category: 'news',
    ),
    NewsSource(
      name: 'Business Standard - Markets',
      url: 'https://www.business-standard.com/rss/markets-106.rss',
      category: 'market',
    ),
    NewsSource(
      name: 'Business Standard - Finance',
      url: 'https://www.business-standard.com/rss/finance-103.rss',
      category: 'finance',
    ),
  ];

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
    _refreshTimer?.cancel();
    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
        _loadNews();
      });
    }
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);

    try {
      List<NewsItem> allArticles = [];

      // Fetch from all RSS sources in parallel
      final futures = _newsSources.map((source) => _fetchRSSFeed(source));
      final results = await Future.wait(futures);

      for (var articles in results) {
        allArticles.addAll(articles);
      }

      // Sort by timestamp (newest first)
      allArticles.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Filter today's news only
      final today = DateTime.now();
      final todayArticles = allArticles.where((article) {
        final diff = today.difference(article.timestamp);
        return diff.inHours < 24; // Only last 24 hours
      }).toList();

      setState(() {
        _allNews = todayArticles;
        _lastRefresh = DateTime.now();
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${todayArticles.length} news articles (last 24h)');
    } catch (e) {
      debugPrint('❌ Error loading news: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load news: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadNews,
            ),
          ),
        );
      }
    }
  }

  Future<List<NewsItem>> _fetchRSSFeed(NewsSource source) async {
    try {
      // Use RSS to JSON converter API (free, no limits)
      final rssUrl = Uri.encodeComponent(source.url);
      final apiUrl = 'https://api.rss2json.com/v1/api.json?rss_url=$rssUrl&count=50';
      
      final response = await http.get(
        Uri.parse(apiUrl),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'ok') {
          final items = data['items'] as List;
          
          return items.map((item) {
            return _parseRSSItem(item, source.name);
          }).toList();
        }
      }
      
      return [];
    } catch (e) {
      debugPrint('Error fetching ${source.name}: $e');
      return [];
    }
  }

  NewsItem _parseRSSItem(Map<String, dynamic> item, String sourceName) {
    final title = item['title'] ?? 'No Title';
    final description = item['description'] ?? item['content'] ?? 'No description available';
    final link = item['link'] ?? '';
    final pubDate = item['pubDate'] ?? DateTime.now().toIso8601String();
    
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(pubDate);
    } catch (e) {
      timestamp = DateTime.now();
    }

    // Clean HTML tags from description
    final cleanDescription = _stripHtmlTags(description);

    // Extract stock symbol
    final symbol = _extractStockSymbol(title + ' ' + cleanDescription);
    
    // Analyze sentiment
    final sentiment = _analyzeSentiment(title + ' ' + cleanDescription);

    return NewsItem(
      symbol: symbol,
      title: _cleanTitle(title),
      summary: _cleanSummary(cleanDescription),
      sentiment: sentiment,
      timestamp: timestamp,
      source: sourceName,
      url: link,
    );
  }

  String _stripHtmlTags(String html) {
    // Remove HTML tags
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return html.replaceAll(exp, '').replaceAll('&nbsp;', ' ').trim();
  }

  String _extractStockSymbol(String text) {
    final upperText = text.toUpperCase();
    
    // Comprehensive map of Indian company names to stock symbols
    final stockMap = {
      'RELIANCE': 'RELIANCE',
      'RIL': 'RELIANCE',
      'TCS': 'TCS',
      'TATA CONSULTANCY': 'TCS',
      'INFOSYS': 'INFY',
      'INFY': 'INFY',
      'HDFC': 'HDFCBANK',
      'HDFC BANK': 'HDFCBANK',
      'ICICI': 'ICICIBANK',
      'ICICI BANK': 'ICICIBANK',
      'WIPRO': 'WIPRO',
      'TATA STEEL': 'TATASTEEL',
      'TATASTEEL': 'TATASTEEL',
      'BHARTI': 'BHARTIARTL',
      'AIRTEL': 'BHARTIARTL',
      'SBI': 'SBIN',
      'STATE BANK': 'SBIN',
      'ADANI': 'ADANIENT',
      'ITC': 'ITC',
      'KOTAK': 'KOTAKBANK',
      'AXIS': 'AXISBANK',
      'HCL TECH': 'HCLTECH',
      'MARUTI': 'MARUTI',
      'BAJAJ': 'BAJFINANCE',
      'ASIAN PAINTS': 'ASIANPAINT',
      'LARSEN': 'LT',
      'L&T': 'LT',
      'ULTRATECH': 'ULTRACEMCO',
      'TITAN': 'TITAN',
      'NESTLE': 'NESTLEIND',
      'SUN PHARMA': 'SUNPHARMA',
      'MAHINDRA': 'M&M',
      'HINDALCO': 'HINDALCO',
      'POWER GRID': 'POWERGRID',
      'NTPC': 'NTPC',
      'ONGC': 'ONGC',
      'COAL INDIA': 'COALINDIA',
    };

    for (var entry in stockMap.entries) {
      if (upperText.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'MARKET';
  }

  String _analyzeSentiment(String text) {
    final lowerText = text.toLowerCase();
    
    // Positive keywords
    final positiveWords = [
      'surge', 'gain', 'profit', 'growth', 'strong', 'beat', 'exceed',
      'bullish', 'high', 'success', 'win', 'boost', 'rise', 'jump',
      'positive', 'upgrade', 'outperform', 'rally', 'soar', 'hits high',
      'record', 'all-time high', '买买', 'buy', 'up', 'top gainer'
    ];
    
    // Negative keywords
    final negativeWords = [
      'fall', 'loss', 'decline', 'weak', 'miss', 'disappoint', 'bearish',
      'low', 'fail', 'drop', 'concern', 'downgrade', 'underperform',
      'negative', 'struggle', 'cut', 'crash', 'plunge', 'slump',
      'worst', 'sell', 'down', 'pressure', 'loss'
    ];

    int positiveCount = 0;
    int negativeCount = 0;

    for (var word in positiveWords) {
      if (lowerText.contains(word)) positiveCount++;
    }

    for (var word in negativeWords) {
      if (lowerText.contains(word)) negativeCount++;
    }

    if (positiveCount > negativeCount) return 'Bullish';
    if (negativeCount > positiveCount) return 'Bearish';
    return 'Neutral';
  }

  String _cleanTitle(String title) {
    // Remove source names and clean up
    String cleaned = title.split(' - ')[0];
    cleaned = _stripHtmlTags(cleaned);
    return cleaned.length > 100 
        ? '${cleaned.substring(0, 100)}...' 
        : cleaned;
  }

  String _cleanSummary(String summary) {
    if (summary.isEmpty || summary == 'No description available') {
      return 'Tap to read full article';
    }
    String cleaned = _stripHtmlTags(summary);
    return cleaned.length > 200 
        ? '${cleaned.substring(0, 200)}...' 
        : cleaned;
  }

  List<NewsItem> get _filteredNews {
    if (_searchQuery.isEmpty) return _allNews;
    return _allNews.where((news) =>
      news.symbol.toUpperCase().contains(_searchQuery) ||
      news.title.toUpperCase().contains(_searchQuery) ||
      news.summary.toUpperCase().contains(_searchQuery)
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
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return 'Today';
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open article: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Indian Stock News',
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
              _startAutoRefresh();
            },
            tooltip: _autoRefresh ? 'Auto-refresh ON' : 'Auto-refresh OFF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadNews,
            tooltip: 'Refresh Now',
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
                  const Icon(
                    Icons.newspaper,
                    color: Color(0xFF1E40AF),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Indian Market News',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        Text(
                          'Updated: ${_getTimeAgo(_lastRefresh)} • ${_allNews.length} articles today',
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.autorenew, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Sources info banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Real-time news from ET, Moneycontrol, Business Standard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  hintText: 'Search by stock or keyword...',
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

            const SizedBox(height: 16),

            // News List
            Expanded(
              child: _isLoading && _allNews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading latest news...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
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
                                    ? 'No news available today'
                                    : 'No news found for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _loadNews,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh News'),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: _filteredNews.length,
                              itemBuilder: (context, index) {
                                final news = _filteredNews[index];
                                return _buildNewsCard(news);
                              },
                            ),
                            if (_isLoading)
                              const Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                          ],
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
                    Expanded(
                      child: Text(
                        news.source,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _openUrl(news.url),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text(
                        'Read Full',
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
  final String url;

  NewsItem({
    required this.symbol,
    required this.title,
    required this.summary,
    required this.sentiment,
    required this.timestamp,
    required this.source,
    required this.url,
  });
}

class NewsSource {
  final String name;
  final String url;
  final String category;

  NewsSource({
    required this.name,
    required this.url,
    required this.category,
  });
}
