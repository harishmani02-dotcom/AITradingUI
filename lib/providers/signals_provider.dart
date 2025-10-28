import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/signal_model.dart';
 
class SignalsProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<SignalModel> _signals = [];
  bool _isLoading = false;
  String? _errorMessage;
 
  List<SignalModel> get signals => _signals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
 
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
 
  Future<void> fetchTodaySignals({bool isPremium = false}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
 
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      var query = _supabase
          .from('signals')
          .select()
          .eq('signal_date', today)
          .order('confidence', ascending: false);
 
      // If not premium, limit to 5 signals (free tier)
      if (!isPremium) {
        query = query.limit(5);
      }
 
      final response = await query;
      
      _signals = (response as List)
          .map((json) => SignalModel.fromJson(json))
          .toList();
 
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
 
  Future<void> refreshSignals({bool isPremium = false}) async {
    await fetchTodaySignals(isPremium: isPremium);
  }
 
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}