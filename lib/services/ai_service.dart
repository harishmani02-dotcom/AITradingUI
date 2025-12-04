import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
 
class AIService {
  // Get API key from .env file
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  // Get API key from compile-time environment variable (dart-define)
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // System prompt to make AI act as a trading assistant
  static const String _systemPrompt = '''You are an expert Indian stock market trading assistant with deep knowledge of:
- NSE and BSE stocks
- Technical analysis (RSI, MACD, Moving Averages, Support/Resistance)
- Fundamental analysis
- Market trends and sentiment
- Indian stock market regulations

Provide clear, concise, and actionable insights. Use emojis appropriately. 
When discussing stocks, mention current price levels, support/resistance, and trends.
Always remind users to do their own research and that this is not financial advice.
Keep responses focused on Indian stock market (NIFTY, BANKNIFTY, major stocks like TCS, RELIANCE, INFY, HDFC, etc.)''';

  /// Send message to AI and get response
  static Future<String> getAIResponse(String userMessage) async {
    try {
      // Validate API key
      if (_apiKey.isEmpty) {
        return '⚠️ API key not configured!\n\nThe app was not built with an API key.\n\nDevelopers: Build with:\nflutter run --dart-define=GEMINI_API_KEY=your_key';
      }

      // Initialize the Gemini model
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: _apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );

      // Generate response
      final content = Content.text(userMessage);
      final response = await model.generateContent([content]);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        return '❌ Empty response from AI. Please try again.';
      }
    } catch (e) {
      // Handle specific errors
      if (e.toString().contains('API_KEY_INVALID') || 
          e.toString().contains('invalid api key')) {
        return '🔑 Invalid API key!\n\nThe Gemini API key is incorrect or expired.\n\nPlease contact the developer.';
      } else if (e.toString().contains('RESOURCE_EXHAUSTED') || 
                 e.toString().contains('quota')) {
        return '⏳ Rate limit exceeded!\n\nYou\'ve hit the free tier quota. Please wait a moment and try again.';
      } else if (e.toString().contains('SocketException') || 
                 e.toString().contains('network')) {
        return '📡 No internet connection.\n\nPlease check:\n1. WiFi/Mobile data is ON\n2. Internet is working\n3. Try again';
      } else {
        return '❌ Unexpected Error:\n${e.toString()}\n\nPlease try again.';
      }
    }
  }
}
