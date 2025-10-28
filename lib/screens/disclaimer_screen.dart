import 'package:flutter/material.dart';
 
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Legal Disclaimer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'EDUCATIONAL LEARNING INDICATORS ONLY',
              content:
                  'The signals provided by this application are educational learning indicators generated through automated analysis of publicly available stock market data using technical indicators (RSI, MACD, Bollinger Bands, Volume Analysis, and Candlestick Patterns).',
            ),
            _buildSection(
              title: '⚠️ IMPORTANT DISCLAIMERS:',
              bullets: [
                'These are NOT investment recommendations or financial advice',
                'We are NOT SEBI-registered Research Analysts',
                'Trading and investing in stocks involves substantial risk of loss',
                'Past performance does NOT guarantee future results',
                'You should conduct your own research and due diligence',
                'Consult a registered financial advisor before making investment decisions',
                'We take NO responsibility for your trading profits or losses',
              ],
            ),
            _buildSection(
              title: 'BY USING THIS APP, YOU ACKNOWLEDGE:',
              bullets: [
                'These are educational tools for learning purposes only',
                'You trade and invest at your own risk',
                'We have no liability for your financial outcomes',
                'All trading decisions and their consequences are solely yours',
                'You will not hold us responsible for any losses incurred',
              ],
            ),
            _buildSection(
              title: 'DATA SOURCES:',
              bullets: [
                'Stock data: Yahoo Finance (15-minute delayed)',
                'Analysis: Proprietary algorithms combining 5 technical indicators',
              ],
            ),
            _buildSection(
              title: 'SUBSCRIPTION TERMS:',
              bullets: [
                'Monthly subscription: ₹499/month',
                'Auto-renewal unless cancelled',
                'No refunds for partial months',
                'Cancel anytime from your profile',
              ],
            ),
            _buildSection(
              title: 'PRIVACY:',
              bullets: [
                'We do not store your payment card details',
                'Payments processed securely via Razorpay',
                'We do not share your personal data with third parties',
                'Your trading activity is not tracked or monitored',
              ],
            ),
            _buildSection(
              title: 'ACCURACY DISCLAIMER:',
              bullets: [
                'AI predictions are based on historical patterns',
                'Market conditions can change unpredictably',
                'No system guarantees 100% accuracy',
                'Backtested results may not reflect future performance',
              ],
            ),
            _buildSection(
              title: 'RISK WARNING:',
              bullets: [
                'Stock trading can result in significant financial loss',
                'Only invest money you can afford to lose',
                'Diversify your portfolio to manage risk',
                'Stop-loss orders can help limit losses',
                'Leverage increases both potential gains and losses',
              ],
            ),
            _buildSection(
              title: 'LEGAL COMPLIANCE:',
              bullets: [
                'This app complies with Indian IT Act 2000',
                'Data stored securely following industry standards',
                'User consent obtained for data collection',
                'Right to data deletion upon request',
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('For questions or support:'),
                  const SizedBox(height: 4),
                  const Text('Email: support@aitradingsignals.com'),
                  const Text('Website: www.aitradingsignals.com'),
                  const SizedBox(height: 12),
                  Text(
                    'Last updated: ${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDEFDE0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'By continuing to use this application, you confirm that you have read, understood, and agree to these terms.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
 
  Widget _buildSection({
    required String title,
    String? content,
    List<String>? bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.6,
              ),
            ),
          if (bullets != null)
            ...bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}