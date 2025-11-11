
import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark navy background
      appBar: AppBar(
        title: const Text(
          'Legal Disclaimer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main warning card
            _buildWarningCard(),
            const SizedBox(height: 16),
            
            // Educational purpose card
            _buildInfoCard(
              icon: Icons.school_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: 'EDUCATIONAL LEARNING INDICATORS ONLY',
              content:
                  'The signals provided by this application are educational learning indicators generated through automated analysis of publicly available stock market data using technical indicators (RSI, MACD, Average True Range (ATR), Exponential Moving Averages, Bollinger Bands, Volume Analysis, and Candlestick Patterns).',
            ),
            const SizedBox(height: 16),
            
            // Important disclaimers card
            _buildListCard(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFEF4444),
              title: '⚠️ IMPORTANT DISCLAIMERS',
              items: [
                'These are NOT investment recommendations or financial advice',
                'We are NOT SEBI-registered Research Analysts',
                'Trading and investing in stocks involves substantial risk of loss',
                'Past performance does NOT guarantee future results',
                'You should conduct your own research and due diligence',
                'Consult a registered financial advisor before making investment decisions',
                'We take NO responsibility for your trading profits or losses',
              ],
            ),
            const SizedBox(height: 16),
            
            // Acknowledgment card
            _buildListCard(
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF10B981),
              title: 'BY USING THIS APP, YOU ACKNOWLEDGE',
              items: [
                'These are educational tools for learning purposes only',
                'You trade and invest at your own risk',
                'We have no liability for your financial outcomes',
                'All trading decisions and their consequences are solely yours',
                'You will not hold us responsible for any losses incurred',
              ],
            ),
            const SizedBox(height: 16),
            
            // Data sources card
            _buildListCard(
              icon: Icons.data_usage,
              iconColor: const Color(0xFF3B82F6),
              title: 'DATA SOURCES',
              items: [
                'Stock data: Yahoo Finance (15-minute delayed)',
                'Analysis: Proprietary algorithms combining 5 technical indicators',
              ],
            ),
            const SizedBox(height: 16),
            
            // Subscription terms card
            _buildListCard(
              icon: Icons.payment,
              iconColor: const Color(0xFF8B5CF6),
              title: 'SUBSCRIPTION TERMS',
              items: [
                'Monthly subscription: ₹499/month',
                'Auto-renewal unless cancelled',
                'No refunds for partial months',
                'Cancel anytime from your profile',
              ],
            ),
            const SizedBox(height: 16),
            
            // Privacy card
            _buildListCard(
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF06B6D4),
              title: 'PRIVACY',
              items: [
                'We do not store your payment card details',
                'Payments processed securely via Razorpay',
                'We do not share your personal data with third parties',
                'Your trading activity is not tracked or monitored',
              ],
            ),
            const SizedBox(height: 16),
            
            // Accuracy disclaimer card
            _buildListCard(
              icon: Icons.analytics_outlined,
              iconColor: const Color(0xFFF59E0B),
              title: 'ACCURACY DISCLAIMER',
              items: [
                'AI predictions are based on historical patterns',
                'Market conditions can change unpredictably',
                'No system guarantees 100% accuracy',
                'Backtested results may not reflect future performance',
              ],
            ),
            const SizedBox(height: 16),
            
            // Risk warning card
            _buildListCard(
              icon: Icons.dangerous_outlined,
              iconColor: const Color(0xFFEF4444),
              title: 'RISK WARNING',
              items: [
                'Stock trading can result in significant financial loss',
                'Only invest money you can afford to lose',
                'Diversify your portfolio to manage risk',
                'Stop-loss orders can help limit losses',
                'Leverage increases both potential gains and losses',
              ],
            ),
            const SizedBox(height: 16),
            
            // Legal compliance card
            _buildListCard(
              icon: Icons.gavel,
              iconColor: const Color(0xFF10B981),
              title: 'LEGAL COMPLIANCE',
              items: [
                'This app complies with Indian IT Act 2000',
                'Data stored securely following industry standards',
                'User consent obtained for data collection',
                'Right to data deletion upon request',
              ],
            ),
            const SizedBox(height: 16),
            
            // Contact information card
            _buildContactCard(),
            const SizedBox(height: 16),
            
            // Agreement card
            _buildAgreementCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.2),
            const Color(0xFFDC2626).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFEF4444),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Please read all disclaimers carefully before using this app',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
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

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.2),
            const Color(0xFF2563EB).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.contact_support_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'CONTACT INFORMATION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactRow(Icons.email_outlined, 'support@aitradingsignals.com'),
          const SizedBox(height: 8),
          _buildContactRow(Icons.language, 'www.aitradingsignals.com'),
          const SizedBox(height: 12),
          Text(
            'Last updated: ${DateTime.now().year}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.2),
            const Color(0xFF059669).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'By continuing to use this application, you confirm that you have read, understood, and agree to these terms.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

