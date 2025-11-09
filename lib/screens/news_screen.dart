// ============================================
// FILE 2: lib/screens/news_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webfeed/webfeed.dart';

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
  String _errorMessage = '';

  // Multiple RSS feed sources for Indian stock market
  final List<RSSSource> _rssSources = [
    RSSSource(
      name: 'Moneycontrol',
      url: 'https://www.moneycontrol.com/rss/latestnews.xml',
    ),
    RSSSource(
      name: 'Economic Times',
      url: 'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms',
    ),
    RSSSource(
      name: 'Business Standard',
      url: 'https://www.business-standard.com/rss/markets-106.rss',
    ),
    RSSSource(
      name: 'Mint',
      url: 'https://www.livemint.com/rss/markets',
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
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<NewsItem> allArticles = [];
      int successCount = 0;

      for (var source in _rssSources) {
        try {
          debugPrint('📡 Fetching from ${source.name}...');
          final articles = await _fetchFromRSS(source);
          if (articles.isNotEmpty) {
            allArticles.addAll(articles);
            successCount++;
            debugPrint('✅ Got ${articles.length} articles from ${source.name}');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to fetch from ${source.name}: $e');
        }
      }

      if (allArticles.isEmpty) {
        throw Exception('Could not fetch news from any source. Please check your internet connection.');
      }

      allArticles.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final cutoffDate = DateTime.now().subtract(const Duration(hours: 48));
      final recentArticles = allArticles.where((article) {
        return article.timestamp.isAfter(cutoffDate);
      }).toList();

      final articlesToShow = recentArticles.isNotEmpty ? recentArticles : allArticles;

      setState(() {
        _allNews = articlesToShow;
        _lastRefresh = DateTime.now();
        _isLoading = false;
        _errorMessage = '';
      });

      debugPrint('✅ Loaded ${articlesToShow.length} articles from $successCount sources');
    } catch (e) {
      debugPrint('❌ Error loading news: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load news: $e'),
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

  Future<List<NewsItem>> _fetchFromRSS(RSSSource source) async {
    try {
      final response = await http.get(
        Uri.parse(source.url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);
        final items = feed.items ?? [];

        return items.map((item) {
          final title = item.title ?? 'No Title';
          final description = item.description ?? '';
          final link = item.link ?? '';
          final pubDate = item.pubDate ?? DateTime.now();

          final cleanDesc = _stripHtml(description);
          final symbol = _extractStockSymbol(title + ' ' + cleanDesc);
          final sentiment = _analyzeSentiment(title + ' ' + cleanDesc);

          return NewsItem(
            symbol: symbol,
            title: _cleanText(title),
            summary: _cleanText(cleanDesc),
            sentiment: sentiment,
            timestamp: pubDate,
            source: source.name,
            url: link,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching from ${source.name}: $e');
      return [];
    }
  }

  String _stripHtml(String text) {
    final exp = RegExp(r'<[^>]*>', multiLine: true);
    return text
        .replaceAll(exp, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String _cleanText(String text) {
    if (text.isEmpty) return 'No description available';
    String cleaned = _stripHtml(text);
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.length > 200) {
      cleaned = '${cleaned.substring(0, 200)}...';
    }
    return cleaned.trim();
  }

  String _extractStockSymbol(String text) {
    final upperText = text.toUpperCase();

    final stockMap = {
      'RELIANCE': 'RELIANCE',
      'RIL': 'RELIANCE',
      'TCS': 'TCS',
      'TATA CONSULTANCY': 'TCS',
      'INFOSYS': 'INFY',
      'HDFC BANK': 'HDFCBANK',
      'HDFC': 'HDFCBANK',
      'ICICI BANK': 'ICICIBANK',
      'ICICI': 'ICICIBANK',
      'WIPRO': 'WIPRO',
      'TATA STEEL': 'TATASTEEL',
      'BHARTI AIRTEL': 'BHARTIARTL',
      'AIRTEL': 'BHARTIARTL',
      'SBI': 'SBIN',
      'STATE BANK': 'SBIN',
      'ADANI': 'ADANIENT',
      'ITC': 'ITC',
      'KOTAK': 'KOTAKBANK',
      'AXIS BANK': 'AXISBANK',
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
      'NIFTY': 'NIFTY',
      'SENSEX': 'SENSEX',
      'BSE': 'BSE',
      'NSE': 'NSE',
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

    final positiveWords = [
      'surge', 'gain', 'profit', 'growth', 'strong', 'beat', 'exceed',
      'bullish', 'high', 'rally', 'soar', 'jump', 'positive', 'upgrade',
      'outperform', 'record', 'hits high', 'all-time high', 'buy', 'up',
    ];

    final negativeWords = [
      'fall', 'loss', 'decline', 'weak', 'miss', 'disappoint', 'bearish',
      'low', 'crash', 'plunge', 'drop', 'concern', 'downgrade', 'underperform',
      'negative', 'sell', 'down', 'pressure', 'slump', 'worst',
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
        return const Color(0xFF8B5CF6);
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
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        title: const Text(
          'Market News',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _autoRefresh ? Icons.autorenew : Icons.refresh,
              color: const Color(0xFFA78BFA),
            ),
            onPressed: () {
              setState(() {
                _autoRefresh = !_autoRefresh;
              });
              _startAutoRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFA78BFA)),
            onPressed: _isLoading ? null : _loadNews,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        backgroundColor: const Color(0xFF2D3748),
        color: const Color(0xFFA78BFA),
        child: Column(
          children: [
            // Status Bar with Premium Banner
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Premium Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.diamond, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Premium Vibes',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Full Access Unlocked',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3748),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4B5563),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Color(0xFFA78BFA), size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'All Signals Unlocked',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${_getTimeAgo(_lastRefresh)}',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
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
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4B5563),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toUpperCase();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search stocks...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9CA3AF),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)),
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
                  fillColor: const Color(0xFF2D3748),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
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
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFA78BFA),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Fetching latest market news...',
                            style: TextStyle(
                              color: Colors.grey[400],
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
                                color: Colors.grey[700],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No news available'
                                    : 'No results for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadNews,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh News'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA78BFA),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                              itemCount: _filteredNews.length,
                              itemBuilder: (context, index) {
                                return _buildNewsCard(_filteredNews[index]);
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
                                    Color(0xFFA78BFA),
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
    final sentimentColor = _getSentimentColor(news.sentiment);
    final isBearish = news.sentiment == 'Bearish';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBearish ? Colors.red[900]! : Colors.green[900]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: sentimentColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Symbol and Sentiment
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sentimentColor.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA78BFA),
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
                  color: sentimentColor,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  news.sentiment,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sentimentColor,
                  ),
                ),
                const Spacer(),
                Text(
                  _getTimeAgo(news.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  news.summary,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.source,
                      size: 13,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        news.source,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openUrl(news.url),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA78BFA).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new, size: 12, color: Color(0xFFA78BFA)),
                            SizedBox(width: 4),
                            Text(
                              'Read',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFA78BFA),
                              ),
                            ),
                          ],
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

class RSSSource {
  final String name;
  final String url;

  RSSSource({
    required this.name,
    required this.url,
  });
}
