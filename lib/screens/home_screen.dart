import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/signals_provider.dart';
import '../widgets/signal_card.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';

@override
void initState() {
super.initState();
WidgetsBinding.instance.addPostFrameCallback((_) {
_loadSignals();
});
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

Future<void> _loadSignals() async {
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final signalsProvider = Provider.of<SignalsProvider>(context, listen: false);

final isPremium = authProvider.userProfile?.isSubscriptionActive ?? false;  
await signalsProvider.fetchTodaySignals(isPremium: isPremium);

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

@override
Widget build(BuildContext context) {
final authProvider = Provider.of<AuthProvider>(context);
final signalsProvider = Provider.of<SignalsProvider>(context);
final isPremium = authProvider.userProfile?.isSubscriptionActive ?? false;

// Filter signals based on search query  
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
      IconButton(  
        icon: const Icon(Icons.person, color: Colors.white),  
        onPressed: () {  
          Navigator.of(context).push(  
            MaterialPageRoute(builder: (_) => const ProfileScreen()),  
          );  
        },  
      ),  
    ],  
  ),  
  body: RefreshIndicator(  
    onRefresh: _loadSignals,  
    child: Column(  
      children: [  
        // Info banner  
        Container(  
          width: double.infinity,  
          padding: const EdgeInsets.all(16),  
          decoration: const BoxDecoration(  
            color: Color(0xFFDBEAFE),  
          ),  
          child: Row(  
            children: [  
              const Icon(  
                Icons.trending_up,  
                color: Color(0xFF10B981),  
                size: 32,  
              ),  
              const SizedBox(width: 12),  
              Expanded(  
                child: Column(  
                  crossAxisAlignment: CrossAxisAlignment.start,  
                  children: [  
                    Text(  
                      isPremium ? 'Premium Active ✨' : 'Live AI Signals',  
                      style: const TextStyle(  
                        fontSize: 16,  
                        fontWeight: FontWeight.w600,  
                        color: Color(0xFF1E40AF),  
                      ),  
                    ),  
                    const SizedBox(height: 2),  
                    const Text(  
                      'Updated daily at 6 PM IST',  
                      style: TextStyle(  
                        fontSize: 12,  
                        color: Color(0xFF6B7280),  
                      ),  
                    ),  
                  ],  
                ),  
              ),  
            ],  
          ),  
        ),  

        // ✅ SEARCH BAR  
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
            onChanged: _onSearchChanged,  
            decoration: InputDecoration(  
              hintText: 'Search stocks (e.g., RELIANCE, TCS, INFY)',  
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
                      onPressed: _clearSearch,  
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

        // ✅ SEARCH RESULTS INFO  
        if (_searchQuery.isNotEmpty) ...[  
          Padding(  
            padding: const EdgeInsets.symmetric(horizontal: 16),  
            child: Row(  
              children: [  
                Text(  
                  'Found ${filteredSignals.length} result${filteredSignals.length == 1 ? '' : 's'}',  
                  style: const TextStyle(  
                    fontSize: 14,  
                    color: Color(0xFF6B7280),  
                    fontWeight: FontWeight.w500,  
                  ),  
                ),  
                const Spacer(),  
                TextButton.icon(  
                  onPressed: _clearSearch,  
                  icon: const Icon(Icons.clear, size: 16),  
                  label: const Text('Clear'),  
                  style: TextButton.styleFrom(  
                    foregroundColor: const Color(0xFF1E40AF),  
                    padding: const EdgeInsets.symmetric(horizontal: 8),  
                  ),  
                ),  
              ],  
            ),  
          ),  
          const SizedBox(height: 8),  
        ],  

        // Summary stats (only show when not searching)  
        if (signalsProvider.signals.isNotEmpty && _searchQuery.isEmpty) ...[  
          Container(  
            margin: const EdgeInsets.symmetric(horizontal: 16),  
            padding: const EdgeInsets.all(16),  
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
            child: Row(  
              mainAxisAlignment: MainAxisAlignment.spaceAround,  
              children: [  
                _buildStatItem(  
                  '🟢 Buy',  
                  signalsProvider.buySignalsCount.toString(),  
                  const Color(0xFF10B981),  
                ),  
                Container(width: 1, height: 40, color: Colors.grey[300]),  
                _buildStatItem(  
                  '🔴 Sell',  
                  signalsProvider.sellSignalsCount.toString(),  
                  const Color(0xFFEF4444),  
                ),  
                Container(width: 1, height: 40, color: Colors.grey[300]),  
                _buildStatItem(  
                  '⚪ Hold',  
                  signalsProvider.holdSignalsCount.toString(),  
                  const Color(0xFF9CA3AF),  
                ),  
              ],  
            ),  
          ),  
          const SizedBox(height: 16),  
        ],  

        // Signals list  
        Expanded(  
          child: signalsProvider.isLoading  
              ? const Center(child: CircularProgressIndicator())  
              : filteredSignals.isEmpty  
                  ? _buildEmptyState(_searchQuery.isNotEmpty)  
                  : ListView.builder(  
                      padding: const EdgeInsets.only(bottom: 80),  
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
  floatingActionButton: !isPremium  
      ? FloatingActionButton.extended(  
          onPressed: () {  
            Navigator.of(context).push(  
              MaterialPageRoute(  
                builder: (_) => const SubscriptionScreen(),  
              ),  
            );  
          },  
          backgroundColor: const Color(0xFF7C3AED),  
          icon: const Icon(Icons.upgrade),  
          label: const Text('Upgrade to Premium'),  
        )  
      : null,  
);

}

Widget _buildStatItem(String label, String value, Color color) {
return Column(
children: [
Text(
value,
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: color,
),
),
const SizedBox(height: 4),
Text(
label,
style: const TextStyle(
fontSize: 12,
color: Color(0xFF6B7280),
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
