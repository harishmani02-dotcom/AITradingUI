import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
 
class AIService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Get API key from .env file
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
 
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
      if (_apiKey.isEmpty || _apiKey == 'your_groq_api_key_here') {
        return '⚠️ API key not configured!\n\nSteps to fix:\n1. Go to https://console.groq.com/keys\n2. Create a FREE API key\n3. Add it to your .env file:\nGROQ_API_KEY=gsk_your_key_here';
      }
 
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile', // UPDATED MODEL - Currently supported
          'messages': [
            {
              'role': 'system',
              'content': _systemPrompt,
            },
            {
              'role': 'user',
              'content': userMessage,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
          'top_p': 1,
          'stream': false,
        }),
      );
 
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['choices'][0]['message']['content'];
        return aiMessage.trim();
      } else if (response.statusCode == 401) {
        return '🔑 Invalid API key!\n\nYour API key is incorrect.\n\nSteps to fix:\n1. Go to https://console.groq.com/keys\n2. Create a new API key\n3. Update your .env file:\nGROQ_API_KEY=gsk_your_new_key';
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Bad request';
        return '❌ API Error 400:\n$errorMessage\n\nPlease check:\n1. API key is correct\n2. Model name is valid\n3. Request format is correct';
      } else if (response.statusCode == 429) {
        return '⏳ Rate limit exceeded!\n\nToo many requests. Please wait a moment and try again.';
      } else {
        return '❌ Error ${response.statusCode}\n\nResponse: ${response.body}\n\nPlease try again or contact support.';
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('HandshakeException')) {
        return '📡 No internet connection.\n\nPlease check:\n1. WiFi/Mobile data is ON\n2. Internet is working\n3. Try again';
      }
      return '❌ Unexpected Error:\n${e.toString()}\n\nPlease try again.';
    }
  }
}
 
