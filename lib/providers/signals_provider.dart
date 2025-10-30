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
    return _signals.map((s) => s.confidence).reduce((a, b) => a + b) / _signals.length;
  }
 
  /// ✅ FINAL FIX: Fetch latest unique signals
  Future<void> fetchTodaySignals({bool? isPremium}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
 
      final user = _supabase.auth.currentUser;
      print('🔐 User: ${user?.email ?? "NOT LOGGED IN"}');
 
      // Check subscription status
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
          
          print('💎 Premium: $_isPremiumUser');
        } catch (e) {
          print('⚠️ Subscription check failed: $e');
          _isPremiumUser = false;
        }
      } else {
        _isPremiumUser = isPremium ?? false;
      }
 
      // ✅ STEP 1: Get the latest signal_date
      print('📡 Finding latest signal date...');
      
      final maxDateResult = await _supabase
          .from('signals')
          .select('signal_date')
          .order('signal_date', ascending: false)
          .limit(1);
 
      if (maxDateResult.isEmpty) {
        print('❌ No signals in database');
        _signals = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
 
      final latestDate = maxDateResult[0]['signal_date'];
      print('📅 Latest date: $latestDate');
 
      // ✅ STEP 2: Get ALL signals for that date only
      final response = await _supabase
          .from('signals')
          .select()
          .eq('signal_date', latestDate);
 
      print('✅ Fetched ${response.length} signals for $latestDate');
 
      if (response.isEmpty) {
        print('❌ No signals found for latest date');
        _signals = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
 
      // ✅ STEP 3: Remove duplicates by symbol (keep first occurrence)
      final seenSymbols = <String>{};
      final uniqueSignals = <dynamic>[];
 
      for (var json in response) {
        final symbol = json['symbol'];
        if (!seenSymbols.contains(symbol)) {
          seenSymbols.add(symbol);
          uniqueSignals.add(json);
        } else {
          print('⚠️ Duplicate found: $symbol - SKIPPED');
        }
      }
 
      print('📊 Unique signals: ${uniqueSignals.length}');
 
      // ✅ STEP 4: Convert to models
      var signalsList = uniqueSignals
          .map((json) => SignalModel.fromJson(json))
          .toList();
 
      // ✅ STEP 5: Sort by confidence
      signalsList.sort((a, b) => b.confidence.compareTo(a.confidence));
 
      // ✅ STEP 6: Limit for free users
      if (!_isPremiumUser) {
        signalsList = signalsList.take(5).toList();
        print('🆓 FREE - Limited to 5 signals');
      } else {
        print('💎 PREMIUM - Showing all ${signalsList.length} signals');
      }
 
      _signals = signalsList;
      
      print('✅ FINAL: ${_signals.length} signals');
      print('📊 Symbols: ${_signals.map((s) => s.symbol).join(", ")}');
 
      _isLoading = false;
      notifyListeners();
 
    } catch (e) {
      print('❌ ERROR: $e');
      _errorMessage = 'Failed to load signals: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
 
  Future<void> refreshSignals({bool? isPremium}) async {
    await fetchTodaySignals(isPremium: isPremium);
  }
 
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
 
  void setPremiumStatus(bool isPremium) {
    _isPremiumUser = isPremium;
    notifyListeners();
  }
}
