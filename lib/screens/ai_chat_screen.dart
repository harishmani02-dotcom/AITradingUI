import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  // Animation for the starfield effect
  late AnimationController _starfieldController;

  // --- MODIFIED QUICK QUESTIONS (Theoretical Stock Market) ---
  final List<String> _quickQuestions = [
    "Explain the concept of 'Technical Analysis' for beginners.",
    "What are three key risks when investing in penny stocks?",
    "How does a stock split affect investor portfolio value?",
    "Define the 'Beta' of a stock and its significance.",
    "What is the difference between a 'Bull Trap' and a 'Bear Trap'?",
    "Give an example of a simple 'Swing Trading' strategy.",
  ];
  // -----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    
    // Initialize Starfield Animation
    _starfieldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _starfieldController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "👋 Hello! I'm your AI Market Strategist. Ask me anything about stock market concepts, analysis, and trading strategies!",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Assuming AIService.getAIResponse is available and functional
      final aiResponse = await AIService.getAIResponse(text);
      
      setState(() {
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "❌ Network Error. Please check your connection or try a less complex query.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark space theme background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFC084FC)], // Brighter purple gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Strategist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Market Intelligence',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // --- WOW Factor: Animated Starfield Background ---
          AnimatedBuilder(
            animation: _starfieldController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0, 
                  _starfieldController.value * 200 // Slow vertical drift
                ), 
                child: Opacity(
                  opacity: 0.15,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.5,
                        colors: [
                          Color(0xFF1E293B),
                          Color(0xFF0F172A),
                        ]
                      )
                    ),
                    child: CustomPaint(
                      painter: StarfieldPainter(_starfieldController.value),
                      child: Container(),
                    ),
                  ),
                ),
              );
            },
          ),
          // ----------------------------------------------------

          Column(
            children: [
              // Quick Questions Section
              if (_messages.length == 1) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Starter Concepts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC084FC),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _quickQuestions.map((question) {
                          return InkWell(
                            onTap: () => _sendMessage(question),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: const Color(0xFF7C3AED).withOpacity(0.6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                question,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE2E8F0),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),

              // Input Area
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3548),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Ask your strategy question...',
                    hintStyle: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  enabled: !_isTyping,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: _isTyping 
                    ? const LinearGradient(
                        colors: [Color(0xFF4B5563), Color(0xFF4B5563)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                shape: BoxShape.circle,
                boxShadow: _isTyping ? [] : [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                onPressed: _isTyping 
                    ? null 
                    : () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // Wow factor: Use a slight gradient and bolder colors
    final Color bubbleColor = message.isUser
        ? const Color(0xFF7C3AED) // User purple
        : const Color(0xFF2D3548); // AI dark grey

    final BorderRadius userRadius = BorderRadius.only(
      topLeft: Radius.circular(message.isUser ? 16 : 4),
      topRight: const Radius.circular(16),
      bottomLeft: const Radius.circular(16),
      bottomRight: Radius.circular(message.isUser ? 4 : 16),
    );
    
    final BorderRadius aiRadius = BorderRadius.only(
      topLeft: Radius.circular(message.isUser ? 16 : 4),
      topRight: const Radius.circular(16),
      bottomLeft: const Radius.circular(16),
      bottomRight: Radius.circular(message.isUser ? 4 : 16),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: message.isUser ? userRadius : aiRadius,
                border: message.isUser ? null : Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                boxShadow: message.isUser ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isUser 
                          ? Colors.white 
                          : const Color(0xFFE2E8F0),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3548),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF7C3AED),
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3548),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildPulsingDot(const Duration(milliseconds: 0)),
                const SizedBox(width: 6),
                _buildPulsingDot(const Duration(milliseconds: 200)),
                const SizedBox(width: 6),
                _buildPulsingDot(const Duration(milliseconds: 400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot(Duration delay) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF94A3B8).withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      // Use a custom animation to simulate continuous pulsing
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final adjustedValue = (value + delay.inMilliseconds / 1000) % 1.0;
          final scale = 0.8 + adjustedValue * 0.4; // Scale between 0.8 and 1.2
          return Transform.scale(
            scale: scale < 1.0 ? scale : 2.0 - scale, // Bounce effect
            child: Opacity(
              opacity: 0.5 + adjustedValue * 0.5,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
        onEnd: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// Custom Painter for a subtle Starfield effect
class StarfieldPainter extends CustomPainter {
  final double animationValue;

  StarfieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.7);
    final random = (seed) => (size.width * 0.5 * (seed * 999) % 1) + (animationValue * 50);

    for (int i = 0; i < 100; i++) {
      final x = (i * 7) % size.width;
      final y = (i * 11 + (animationValue * size.height * 0.5)) % size.height;
      final radius = 0.5 + (i % 3) * 0.5;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Draw a few larger, slower moving stars
    for (int i = 0; i < 10; i++) {
      final x = (i * 20 + 5) % size.width;
      final y = (i * 30 + 10 + (animationValue * size.height * 0.1)) % size.height;
      final radius = 1.5 + (i % 2) * 0.5;
      
      canvas.drawCircle(Offset(x, y), radius, paint..color = const Color(0xFFC084FC).withOpacity(0.5));
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
