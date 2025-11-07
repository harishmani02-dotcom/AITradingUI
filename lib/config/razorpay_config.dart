class RazorpayConfig {
  // Live MODE keys (start with rzp_test_)
  static const String keyId = 'rzp_live_RcukgWczq3ctBB'; // Replace!
  static const String keySecret = '3kcApoYuV3qTUjNZRa1E4bpa'; // Replace!
  
  // Subscription amount (in paise - ₹499 = 49900 paise)
  static const int subscriptionAmount = 100;
  
  // Business details
  static const String companyName = 'AI Trading Signals';
  static const String description = 'Monthly Premium Subscription';
  static const String currency = 'INR';
  
  // Colors
  static const String brandColor = '#7C3AED'; // Purple

  // ⭐ NEW: Environment flag
  static const bool isLiveMode = true; //
}
