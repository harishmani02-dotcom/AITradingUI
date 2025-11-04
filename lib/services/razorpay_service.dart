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
      'prefill': {
        'email': userEmail,
      },
      'notes': {
        'user_id': userId,
        'product': 'premium_subscription',
      },
      'theme': {
        'color': RazorpayConfig.brandColor,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      onFailure('Failed to open payment gateway');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('✅ Payment Success: ${response.paymentId}');
    onSuccess(response.paymentId ?? '');
    
    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful! 🎉\nActivating subscription...'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
        ),
      );
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
