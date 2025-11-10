import 'package:flutter/material.dart';
import '../models/signal_model.dart';

class SignalCard extends StatelessWidget {
  final SignalModel signal;
  final bool showDetails;
  final VoidCallback? onTap; // New: Optional tap handler

  const SignalCard({
    super.key,
    required this.signal,
    this.showDetails = true,
    this.onTap, // Initialize the new handler
  });

  // New method to show the detailed analysis dialog
  void _showDetailedAnalysis(BuildContext context) {
    // Determine the primary color for the WOW factor
    final Color primaryColor = signal.getSignalColor();
    final Color secondaryColor = signal.getSignalColor().withOpacity(0.8);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Detailed Analysis",
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, a1, a2, child) {
        // Custom scale and fade transition for the 'envelope' feel
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: a1,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: a1,
            child: child,
          ),
        );
      },
      pageBuilder: (context, a1, a2) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // WOW Factor Color: Gradient background
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B), // Dark Blue/Grey background
                  const Color(0xFF1F2937),
                  secondaryColor.withOpacity(0.15), // Subtle signal color glow
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Symbol, Price, and Signal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signal.symbol,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          '₹${signal.closePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: signal.getSignalBackgroundColor(),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor, width: 1.5),
                      ),
                      child: Text(
                        '${signal.signal.toUpperCase()} ${signal.getSignalEmoji()}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30, color: Colors.white12),
                
                // Detailed Analysis Section
                _buildAnalysisRow(
                  'Overall Confidence',
                  '${signal.confidence.toStringAsFixed(1)}%',
                  Icons.shield_outlined,
                  primaryColor,
                  // Show confidence bar inline
                  LinearProgressIndicator(
                    value: signal.confidence / 100,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                const SizedBox(height: 16),

                // RSI Detail
                _buildAnalysisRow(
                  'Relative Strength Index (RSI)',
                  signal.rsi.toStringAsFixed(1),
                  Icons.show_chart_rounded,
                  Colors.amber,
                  Text(
                    signal.rsi < 30 ? 'Oversold' : (signal.rsi > 70 ? 'Overbought' : 'Neutral Zone'),
                    style: TextStyle(
                      color: signal.rsi < 30 ? Colors.greenAccent : (signal.rsi > 70 ? Colors.redAccent : Colors.yellow),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),

                // Votes Detail
                _buildAnalysisRow(
                  'Expert Consensus Votes',
                  '${signal.buyVotes + signal.sellVotes + signal.holdVotes} Total',
                  Icons.people_alt_outlined,
                  Colors.blueAccent,
                  _buildVoteBreakdown(),
                ),

                const Divider(height: 30, color: Colors.white12),
                
                // Close Button
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: primaryColor.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: primaryColor, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Close Details',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method for the detailed rows
  Widget _buildAnalysisRow(String title, String value, IconData icon, Color color, Widget description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Value and description row
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              description,
            ],
          ),
        ),
      ],
    );
  }

  // Helper method for the vote breakdown
  Widget _buildVoteBreakdown() {
    return Row(
      children: [
        _buildVotePill('B: ${signal.buyVotes}', Colors.greenAccent),
        const SizedBox(width: 10),
        _buildVotePill('S: ${signal.sellVotes}', Colors.redAccent),
        const SizedBox(width: 10),
        _buildVotePill('H: ${signal.holdVotes}', Colors.yellow),
      ],
    );
  }

  // Helper method for vote pills
  Widget _buildVotePill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color signalColor = signal.getSignalColor();

    return GestureDetector(
      onTap: () {
        // Only show detailed analysis if details are available (not locked)
        if (showDetails) {
          _showDetailedAnalysis(context);
        } else {
          // If locked, redirect to subscription screen or show a toast
          if (onTap != null) {
            onTap!(); // Use the passed onTap handler (will go to subscription screen from home_screen)
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🔒 Please upgrade to Premium to view detailed analysis for ${signal.symbol}.',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.amber[700],
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: signalColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Ticker, Price, and Signal Badge (CONSOLIDATED)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          signal.symbol,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${signal.closePrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Signal badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: signal.getSignalBackgroundColor(),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          signal.signal.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: signalColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          signal.getSignalEmoji(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Row 2: Confidence Bar (COMPACT) and Mini Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Conf:',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF6B7280).withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: signal.confidence / 100,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(signalColor),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${signal.confidence.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  // Tap Indicator (envelope-like look)
                  const SizedBox(width: 8),
                  Icon(
                    showDetails ? Icons.insights_rounded : Icons.lock_open_rounded,
                    size: 16,
                    color: showDetails ? signalColor : Colors.amber.shade700,
                  ),
                ],
              ),
              
              // Conditional Content (Compact Analysis or Lock Strip)
              if (showDetails) ...[
                const SizedBox(height: 6),
                // Analysis details (COMPACT - all on one line)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'RSI: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF6B7280).withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: signal.rsi.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Votes (Condensed format: B# / S# / H#)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Votes: B${signal.buyVotes} / S${signal.sellVotes} / H${signal.holdVotes}',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF6B7280).withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Lock Banner (SUPER COMPACT STRIP)
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFBBF24), width: 1),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFFB45309)),
                      SizedBox(width: 6),
                      Text(
                        'Upgrade for detailed analysis',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
