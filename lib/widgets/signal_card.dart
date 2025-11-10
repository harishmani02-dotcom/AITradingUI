import 'package:flutter/material.dart';
import '../models/signal_model.dart';

class SignalCard extends StatelessWidget {
  final SignalModel signal;
  final bool showDetails;

  const SignalCard({
    super.key,
    required this.signal,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color signalColor = signal.getSignalColor();
    final Color signalBgColor = signal.getSignalBackgroundColor();

    return Container(
      // Reduced vertical margin for a tighter list
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
        padding: const EdgeInsets.all(12), // Reduced internal padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Ticker, Price, and Signal Badge (CONSOLIDATED)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ticker & Price (Smaller Font, single row)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        signal.symbol,
                        style: const TextStyle(
                          fontSize: 18, // Reduced from 24
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price is secondary to Ticker
                      Text(
                        '₹${signal.closePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14, // Reduced from 20
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Signal badge (CONSOLIDATED - moved to the right)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4, // Reduced padding
                  ),
                  decoration: BoxDecoration(
                    color: signalBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        signal.signal.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12, // Reduced from 14
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
            
            const SizedBox(height: 8), // Reduced spacing
            
            // Row 2: Confidence Bar (COMPACT)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Confidence:',
                  style: TextStyle(
                    fontSize: 11, // Smaller font
                    color: const Color(0xFF6B7280).withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect( // Added for cleaner rounded edges
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: signal.confidence / 100,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(signalColor),
                      minHeight: 5, // Reduced minHeight from 8
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${signal.confidence.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12, // Reduced from 14
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),

            // Conditional Content (Analysis Details or Lock Banner)
            if (showDetails) ...[
              const SizedBox(height: 10), // Small spacer
              
              // Analysis details (COMPACT - all on one line)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // RSI text
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
                    child: Text(
                      'Votes: B${signal.buyVotes} / S${signal.sellVotes} / H${signal.holdVotes}',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF6B7280).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Lock Banner (SUPER COMPACT STRIP)
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Much smaller padding
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6), // Smaller radius
                  border: Border.all(color: const Color(0xFFFBBF24), width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFFB45309)),
                    SizedBox(width: 6),
                    Text(
                      'Upgrade for detailed analysis', // Shorter message
                      style: TextStyle(
                        fontSize: 10, // Smaller font
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
    );
  }
}
