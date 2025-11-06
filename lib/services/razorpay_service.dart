import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/razorpay_config.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final BuildContext context;
  final String userEmail;
  final String userId;
  final Function(String paymentId) onSuccess;
  final Function(String error) onFailure;

  RazorpayService({
    required this.context,
    required this.userEmail,
    required this.userId,
    required this.onSuccess,
    required this.onFailure,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout() {
    var options = {
      'key': RazorpayConfig.keyId,
      'amount': RazorpayConfig.subscriptionAmount,
      'name': RazorpayConfig.companyName,
      'description': RazorpayConfig.description,
      'prefill': {'email': userEmail},
      'notes': {
        'user_id': userId,
        'product': 'premium_subscription',
      },
      'theme': {'color': RazorpayConfig.brandColor},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      onFailure('Failed to open payment gateway');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success: ${response.paymentId}');
    
    try {
      final supabase = Supabase.instance.client;
      final paymentId = response.paymentId ?? '';
      
      // Step 1: Log payment
      await supabase.from('payments').insert({
        'user_id': userId,
        'razorpay_payment_id': paymentId,
        'amount': RazorpayConfig.subscriptionAmount / 100,
        'status': 'success',
        'currency': 'INR',
      });
      
      // Step 2: Activate subscription (30 days)
      final subscriptionEnd = DateTime.now().add(const Duration(days: 30));
      
      await supabase.from('app_users').upsert({
        'user_id': userId,
        'subscription_status': true,
        'subscription_end': subscriptionEnd.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Subscription activated');
      onSuccess(paymentId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! 🎉\nPremium activated!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Database Error: $e');
      onFailure('Payment successful but activation failed');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Error: ${response.code} - ${response.message}');
    onFailure(response.message ?? 'Payment failed');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed\n${response.message ?? "Please try again"}'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('🔗 External Wallet: ${response.walletName}');
  }

  void dispose() {
    _razorpay.clear();
  }
}
