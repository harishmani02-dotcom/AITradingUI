import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/razorpay_config.dart';

/// Razorpay Payment Service
/// This handles payment processing and subscription activation
/// Works for unlimited users - scalable and production-ready
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

  /// Opens Razorpay payment checkout
  void openCheckout() {
    var options = {
      'key': RazorpayConfig.keyId,
      'amount': RazorpayConfig.subscriptionAmount, // in paise
      'name': RazorpayConfig.companyName,
      'description': RazorpayConfig.description,
      'prefill': {
        'email': userEmail,
      },
      'notes': {
        'user_id': userId,
        'product': 'premium_subscription',
      },
      'theme': {
        'color': RazorpayConfig.brandColor,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('❌ Razorpay Error: $e');
      onFailure('Failed to open payment gateway');
    }
  }

  /// Handles successful payment
  /// Step 1: Logs payment to database
  /// Step 2: Activates user subscription for 30 days
  /// Step 3: Shows success message
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success: ${response.paymentId}');
    
    try {
      final supabase = Supabase.instance.client;
      final paymentId = response.paymentId ?? '';
      final amount = RazorpayConfig.subscriptionAmount / 100; // Convert paise to rupees
      
      // STEP 1: Log payment in payments table
      debugPrint('📝 Logging payment...');
      await supabase.from('payments').insert({
        'user_id': userId,
        'razorpay_payment_id': paymentId,
        'amount': amount,
        'status': 'success',
        'currency': 'INR',
        'payment_method': 'razorpay',
      });
      debugPrint('✅ Payment logged');
      
      // STEP 2: Activate subscription (30 days from today)
      debugPrint('🔄 Activating subscription...');
      final subscriptionEnd = DateTime.now().add(const Duration(days: 30));
      
      // Check if user record exists
      final existingUser = await supabase
          .from('app_users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existingUser == null) {
        // User record doesn't exist - create new one
        debugPrint('📝 Creating new user record...');
        await supabase.from('app_users').insert({
          'user_id': userId,
          'email': userEmail,
          'subscription_status': true,
          'subscription_end': subscriptionEnd.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // User exists - update subscription
        debugPrint('🔄 Updating existing user...');
        await supabase
            .from('app_users')
            .update({
              'subscription_status': true,
              'subscription_end': subscriptionEnd.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      }
      
      debugPrint('✅ Subscription activated until ${subscriptionEnd.toString()}');
      
      // STEP 3: Notify user of success
      onSuccess(paymentId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Payment Successful!\nPremium activated for 30 days!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('❌ Database Error: $e');
      
      // Even if database fails, payment succeeded
      // Log this for manual resolution
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Payment successful but activation failed\n'
              'Payment ID: ${response.paymentId}\n'
              'Contact support for activation'
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 6),
          ),
        );
      }
      
      onFailure('Payment successful but activation failed: $e');
    }
  }

  /// Handles failed payment
  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Error: ${response.code} - ${response.message}');
    onFailure(response.message ?? 'Payment failed');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment Failed\n${response.message ?? "Please try again"}'
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Handles external wallet selection (PayTM, PhonePe, etc.)
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('🔗 External Wallet: ${response.walletName}');
  }

  /// Clean up resources
  void dispose() {
    _razorpay.clear();
  }
}
