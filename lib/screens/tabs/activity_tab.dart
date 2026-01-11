import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:provider/provider.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  int selectedIndex = 0; // 0 -> Deposit, 1 -> Withdrawal, 2 -> ATM Card
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isProcessing = false;
  String _amountText = ''; // Global amount text
  int _enteredAmount = 0; // Global entered amount
  String? _biometricToken; // Store biometric token if biometric auth is used

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0C0E12) : Colors.grey[50];
    final cardGradient = LinearGradient(
      colors: isDark
          ? [Color(0xFF243B64), Color(0xFF0F6B4D)]
          : [Color(0xFF6A4CC8), Color(0xFF00B389)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transactions',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transaction history',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (selectedIndex != 2) // Hide withdraw button for ATM tab
                    ElevatedButton(
                      onPressed: _handleWithdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              selectedIndex == 0 ? 'Deposit' : 'Withdraw',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Gradient balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: cardGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.6 : 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Balance',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '₦0',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Icon button on right
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In Groups',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₦0',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Pending',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '0 transactions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Segmented control for Deposit / Withdrawal / ATM Card
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF15161A) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedIndex == 0
                                ? (isDark
                                    ? const Color(0xFF1E2430)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Deposit',
                              style: TextStyle(
                                color: selectedIndex == 0
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark ? Colors.white70 : Colors.black54),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedIndex == 1
                                ? (isDark
                                    ? const Color(0xFF1E2430)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Withdrawal',
                              style: TextStyle(
                                color: selectedIndex == 1
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark ? Colors.white70 : Colors.black54),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedIndex = 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedIndex == 2
                                ? (isDark
                                    ? const Color(0xFF1E2430)
                                    : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'ATM Card',
                              style: TextStyle(
                                color: selectedIndex == 2
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark ? Colors.white70 : Colors.black54),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Content based on selected tab
              Expanded(
                child: _buildSelectedTabContent(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(bool isDark) {
    switch (selectedIndex) {
      case 0: // Deposit
        return _buildEmptyState(
          isDark: isDark,
          icon: Icons.download_rounded,
          iconColor: const Color(0xFF00C853),
          backgroundColor: isDark
              ? const Color(0xFF0F2A17)
              : const Color(0xFFEFFCF1),
          title: 'No deposits yet',
          subtitle: 'Add funds to start contributing to groups',
        );
      case 1: // Withdrawal
        return _buildEmptyState(
          isDark: isDark,
          icon: Icons.upload_rounded,
          iconColor: const Color(0xFFE53935),
          backgroundColor: isDark
              ? const Color(0xFF2A0F0F)
              : const Color(0xFFFEEFEF),
          title: 'No withdrawals yet',
          subtitle: 'Withdraw funds to your bank account',
        );
      case 2: // ATM Card
        return _buildATMComingSoon(isDark);
      default:
        return Container();
    }
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildATMComingSoon(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ATM Card Illustration
          Container(
            width: 280,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2E3B55), const Color(0xFF1E2A3B)]
                    : [const Color(0xFF4A65B7), const Color(0xFF2E3F7F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Chip
                Positioned(
                  top: 30,
                  left: 25,
                  child: Container(
                    width: 40,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sim_card,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                
                // Contactless Icon
                Positioned(
                  top: 30,
                  right: 25,
                  child: Icon(
                    Icons.wifi,
                    color: Colors.white.withOpacity(0.8),
                    size: 30,
                  ),
                ),
                
                // Card Number
                Positioned(
                  top: 80,
                  left: 25,
                  child: Text(
                    '●●●●   ●●●●   ●●●●   1234',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                
                // Card Holder
                Positioned(
                  bottom: 30,
                  left: 25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARD HOLDER',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JOHN DOE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Expiry
                Positioned(
                  bottom: 30,
                  right: 25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'VALID THRU',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '12/27',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Coming Soon Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? HoopTheme.primaryBlue.withOpacity(0.2)
                  : HoopTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: HoopTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'COMING SOON',
              style: TextStyle(
                color: HoopTheme.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Title
          Text(
            'ATM Card Withdrawals',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Text(
            'Withdraw cash directly from any ATM with your virtual card. '
            'Coming in the next update!',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Features List
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF15161A) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildFeatureItem(
                  isDark: isDark,
                  icon: Icons.credit_card,
                  title: 'Virtual Mastercard',
                  description: 'Get a free virtual card',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  isDark: isDark,
                  icon: Icons.atm,
                  title: 'ATM Withdrawals',
                  description: 'Withdraw cash at any ATM',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  isDark: isDark,
                  icon: Icons.security,
                  title: 'Secure & Safe',
                  description: 'Bank-level security',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Notify Me Button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'We\'ll notify you when ATM withdrawals are available!',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: HoopTheme.primaryBlue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HoopTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Notify Me',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? HoopTheme.primaryBlue.withOpacity(0.15)
                : HoopTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: HoopTheme.primaryBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleWithdraw() async {
    // Reset amount when withdraw is pressed
    _amountText = '';
    _enteredAmount = 0;
    _biometricToken = null;
    
    // Immediately show the amount entry sheet
    _showAmountEntrySheet();
  }

  void _showAmountEntrySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.56,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) {
            int fee = 100;
            return StatefulBuilder(
              builder: (context, setModalState) {
                // Update entered amount based on global amount text
                try {
                  _enteredAmount =
                      int.tryParse(_amountText.replaceAll(',', '')) ?? 0;
                } catch (_) {
                  _enteredAmount = 0;
                }

                final debited = _enteredAmount + fee;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1D27) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3B82F6).withOpacity(0.2)
                                : const Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF3B82F6),
                              width: 2.5,
                            ),
                          ),
                          child: Icon(
                            selectedIndex == 0
                                ? Icons.download_rounded
                                : Icons.upload_rounded,
                            color: const Color(0xFF3B82F6),
                            size: 40,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              selectedIndex == 0
                                  ? 'Deposit Funds'
                                  : 'Withdraw Funds',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedIndex == 0
                                  ? 'Enter the amount you want to deposit.'
                                  : 'Enter the amount you want to withdraw.',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Amount field
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Amount (NGN)',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: TextEditingController(text: _amountText),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF0F1116)
                                : const Color(0xFFF4F6F8),
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white30 : Colors.black38,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onChanged: (v) {
                            _amountText = v;
                            setModalState(() {});
                          },
                        ),

                        const SizedBox(height: 18),

                        if (selectedIndex == 1) // Only show fee for withdrawals
                          // Note box showing fee and debited total
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF8B0000).withOpacity(0.15)
                                  : const Color(0xFFF6EAEA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    const Color(0xFFCC5555).withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text('⚠️',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Note: A withdrawal fee of ₦$fee applies.',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'You will be debited: ₦$debited',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Reset amount when cancelled
                                  _amountText = '';
                                  _enteredAmount = 0;
                                  _biometricToken = null;
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12,
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_enteredAmount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Please enter a valid amount',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  // Close amount sheet
                                  Navigator.of(context).pop();
                                  
                                  if (selectedIndex == 0) {
                                    // Handle deposit
                                    _processDeposit(amount: _enteredAmount);
                                  } else {
                                    // Handle withdrawal with authentication
                                    _authenticateAndProcessWithdrawal(
                                      amount: _enteredAmount,
                                      totalDebited: debited,
                                    );
                                  }
                                  
                                  // Reset amount after proceeding
                                  _amountText = '';
                                  _enteredAmount = 0;
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedIndex == 0
                                      ? HoopTheme.primaryBlue
                                      : const Color(0xFFE53935),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  selectedIndex == 0 ? 'Deposit' : 'Withdraw',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _authenticateAndProcessWithdrawal({
    required int amount,
    required int totalDebited,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    // Check if PIN is set up
    final bool hasPIN = user?.isPinSet ?? false;

    if (!hasPIN) {
      // PIN is not set up
      _showSecuritySetupPrompt();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      bool authenticated = false;
      final bool hasBiometricTransaction =
          user?.biometricTransactionEnabled ?? false;

      if (hasBiometricTransaction) {
        // Try biometrics first if enabled
        final biometricResult = await _authenticateWithBiometrics();
        if (biometricResult['authenticated'] == true) {
          authenticated = true;
          _biometricToken = biometricResult['token']; // Store biometric token
        }
      }

      // If biometrics not enabled or failed, show PIN input
      if (!authenticated) {
        authenticated = await _authenticateWithPIN();
      }

      if (authenticated) {
        // Authentication successful, process withdrawal with single API call
        await _processWithdrawal(
          amount: amount,
          totalDebited: totalDebited,
          biometricToken: _biometricToken,
        );
      } else {
        // Authentication failed or was cancelled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Authentication cancelled or failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Authentication error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        _biometricToken = null; // Reset biometric token
      }
    }
  }

  Future<Map<String, dynamic>> _authenticateWithBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return {'authenticated': false, 'token': null};
      }

      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return {'authenticated': false, 'token': null};
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm withdrawal with biometric authentication',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        sensitiveTransaction: true,
      );

      if (authenticated) {
        // Generate or retrieve biometric token for API call
        // In a real app, this would come from your backend after biometric verification
        final deviceId = await _getDeviceId(); // You need to implement this
        final token = await _generateBiometricToken(deviceId); // Mock function
        
        return {
          'authenticated': true,
          'token': token,
        };
      }

      return {'authenticated': false, 'token': null};
    } catch (e) {
      print('Biometric authentication error: $e');
      return {'authenticated': false, 'token': null};
    }
  }

  // Mock function to get device ID
  Future<String> _getDeviceId() async {
    // In a real app, you would get the actual device ID
    // For example using device_info_plus package
    return 'device-12345';
  }

  // Mock function to generate biometric token
  Future<String?> _generateBiometricToken(String deviceId) async {
    // In a real app, this would call your backend to get a biometric token
    // after successful biometric authentication
    return 'biometric-token-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<bool> _authenticateWithPIN() async {
    final completer = Completer<bool>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String enteredPIN = '';
    bool showPIN = false;
    bool _isVerifyingPIN = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.56,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1D27) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3B82F6).withOpacity(0.2)
                                : const Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF3B82F6),
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF3B82F6),
                            size: 30,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Confirm Withdrawal',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your PIN to confirm the withdrawal',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // PIN Input Field
                        TextField(
                          obscureText: !showPIN,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF0F1116)
                                : const Color(0xFFF4F6F8),
                            hintText: 'Enter PIN',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white30 : Colors.grey[500],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPIN
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color:
                                    isDark ? Colors.white70 : Colors.grey[600],
                              ),
                              onPressed: () {
                                setModalState(() {
                                  showPIN = !showPIN;
                                });
                              },
                            ),
                          ),
                          onChanged: (value) {
                            enteredPIN = value;
                          },
                          onSubmitted: (value) {
                            if (value.length >= 4) {
                              _verifyPIN(value, completer);
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  completer.complete(false);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isVerifyingPIN
                                    ? null
                                    : () {
                                        if (enteredPIN.length >= 4) {
                                          _verifyPIN(enteredPIN, completer);
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'PIN must be at least 4 digits',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HoopTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isVerifyingPIN
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Confirm',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    return completer.future;
  }

  Future<void> _verifyPIN(String enteredPIN, Completer<bool> completer) async {
    bool _isVerifyingPIN = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // In a real app, you would call your API to verify the PIN
      // For now, we'll simulate it
      await Future.delayed(const Duration(milliseconds: 500));

      // For demo, accept any 4-6 digit PIN
      bool isValid = RegExp(r'^[0-9]{4,6}$').hasMatch(enteredPIN);

      if (isValid) {
        Navigator.of(context).pop();
        completer.complete(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid PIN. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        completer.complete(false);
      }
    } catch (e) {
      print('PIN verification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error verifying PIN'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
      completer.complete(false);
    } finally {
      _isVerifyingPIN = false;
    }
  }

  Future<void> _processWithdrawal({
    required int amount,
    required int totalDebited,
    String? biometricToken,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() => _isProcessing = true);

    try {
      // Prepare payload based on authentication method
      final Map<String, dynamic> payload = {
        'amount': amount,
        'totalDebited': totalDebited,
        // Add other withdrawal details as needed
      };

      if (biometricToken != null) {
        // Biometric authentication payload
        payload['biometricToken'] = biometricToken;
        payload['deviceId'] = await _getDeviceId();
      } else {
        // PIN authentication payload
        // Note: In a real app, the PIN would be verified in _verifyPIN
        // and the server would handle the PIN verification
        // For this demo, we're just simulating success
      }

      // TODO: Call your single withdrawal endpoint
      // Example:
      // final response = await authProvider.processWithdrawal(payload);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Withdrawal of ₦$amount requested successfully! You will be debited ₦$totalDebited.',
            ),
            backgroundColor: HoopTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Reset biometric token
      _biometricToken = null;
      
    } catch (e) {
      print('Withdrawal processing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing withdrawal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _processDeposit({required int amount}) {
    // Show success message for deposit
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deposit of ₦$amount requested successfully!',
        ),
        backgroundColor: HoopTheme.successGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSecuritySetupPrompt() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1D27) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Security Required',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'You need to set up a PIN to make withdrawals. '
            'This adds an extra layer of security to protect your funds.\n\n'
            'You can also enable biometric authentication for faster access.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, "/settings/security");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HoopTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Setup Security',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}