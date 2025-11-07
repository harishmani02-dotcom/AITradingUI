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
      if (_apiKey.isEmpty) {
        return '⚠️ API key not configured. Please add your Groq API key to the .env file.';
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-70b-versatile', // Fast and powerful model
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
        return '🔑 Invalid API key. Please check your Groq API key in .env file.';
      } else if (response.statusCode == 429) {
        return '⏳ Too many requests. Please wait a moment and try again.';
      } else {
        return '❌ Error: ${response.statusCode}. Please try again.';
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        return '📡 No internet connection. Please check your network.';
      }
      return '❌ Error: ${e.toString()}';
    }
  }

  /// Get streaming response (optional - for real-time typing effect)
  static Stream<String> getAIResponseStream(String userMessage) async* {
    try {
      if (_apiKey.isEmpty) {
        yield '⚠️ API key not configured.';
        return;
      }

      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });
      
      request.body = jsonEncode({
        'model': 'llama-3.1-70b-versatile',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': userMessage}
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
        'stream': true,
      });

      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode == 200) {
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ') && line != 'data: [DONE]') {
              try {
                final jsonStr = line.substring(6);
                final data = jsonDecode(jsonStr);
                final content = data['choices'][0]['delta']['content'];
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                // Skip invalid JSON
              }
            }
          }
        }
      } else {
        yield '❌ Error: ${streamedResponse.statusCode}';
      }
    } catch (e) {
      yield '❌ Error: ${e.toString()}';
    }
  }
}
