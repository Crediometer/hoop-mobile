import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/constants/themes.dart';

class MarketStormTab extends StatefulWidget {
  const MarketStormTab({super.key});

  @override
  State<MarketStormTab> createState() => _MarketStormTabState();
}

class _MarketStormTabState extends State<MarketStormTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff0E1318) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.grey.shade700;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 24),
                // HOW IT WORKS
                _buildSectionTitle('How It Works'),
                const SizedBox(height: 12),
                ..._buildSteps(isDark),

                const SizedBox(height: 24),

                // EXAMPLE
                _buildSectionTitle('Example'),
                const SizedBox(height: 12),
                _buildExampleCard(isDark),

                const SizedBox(height: 24),

                // BENEFITS
                _buildSectionTitle('Benefits'),
                const SizedBox(height: 12),
                _buildBenefitsGrid(isDark),

                const SizedBox(height: 24),

                // NOTIFY ME
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: 40,
                        color: HoopTheme.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Get Notified at Launch',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to join when we launch',
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: HoopButton(
                          buttonText: 'Notify Me',
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildSteps(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.grey.shade700;

    return [
      _buildStep(
        '1',
        'Trader creates group',
        'Sets up a rotational buying group',
        isDark,
      ),
      _buildStep(
        '2',
        'Members join & contribute',
        'Weekly payments from all members',
        isDark,
      ),
      _buildStep(
        '3',
        'Trader receives funds',
        'Collects all weekly contributions',
        isDark,
      ),
      _buildStep(
        '4',
        'Weekly product delivery',
        'One member receives products each week',
        isDark,
      ),
    ];
  }

  Widget _buildStep(
    String number,
    String title,
    String description,
    bool isDark,
  ) {
    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.grey.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: HoopTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildExampleRow('Group size', '10 members', isDark),
          _buildExampleRow('Weekly contribution', '₦10,000', isDark),
          _buildExampleRow('Weekly pot', '₦100,000', isDark),
          _buildExampleRow('Cycle duration', '10 weeks', isDark),
        ],
      ),
    );
  }

  Widget _buildExampleRow(String label, String value, bool isDark) {
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildBenefitCard('Affordable Products', Icons.shopping_bag, isDark),
        _buildBenefitCard('Trusted Traders', Icons.verified_user, isDark),
        _buildBenefitCard('Weekly Payments', Icons.calendar_today, isDark),
        _buildBenefitCard('Guaranteed Delivery', Icons.security, isDark),
      ],
    );
  }

  Widget _buildBenefitCard(String title, IconData icon, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:  HoopTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color:  HoopTheme.primaryBlue, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
