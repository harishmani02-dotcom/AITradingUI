import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
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

  // Gemini API Configuration
  // NOTE: In a production Flutter app, this key should be secured, not hardcoded.
  final String apiKey = ""; // Canvas will provide this at runtime
  final String apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=";

  // State: Filtering
  String _selectedSentimentFilter = 'All';
  String _selectedCategoryFilter = 'All';

  List<NewsItem> _allNews = [];
  String _errorMessage = '';

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

  final List<String> _sentimentFilters = ['All', 'Bullish', 'Bearish', 'Neutral'];
  final List<String> _categoryFilters = ['All', 'My Watchlist', 'Market', 'Policy', 'Earnings'];

  @override
  void initState() {
    super.initState();
    _loadNews();
    _startAutoRefresh();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toUpperCase();
      });
    });
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

  // --- GEMINI API CALL FOR SUMMARY ---
  Future<String> _fetchAiSummary(String title, String summary) async {
    final prompt = "Summarize the following financial news article in one short, impactful paragraph (maximum 3 sentences). Focus only on the market impact and key facts. Title: $title. Summary: $summary";

    final payload = {
        "contents": [
            {"parts": [{"text": prompt}]}
        ],
        "systemInstruction": {
            "parts": [{"text": "You are a concise financial news analyst. Your response must be purely the summary paragraph, with no preamble."}]
        }
    };

    int retries = 0;
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    while (retries < maxRetries) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl$apiKey'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          return text ?? "Failed to generate AI summary.";
        } else {
          debugPrint('API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        debugPrint('API Request failed (Retry $retries): $e');
      }

      retries++;
      if (retries < maxRetries) {
        await Future.delayed(baseDelay * (1 << (retries - 1))); // Exponential backoff
      }
    }
    return "Failed to connect to AI service after multiple retries.";
  }
  // --- END GEMINI API CALL ---

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // ... (rest of _loadNews remains the same)

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
        throw Exception('Could not fetch news. Please check your internet connection.');
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
            // REMOVED MOCK SUMMARY - it will be fetched on demand now
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
    final filteredBySentiment = _allNews.where((news) {
      if (_selectedSentimentFilter == 'All') return true;
      return news.sentiment == _selectedSentimentFilter;
    });

    final filteredByCategory = filteredBySentiment.where((news) {
      if (_selectedCategoryFilter == 'All') return true;
      if (_selectedCategoryFilter == 'My Watchlist') {
        // Mocking Watchlist filter logic
        return ['TCS', 'INFY'].contains(news.symbol);
      }
      if (_selectedCategoryFilter == 'Market') {
        return news.symbol == 'MARKET';
      }
      // Since RSS data doesn't provide explicit categories, we'll map source names
      if (_selectedCategoryFilter == 'Policy' && (news.source.contains('Standard') || news.source.contains('Times'))) {
        return true;
      }
      if (_selectedCategoryFilter == 'Earnings' && (news.title.contains('Q') || news.title.contains('Profit') || news.title.contains('Result'))) {
        return true;
      }
      return false;
    });


    if (_searchQuery.isEmpty) return filteredByCategory.toList();

    return filteredByCategory.where((news) =>
      news.symbol.toUpperCase().contains(_searchQuery) ||
      news.title.toUpperCase().contains(_searchQuery) ||
      news.summary.toUpperCase().contains(_searchQuery)
    ).toList();
  }

  // Helper method to build the filter chips
  Widget _buildFilterChip(String label, String currentSelection, Function(String) onSelect) {
    final isSelected = currentSelection == label;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF252B3B), // Highlight color for selection
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Helper to show the AI Summary Dialog (Updated to fetch real data)
  void _showAiSummaryDialog(NewsItem news) {
    final Color primaryColor = _getSentimentColor(news.sentiment);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF3B82F6), size: 24),
              const SizedBox(width: 8),
              Text(
                'AI Summary: ${news.symbol}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          // Use FutureBuilder to handle the asynchronous API call
          content: FutureBuilder<String>(
            future: _fetchAiSummary(news.title, news.summary),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  ),
                );
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.contains("Failed")) {
                return SizedBox(
                  height: 150,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading summary.',
                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        ),
                        Text(
                          snapshot.data ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                        )
                      ],
                    ),
                  ),
                );
              }

              // Display the successful summary
              final summaryText = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summaryText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Analyzed Sentiment:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          news.sentiment,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF3B82F6))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openUrl(news.url);
              },
              child: Text('Read Full Article', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return const Color(0xFF22C55E); // Green
      case 'Bearish':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF9CA3AF); // Gray/Neutral
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
    final filteredArticles = _filteredNews;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'News Feed',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadNews,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        backgroundColor: const Color(0xFF2D3748),
        color: Colors.white,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF252B3B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B4252),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFFFD700),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Curated collection of top economic',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'news for the day ✨',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_allNews.length} articles • Updated ${_getTimeAgo(_lastRefresh)}',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF252B3B),
                  borderRadius: BorderRadius.circular(12),
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
                    hintText: 'Search by stock or keyword...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
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
                    fillColor: const Color(0xFF252B3B),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // --- FILTERING CHIPS ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Sentiment:',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _sentimentFilters.map((label) => _buildFilterChip(label, _selectedSentimentFilter, (value) {
                          setState(() => _selectedSentimentFilter = value);
                        })).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Filter by Category:',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _categoryFilters.map((label) => _buildFilterChip(label, _selectedCategoryFilter, (value) {
                          setState(() => _selectedCategoryFilter = value);
                        })).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // --- END FILTERING CHIPS ---

            _isLoading && _allNews.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading news...',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _filteredNews.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
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
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadNews,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh News'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildNewsCard(_filteredNews[index]);
                          },
                          childCount: _filteredNews.length,
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  // --- VISUAL DENSITY and AI SUMMARY BUTTON ---
  Widget _buildNewsCard(NewsItem news) {
    final sentimentColor = _getSentimentColor(news.sentiment);

    return GestureDetector(
      // Opens the full article link
      onTap: () => _openUrl(news.url),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF252B3B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Stock Symbol, Source, and Sentiment (Condensed Header)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Stock Initial/Source Icon (Visual Density)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: sentimentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          news.symbol.substring(0, 1),
                          style: TextStyle(
                            color: sentimentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news.symbol,
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          news.source,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Sentiment Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sentimentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSentimentIcon(news.sentiment),
                        color: sentimentColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        news.sentiment.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: sentimentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Article Title and Summary (Core Content)
            Text(
              news.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              news.summary,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Row 3: Time Ago & AI Summary Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTimeAgo(news.timestamp),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),

                // AI Summary Button (Enhancement 3)
                GestureDetector(
                  // Open the dialog to trigger the API call
                  onTap: () => _showAiSummaryDialog(news),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFFA78BFA), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'AI Summary',
                          style: TextStyle(
                            color: Color(0xFFA78BFA),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
  // Removed aiSummary field as it is fetched on demand

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
