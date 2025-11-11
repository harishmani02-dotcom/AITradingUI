import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webfeed/webfeed.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSentimentFilter = 'All';
  String _selectedSourceFilter = 'All';
  bool _isLoading = false;
  bool _autoRefresh = true;
  Timer? _refreshTimer;
  DateTime _lastRefresh = DateTime.now();

  List<NewsItem> _allNews = [];
  String _errorMessage = '';

  // --- Groq API Configuration ---
  final String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _groqModel = 'llama3-8b-8192';
  // ------------------------------

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
    _checkEnvironment();
    _loadNews();
    _startAutoRefresh();
  }

  void _checkEnvironment() {
    if (dotenv.env.isEmpty) {
      debugPrint('⚠️ WARNING: Dotenv is empty. Make sure .env is loaded properly.');
    } else {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('⚠️ WARNING: GROQ_API_KEY not found in .env file');
      } else {
        debugPrint('✅ GROQ_API_KEY found (${apiKey.length} characters)');
      }
    }
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
            rawContent: '$title. $cleanDesc',
          );
        }).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching from ${source.name}: $e');
      return [];
    }
  }

  // --- IMPROVED AI SUMMARY FETCHER ---
  Future<String> _fetchAiSummary(String content) async {
    // Validate API key first
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    
    if (apiKey.isEmpty) {
      debugPrint('❌ GROQ_API_KEY not found in .env file');
      return "⚠️ API Key missing. Please add GROQ_API_KEY to your .env file.";
    }
    
    // Truncate content to prevent token overflow
    final truncatedContent = content.length > 500 
        ? content.substring(0, 500) 
        : content;

    final systemInstruction =
        "You are a concise financial news summarizer. Provide a brief analysis in 30-40 words highlighting the key event and market impact (Bullish/Bearish/Neutral). Be direct and skip introductory phrases.";

    final userQuery = "Summarize this financial news: $truncatedContent";

    final payload = {
      'model': _groqModel,
      'messages': [
        {'role': 'system', 'content': systemInstruction},
        {'role': 'user', 'content': userQuery},
      ],
      'temperature': 0.3,
      'max_tokens': 100,
      'top_p': 1,
    };

    const maxRetries = 2;
    Duration delay = const Duration(seconds: 1);
    const timeoutDuration = Duration(seconds: 20);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        debugPrint('🔄 AI Summary attempt ${attempt + 1}/$maxRetries');
        
        final response = await http.post(
          Uri.parse(_groqApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: json.encode(payload),
        ).timeout(timeoutDuration);

        debugPrint('📡 Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          final text = result['choices']?[0]?['message']?['content']?.toString().trim();
          
          if (text != null && text.isNotEmpty) {
            debugPrint('✅ AI Summary generated successfully');
            return text;
          }
        } else if (response.statusCode == 401) {
          debugPrint('❌ Unauthorized: Invalid API key');
          return "❌ Invalid API Key. Please verify your GROQ_API_KEY in the .env file.";
        } else if (response.statusCode == 429) {
          debugPrint('⚠️ Rate limit exceeded');
          return "⚠️ Rate limit reached. Please try again in a few minutes.";
        } else if (response.statusCode == 503) {
          debugPrint('⚠️ Service unavailable');
          if (attempt == maxRetries - 1) {
            return "⚠️ Groq API is temporarily unavailable. Try again later.";
          }
        } else {
          debugPrint('❌ Unexpected response: ${response.statusCode} - ${response.body}');
        }

      } on TimeoutException {
        debugPrint('⏱️ Request timed out on attempt ${attempt + 1}');
        if (attempt == maxRetries - 1) {
          return "⚠️ Connection timeout. The AI service is not responding. Check your internet connection.";
        }
      } on http.ClientException catch (e) {
        debugPrint('🌐 Network error: $e');
        if (attempt == maxRetries - 1) {
          return "❌ Network error. Please check your internet connection.";
        }
      } catch (e) {
        debugPrint('❌ Unexpected error: $e');
        if (attempt == maxRetries - 1) {
          return "❌ An unexpected error occurred: ${e.toString()}";
        }
      }

      // Exponential backoff
      if (attempt < maxRetries - 1) {
        await Future.delayed(delay);
        delay *= 2;
      }
    }

    return "❌ Unable to generate summary after $maxRetries attempts. Please try again.";
  }
  // -------------------------------------

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

  void _updateFilter(String type, String value) {
    setState(() {
      if (type == 'sentiment') {
        _selectedSentimentFilter = value;
      } else if (type == 'source') {
        _selectedSourceFilter = value;
      }
    });
  }

  List<NewsItem> get _filteredNews {
    final news = _allNews.where((news) {
      final matchesSearch = _searchQuery.isEmpty ||
          news.symbol.toUpperCase().contains(_searchQuery) ||
          news.title.toUpperCase().contains(_searchQuery) ||
          news.summary.toUpperCase().contains(_searchQuery);

      final matchesSentiment = _selectedSentimentFilter == 'All' ||
          news.sentiment == _selectedSentimentFilter;

      final matchesSource = _selectedSourceFilter == 'All' ||
          news.source == _selectedSourceFilter;

      return matchesSearch && matchesSentiment && matchesSource;
    }).toList();
    return news;
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return const Color(0xFF10B981);
      case 'Bearish':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'Bullish':
        return Icons.trending_up_rounded;
      case 'Bearish':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
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

  void _showAiSummaryDialog(NewsItem news) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<String>(
          future: _fetchAiSummary(news.rawContent),
          builder: (context, snapshot) {
            String summaryText;
            Widget contentWidget;
            bool isLoading = snapshot.connectionState == ConnectionState.waiting;

            if (isLoading) {
              summaryText = 'Generating AI Summary...';
              contentWidget = Column(
                children: [
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    summaryText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 16),
                  ),
                ],
              );
            } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.startsWith('❌') || snapshot.data!.startsWith('⚠️')) {
              summaryText = snapshot.data ?? 'An unknown error occurred.';
              
              bool isError = summaryText.startsWith('❌');
              bool isWarning = summaryText.startsWith('⚠️');
              
              contentWidget = Column(
                children: [
                  const SizedBox(height: 16),
                  Icon(
                    isError ? Icons.error_outline : Icons.warning_amber_rounded, 
                    color: isError ? const Color(0xFFEF4444) : const Color(0xFFFFA500), 
                    size: 40
                  ),
                  const SizedBox(height: 16),
                  Text(
                    summaryText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isError ? const Color(0xFFEF4444) : const Color(0xFFFFA500),
                      fontSize: 14,
                    ),
                  ),
                  if (isError || isWarning) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Check console logs for details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ]
                ],
              );
            } else {
              summaryText = snapshot.data!;
              contentWidget = Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  summaryText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFF7C3AED).withOpacity(0.5),
                  width: 2,
                ),
              ),
              titlePadding: const EdgeInsets.only(top: 24, bottom: 0, left: 24, right: 24),
              contentPadding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 0),
              actionsPadding: const EdgeInsets.all(16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'AI Summary: ${news.symbol}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  contentWidget,
                  if (!isLoading && !summaryText.startsWith('❌') && !summaryText.startsWith('⚠️')) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sentiment:',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSentimentColor(news.sentiment).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            news.sentiment,
                            style: TextStyle(
                              color: _getSentimentColor(news.sentiment),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openUrl(news.url);
                  },
                  child: const Text('Read Full Article', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentimentOptions = ['All', 'Bullish', 'Bearish', 'Neutral'];
    final sourceOptions = ['All', ..._rssSources.map((s) => s.name)];

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
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter by:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: sentimentOptions.map((sentiment) => _buildFilterChip(
                          sentiment,
                          _selectedSentimentFilter == sentiment,
                          () => _updateFilter('sentiment', sentiment),
                          _getSentimentColor(sentiment),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: sourceOptions.map((source) => _buildFilterChip(
                          source,
                          _selectedSourceFilter == source,
                          () => _updateFilter('source', source),
                          const Color(0xFF7C3AED),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                                textAlign: TextAlign.center,
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
  
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onPressed, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        onPressed: onPressed,
        backgroundColor: isSelected ? color : const Color(0xFF252B3B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? color : const Color(0xFF3B4252),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem news) {
    final sentimentColor = _getSentimentColor(news.sentiment);

    return GestureDetector(
      onTap: () => _openUrl(news.url),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B4252),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      news.symbol.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.symbol,
                        style: const TextStyle(
                          color: Color(0xFFC084FC),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '${news.source} • ${_getTimeAgo(news.timestamp)}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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

            const SizedBox(height: 12),

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
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAiSummaryDialog(news),
                  icon: const Icon(Icons.auto_awesome, color: Color(0xFFC084FC), size: 16),
                  label: const Text('AI Summary', style: TextStyle(color: Color(0xFFC084FC), fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                
                const SizedBox(width: 8),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 14,
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
  final String rawContent;

  NewsItem({
    required this.symbol,
    required this.title,
    required this.summary,
    required this.sentiment,
    required this.timestamp,
    required this.source,
    required this.url,
    required this.rawContent,
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
