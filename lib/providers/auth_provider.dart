import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
 
class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
 
  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
 
  AuthProvider() {
    _initAuthListener();
  }
 
  void _initAuthListener() {
    _user = _supabase.auth.currentUser;
    
    if (_user != null) {
      _fetchUserProfile();
    }
 
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _fetchUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }
 
  Future<void> _fetchUserProfile() async {
    try {
      final response = await _supabase
          .from('app_users')
          .select()
          .eq('user_id', _user!.id)
          .single();
 
      _userProfile = UserModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }
 
  Future<bool> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
 
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
 
      if (response.user != null) {
        _user = response.user;
        await _fetchUserProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }
 
      _errorMessage = 'Signup failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
 
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
 
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
 
      if (response.user != null) {
        _user = response.user;
        await _fetchUserProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }
 
      _errorMessage = 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
 
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
    _userProfile = null;
    notifyListeners();
  }
 
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}