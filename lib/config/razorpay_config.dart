class RazorpayConfig {
  // TEST MODE keys (start with rzp_test_)
  static const String keyId = 'rzp_test_YOUR_KEY_ID_HERE'; // Replace!
  static const String keySecret = 'YOUR_KEY_SECRET_HERE'; // Replace!
  
  // Subscription amount (in paise - ₹499 = 49900 paise)
  static const int subscriptionAmount = 49900;
  
  // Business details
  static const String companyName = 'AI Trading Signals';
  static const String description = 'Monthly Premium Subscription';
  static const String currency = 'INR';
  
  // Colors
  static const String brandColor = '#7C3AED'; // Purple
}
