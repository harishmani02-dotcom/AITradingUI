import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/signal_model.dart';
 
class SignalsProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
 
  List<SignalModel> _signals = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPremiumUser = false;
 
  List<SignalModel> get signals => _signals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPremiumUser => _isPremiumUser;
 
  int get buySignalsCount =>
      _signals.where((s) => s.signal.toLowerCase() == 'buy').length;
 
  int get sellSignalsCount =>
      _signals.where((s) => s.signal.toLowerCase() == 'sell').length;
 
  int get holdSignalsCount =>
      _signals.where((s) => s.signal.toLowerCase() == 'hold').length;
 
  double get averageConfidence {
    if (_signals.isEmpty) return 0;
    return _signals.map((s) => s.confidence).reduce((a, b) => a + b) / signals.length;
  }
 
  /// ✅ FIX 1, 2, 3: Fetch latest unique signals + check subscription
  Future<void> fetchTodaySignals({bool? isPremium}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
 
      // 🔍 DEBUG: Check authentication
      final user = _supabase.auth.currentUser;
      print('🔐 Current user: ${user?.email ?? "NOT LOGGED IN"}');
      print('🔐 User ID: ${user?.id}');
 
      // ✅ FIX 3: Check subscription status from database
      if (isPremium == null && user != null) {
        try {
          final subscriptionResponse = await _supabase
              .from('app_users')
              .select('subscription_status, subscription_end')
              .eq('user_id', user.id)
              .single();
          
          final subscriptionStatus = subscriptionResponse['subscription_status'] ?? false;
          final subscriptionEndStr = subscriptionResponse['subscription_end'];
          
          if (subscriptionStatus && subscriptionEndStr != null) {
            final subscriptionEnd = DateTime.parse(subscriptionEndStr);
            _isPremiumUser = subscriptionEnd.isAfter(DateTime.now());
          } else {
            _isPremiumUser = subscriptionStatus;
          }
          
          print('💎 Premium status: $_isPremiumUser');
        } catch (e) {
          print('⚠️ Could not fetch subscription status: $e');
          _isPremiumUser = false;
        }
      } else {
        _isPremiumUser = isPremium ?? false;
      }
 
      // ✅ FIX 1 & 2: Get all signals, then filter for latest per stock
      print('📡 Fetching signals from database...');
      
      final response = await _supabase
          .from('signals')
          .select()
          .order('signal_date', ascending: false)
          .order('created_at', ascending: false);
 
      print('✅ Fetched ${response.length} total signals from DB');
 
      if (response.isEmpty) {
        print('❌ No signals found in database');
        _signals = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
 
      // ✅ Group by symbol and take only the latest (first occurrence)
      final Map<String, dynamic> latestSignalsMap = {};
      
      for (var json in response) {
        final symbol = json['symbol'];
        // Only add if we haven't seen this symbol yet
        if (!latestSignalsMap.containsKey(symbol)) {
          latestSignalsMap[symbol] = json;
        }
      }
 
      print('📊 Found ${latestSignalsMap.length} unique stocks');
 
      // Convert to SignalModel list
      var signalsList = latestSignalsMap.values
          .map((json) => SignalModel.fromJson(json))
          .toList();
 
      // Sort by confidence (highest first)
      signalsList.sort((a, b) => b.confidence.compareTo(a.confidence));
 
      print('📈 Signals sorted by confidence');
 
      // ✅ Limit for free users
      if (!_isPremiumUser) {
        signalsList = signalsList.take(5).toList();
        print('🆓 FREE user - Limited to 5 signals');
      } else {
        print('💎 PREMIUM user - Showing all ${signalsList.length} signals');
      }
 
      _signals = signalsList;
      
      print('✅ Final signals count: ${_signals.length}');
      print('📊 Symbols: ${_signals.map((s) => s.symbol).join(", ")}');
      print('📅 Latest signal date: ${_signals.isNotEmpty ? _signals[0].signalDate : "N/A"}');
 
      _isLoading = false;
      notifyListeners();
 
    } catch (e) {
      print('❌ ERROR fetching signals: $e');
      _errorMessage = 'Failed to load signals: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
 
  /// Refresh signals (calls fetchTodaySignals)
  Future<void> refreshSignals({bool? isPremium}) async {
    await fetchTodaySignals(isPremium: isPremium);
  }
 
  /// Clear any error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
 
  /// Manually set premium status (useful for testing)
  void setPremiumStatus(bool isPremium) {
    _isPremiumUser = isPremium;
    notifyListeners();
  }
}
