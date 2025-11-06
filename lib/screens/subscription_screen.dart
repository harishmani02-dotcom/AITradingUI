import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/razorpay_service.dart';
import '../providers/auth_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isProcessing = false;

  Future<void> _handlePayment() async {
    // Prevent double-tap
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception('Please login first');
      }

      // Initialize Razorpay payment
      final razorpayService = RazorpayService(
        context: context,
        userEmail: user.email ?? '',
        userId: user.id,
        onSuccess: (paymentId) async {
          debugPrint('✅ Payment ID: $paymentId');
          
          // Wait 2 seconds for database to update
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            // Navigate to home and remove all previous routes
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        },
        onFailure: (error) {
          debugPrint('❌ Payment failed: $error');
          setState(() => _isProcessing = false);
        },
      );

      // Open Razorpay checkout
      razorpayService.openCheckout();
      
    } catch (e) {
      setState(() => _isProcessing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subscribe to Premium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Premium Badge
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Premium Access',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '₹499',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: '/month',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Features List
              _buildFeatureCard(),

              const SizedBox(height: 32),

              // Subscribe Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Subscribe Now - ₹499',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Trust Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Secure payment powered by Razorpay',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Cancel Anytime Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[700],
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cancel anytime from your profile\nNo hidden charges',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What You Get',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureItem('Daily AI signals for 20+ stocks'),
          _buildFeatureItem('5-method technical analysis'),
          _buildFeatureItem('Buy/Sell confidence scores'),
          _buildFeatureItem('RSI, MACD, Bollinger analysis'),
          _buildFeatureItem('Volume & pattern recognition'),
          _buildFeatureItem('Historical accuracy tracking'),
          _buildFeatureItem('Priority customer support'),
          _buildFeatureItem('Updates daily at 6 PM IST'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
