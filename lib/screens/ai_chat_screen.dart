import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // NOTE: Updated with the latest key provided by the user (November 2025).
  static const String _groqApiKey = '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';
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqModel = 'mixtral-8x7b-32768';

  // We are storing a history of messages here for context.
  static final List<Map<String, String>> _chatHistory = [
    {
      "role": "system",
      "content": "You are a professional and extremely fast AI Market Strategist and financial assistant. Provide concise, expert answers about stock market concepts, analysis, and trading strategies. Keep responses brief and relevant to the user's question."
    }
  ];

  static Future<String> getAIResponse(String userQuery) async {
    // 1. Add the new user query to the history
    _chatHistory.add({
      "role": "user",
      "content": userQuery,
    });

    final payload = {
      "model": _groqModel,
      "messages": _chatHistory,
      "temperature": 0.7,
      "max_tokens": 1000,
    };

    try {
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponseText = data['choices'][0]['message']['content'] as String;
        
        // 2. Add the AI response to the history for context in future messages
        _chatHistory.add({
          "role": "assistant",
          "content": aiResponseText,
        });

        return aiResponseText;
      } else if (response.statusCode == 401) {
        // Specific handling for Invalid API Key (401 Unauthorized)
        return "⚠️ **API Key Invalid/Expired.** Please ensure the Groq API key is correct in `lib/services/ai_service.dart`. Status 401: Unauthorized.";
      } 
      else {
        // General API error handling
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'API Error ${response.statusCode}';
        return "❌ Groq API Error: $errorMessage";
      }
    } catch (e) {
      // Network or processing error
      return "❌ Network or processing error. Check your internet connection or Groq service status.";
    }
  }
}
