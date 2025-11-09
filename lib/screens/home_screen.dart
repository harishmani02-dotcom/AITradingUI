import 'package:flutter/material.dart';
import '../services/finnhub_service.dart';
 
class TopMoversScreen extends StatefulWidget {
  const TopMoversScreen({super.key});
 
  @override
  State<TopMoversScreen> createState() => _TopMoversScreenState();
}
 
class _TopMoversScreenState extends State<TopMoversScreen> {
  final FinnhubService _service = FinnhubService();
  bool _loading = false;
  List<dynamic> _data = [];
  String _selectedTab = 'gainers';
 
  @override
  void initState() {
    super.initState();
    _loadData();
  }
 
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getTopMovers(_selectedTab);
      setState(() => _data = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Movers'),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          tabs: const [
            Tab(text: 'Top Gainers'),
            Tab(text: 'Top Losers'),
            Tab(text: 'Volume Buzzers'),
          ],
          onTap: (index) {
            setState(() {
              _selectedTab = index == 0 ? 'gainers' : index == 1 ? 'losers' : 'volume';
              _loadData();
            });
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? const Center(child: Text('No data available'))
              : ListView.builder(
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    final item = _data[index];
                    return ListTile(
                      title: Text(item['symbol'] ?? 'N/A'),
                      subtitle: Text(item['description'] ?? ''),
                      trailing: Text(item['change']?.toString() ?? ''),
                    );
                  },
                ),
    );
  }
}
