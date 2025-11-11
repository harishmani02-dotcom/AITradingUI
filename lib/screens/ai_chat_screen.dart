import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  final List<String> _quickQuestions = [
    "Explain the 'Golden Cross' pattern for a beginner?",
    "What are the risks of using high leverage in trading?",
    "Analyze the importance of Volume in technical analysis.",
    "Give an example of a good stock screening criteria.",
    "What is the theoretical 'Efficient Market Hypothesis'?",
    "How does inflation affect stock valuation?",
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
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
          text: "❌ Network Error: Could not reach the AI service. Please check your connection and try again.",
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
      backgroundColor: const Color(0xFF1A1F2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            // Logo/Icon
            Icon(Icons.rocket_launch_rounded, color: Color(0xFFC084FC), size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Strategist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // WOW Factor Background: Animated Starfield Simulation
          ..._buildStarfield(),

          Column(
            children: [
              // Quick Questions Section
              if (_messages.length == 1)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Questions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC084FC),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickQuestions.map((question) {
                          return InkWell(
                            onTap: () => _sendMessage(question),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D3548),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFC084FC).withOpacity(0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC084FC).withOpacity(0.1),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Text(
                                question,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE2E8F0),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFF2D3548).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3548),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.15),
                                blurRadius: 8,
                              ),
                            ]
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Ask your strategy question...',
                              hintStyle: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
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
                      // Send Button with Glow
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
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: _isTyping 
                              ? null 
                              : () => _sendMessage(_messageController.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WOW Factor: Starfield Background ---
  List<Widget> _buildStarfield() {
    return [
      for (int i = 0; i < 50; i++) 
        AnimatedBuilder(
          animation: _typingController,
          builder: (context, child) {
            final double randomSeed = (i * 0.12345) % 1.0;
            final double baseSize = 1.0 + randomSeed * 2.0;
            final double maxOpacity = 0.3 + randomSeed * 0.7;
            final double travelRange = 1.0 + (i % 10) / 5.0; 

            // Offset the position slightly based on the animation value
            final double xOffset = randomSeed * 0.5;
            final double yOffset = (i % 2 == 0 ? 1 : -1) * randomSeed * 0.5;

            // Simple parallax/twinkle effect by modulating opacity and position
            final double opacity = maxOpacity * (0.5 + 0.5 * (1 + (travelRange * _typingController.value)).remainder(2) - 1).abs();


            return Positioned(
              top: (i * 30.7 + _typingController.value * 200 * travelRange) % MediaQuery.of(context).size.height,
              left: (i * 20.3 + _typingController.value * 150 * travelRange) % MediaQuery.of(context).size.width,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: baseSize,
                  height: baseSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC084FC).withOpacity(0.5),
                        blurRadius: baseSize * 0.5,
                      )
                    ]
                  ),
                ),
              ),
            );
          },
        ),
    ];
  }

  // --- Message Bubble Widget ---
  Widget _buildMessageBubble(ChatMessage message) {
    // Determine the color gradient based on the user/AI role
    final List<Color> bubbleColors = message.isUser
        ? [const Color(0xFF7C3AED), const Color(0xFFC084FC)] // User: Purple Gradient
        : [const Color(0xFF2D3548), const Color(0xFF3B4252)]; // AI: Dark Blue Gradient

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          if (!message.isUser) ...[
            const Icon(Icons.rocket_launch_rounded, color: Color(0xFFC084FC), size: 28),
            const SizedBox(width: 10),
          ],

          // Message Content
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bubbleColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16).copyWith(
                  topLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                  topRight: message.isUser ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white, 
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User Avatar
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

  // --- Typing Indicator Widget ---
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: Color(0xFFC084FC), size: 28),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D3548), Color(0xFF3B4252)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16).copyWith(topLeft: Radius.zero),
            ),
            child: Row(
              children: [
                _buildDot(0),
                const SizedBox(width: 6),
                _buildDot(200),
                const SizedBox(width: 6),
                _buildDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIX: Dot now uses AnimatedBuilder tied to _typingController for smooth, efficient animation
  Widget _buildDot(int delay) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        final double normalizedValue = (_typingController.value + (delay / 600)).remainder(1.0);
        final double opacity = 0.3 + (normalizedValue * 0.7);

        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
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
