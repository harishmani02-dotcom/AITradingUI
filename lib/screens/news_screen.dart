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

  final String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _groqModel = 'llama3-8b-8192';

  final List<RSSSource> _rssSources = [
    RSSSource(name: 'Moneycontrol', url: 'https://www.moneycontrol.com/rss/latestnews.xml'),
    RSSSource(name: 'Economic Times', url: 'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms'),
    RSSSource(name: 'Business Standard', url: 'https://www.business-standard.com/rss/markets-106.rss'),
    RSSSource(name: 'Mint', url: 'https://www.livemint.com/rss/markets'),
  ];

  @override
  void initState() {
    super.initState();
    _validateConfiguration();
    _loadNews();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _validateConfiguration() {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('⚠️ GROQ_API_KEY not found in .env file!');
    } else if (apiKey.length < 20) {
      debugPrint('⚠️ GROQ_API_KEY seems too short.');
    } else {
      debugPrint('✅ API key present');
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) => _loadNews());
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<NewsItem> allArticles = [];
      for (var source in _rssSources) {
        try {
          final articles = await _fetchFromRSS(source);
          if (articles.isNotEmpty) allArticles.addAll(articles);
        } catch (e) {
          debugPrint('⚠️ Failed from ${source.name}: $e');
        }
      }

      if (allArticles.isEmpty) throw Exception('Could not fetch news');

      allArticles.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final cutoff = DateTime.now().subtract(const Duration(hours: 48));
      final recent = allArticles.where((a) => a.timestamp.isAfter(cutoff)).toList();

      setState(() {
        _allNews = recent.isNotEmpty ? recent : allArticles;
        _lastRefresh = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<List<NewsItem>> _fetchFromRSS(RSSSource source) async {
    final response = await http.get(Uri.parse(source.url), headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];

    final feed = RssFeed.parse(response.body);
    return (feed.items ?? []).map((item) {
      final title = item.title ?? 'No Title';
      final desc = _stripHtml(item.description ?? '');
      final content = '$title. $desc';
      return NewsItem(
        symbol: _extractStockSymbol(content),
        title: _cleanText(title),
        summary: _cleanText(desc),
        sentiment: _analyzeSentiment(content),
        timestamp: item.pubDate ?? DateTime.now(),
        source: source.name,
        url: item.link ?? '',
        rawContent: content,
      );
    }).toList();
  }

  Future<String> _fetchAiSummary(String content) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) return "⚠️ API Key missing. Add GROQ_API_KEY to .env";

    final payload = {
      'model': _groqModel,
      'messages': [
        {'role': 'system', 'content': 'Concise financial news summarizer. Max 40 words. Focus on key event and market impact.'},
        {'role': 'user', 'content': 'Summarize: $content'},
      ],
      'temperature': 0.3,
      'max_tokens': 150,
    };

    for (int i = 0; i < 2; i++) {
      try {
        final response = await http.post(
          Uri.parse(_groqApiUrl),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final text = json.decode(response.body)['choices']?[0]['message']?['content']?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        } else if (response.statusCode == 401) {
          return "❌ Invalid API Key";
        } else if (response.statusCode == 429) {
          return "⚠️ Rate limit exceeded";
        }
      } on TimeoutException {
        if (i == 1) return "⏱️ Request timed out";
      } catch (e) {
        if (i == 1) return "❌ Error: ${e.toString().substring(0, 30)}...";
      }
      if (i == 0) await Future.delayed(const Duration(seconds: 2));
    }
    return "❌ Failed after retries";
  }

  String _stripHtml(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&').trim();
  }

  String _cleanText(String text) {
    if (text.isEmpty) return 'No description';
    String clean = _stripHtml(text).replaceAll(RegExp(r'\s+'), ' ');
    return clean.length > 200 ? '${clean.substring(0, 200)}...' : clean.trim();
  }

  String _extractStockSymbol(String text) {
    final upper = text.toUpperCase();
    final stocks = {
      'RELIANCE': 'RELIANCE', 'TCS': 'TCS', 'INFOSYS': 'INFY', 'HDFC': 'HDFCBANK',
      'ICICI': 'ICICIBANK', 'WIPRO': 'WIPRO', 'AIRTEL': 'BHARTIARTL', 'SBI': 'SBIN',
      'ADANI': 'ADANIENT', 'ITC': 'ITC', 'AXIS': 'AXISBANK', 'MARUTI': 'MARUTI',
      'BAJAJ': 'BAJFINANCE', 'NIFTY': 'NIFTY', 'SENSEX': 'SENSEX',
    };
    for (var e in stocks.entries) {
      if (upper.contains(e.key)) return e.value;
    }
    return 'MARKET';
  }

  String _analyzeSentiment(String text) {
    final lower = text.toLowerCase();
    final pos = ['surge', 'gain', 'profit', 'growth', 'bullish', 'rally', 'up'];
    final neg = ['fall', 'loss', 'decline', 'bearish', 'crash', 'down'];
    int pCount = pos.where((w) => lower.contains(w)).length;
    int nCount = neg.where((w) => lower.contains(w)).length;
    if (pCount > nCount) return 'Bullish';
    if (nCount > pCount) return 'Bearish';
    return 'Neutral';
  }

  List<NewsItem> get _filteredNews {
    return _allNews.where((n) {
      final search = _searchQuery.isEmpty || n.symbol.toUpperCase().contains(_searchQuery) || n.title.toUpperCase().contains(_searchQuery);
      final sentiment = _selectedSentimentFilter == 'All' || n.sentiment == _selectedSentimentFilter;
      final source = _selectedSourceFilter == 'All' || n.source == _selectedSourceFilter;
      return search && sentiment && source;
    }).toList();
  }

  Color _getSentimentColor(String s) {
    if (s == 'Bullish') return const Color(0xFF10B981);
    if (s == 'Bearish') return const Color(0xFFEF4444);
    return const Color(0xFF9CA3AF);
  }

  IconData _getSentimentIcon(String s) {
    if (s == 'Bullish') return Icons.trending_up_rounded;
    if (s == 'Bearish') return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  String _getTimeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays == 1) return 'Yesterday';
    return '${d.inDays}d ago';
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showAiSummaryDialog(NewsItem news) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: _fetchAiSummary(news.rawContent),
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting;
          final error = snap.data?.startsWith('❌') ?? false || snap.data?.startsWith('⚠️') ?? false;
          final text = snap.data ?? 'Generating...';

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.5), width: 2)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 24),
                const SizedBox(width: 8),
                Text('AI Summary: ${news.symbol}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading) ...[
                  const CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  const SizedBox(height: 16),
                  const Text('Generating...', style: TextStyle(color: Color(0xFFE5E7EB))),
                ] else if (error) ...[
                  Icon(Icons.error_outline, color: const Color(0xFFEF4444), size: 40),
                  const SizedBox(height: 16),
                  Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
                ] else ...[
                  Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 15, height: 1.4)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sentiment:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _getSentimentColor(news.sentiment).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text(news.sentiment, style: TextStyle(color: _getSentimentColor(news.sentiment), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8)))),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openUrl(news.url);
                },
                child: const Text('Read Full', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w600, fontSize: 13)),
        onPressed: onTap,
        backgroundColor: selected ? color : const Color(0xFF252B3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selected ? color : const Color(0xFF3B4252))),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem news) {
    final color = _getSentimentColor(news.sentiment);
    return GestureDetector(
      onTap: () => _openUrl(news.url),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: const Color(0xFF3B4252), borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text(news.symbol[0], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(news.symbol, style: const TextStyle(color: Color(0xFFC084FC), fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('${news.source} • ${_getTimeAgo(news.timestamp)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      Icon(_getSentimentIcon(news.sentiment), color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(news.sentiment.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(news.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(news.summary, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAiSummaryDialog(news),
                  icon: const Icon(Icons.auto_awesome, color: Color(0xFFC084FC), size: 16),
                  label: const Text('AI Summary', style: TextStyle(color: Color(0xFFC084FC), fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9CA3AF), size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentiments = ['All', 'Bullish', 'Bearish', 'Neutral'];
    final sources = ['All', ..._rssSources.map((s) => s.name)];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('News Feed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _isLoading ? null : _loadNews)],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF252B3B), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF3B4252), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 24)),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Curated collection of top economic\nnews for the day ✨', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('${_allNews.length} articles • Updated ${_getTimeAgo(_lastRefresh)}', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFF252B3B), borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.toUpperCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by stock or keyword...',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)), onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    }) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFF252B3B),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter by:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: sentiments.map((s) => _buildFilterChip(s, _selectedSentimentFilter == s, () => setState(() => _selectedSentimentFilter = s), _getSentimentColor(s))).toList())),
                    const SizedBox(height: 8),
                    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: sources.map((s) => _buildFilterChip(s, _selectedSourceFilter == s, () => setState(() => _selectedSourceFilter = s), const Color(0xFF7C3AED))).toList())),
                  ],
                ),
              ),
            ),
            if (_isLoading && _allNews.isEmpty)
              SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: Colors.white), const SizedBox(height: 16), Text('Loading news...', style: TextStyle(color: Colors.grey[400]))])))
            else if (_filteredNews.isEmpty)
              SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.article_outlined, size: 64, color: Colors.grey[700]), const SizedBox(height: 16), Text(_searchQuery.isEmpty ? 'No news available' : 'No results', style: TextStyle(fontSize: 18, color: Colors.grey[400])), const SizedBox(height: 16), ElevatedButton.icon(onPressed: _loadNews, icon: const Icon(Icons.refresh), label: const Text('Refresh'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)))])))
            else
              SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildNewsCard(_filteredNews[index]), childCount: _filteredNews.length)),
          ],
        ),
      ),
    );
  }
}

class NewsItem {
  final String symbol, title, summary, sentiment, source, url, rawContent;
  final DateTime timestamp;
  NewsItem({required this.symbol, required this.title, required this.summary, required this.sentiment, required this.timestamp, required this.source, required this.url, required this.rawContent});
}

class RSSSource {
  final String name, url;
  RSSSource({required this.name, required this.url});
}
