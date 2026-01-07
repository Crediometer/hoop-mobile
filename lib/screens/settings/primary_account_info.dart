// screens/account/primary_account_screen.dart
import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/back_button.dart';
import 'package:hoop/constants/themes.dart';

class PrimaryAccountScreen extends StatefulWidget {
  const PrimaryAccountScreen({super.key});

  @override
  State<PrimaryAccountScreen> createState() => _PrimaryAccountScreenState();
}

class _PrimaryAccountScreenState extends State<PrimaryAccountScreen> {
  String selectedAccount = "account-1";
  bool showAddAccount = false;

  final Map<String, dynamic> newAccount = {
    'bankName': '',
    'accountNumber': '',
    'accountName': '',
    'accountType': 'savings',
  };

  final Map<String, dynamic> account = {
    'id': 'account-1',
    'bankName': 'First Bank',
    'accountNumber': '****1234',
    'accountName': 'John Doe',
    'accountType': 'Savings',
    'isPrimary': true,
    'isVerified': true,
  };

  final List<String> nigerianBanks = [
    "Access Bank",
    "First Bank",
    "GTBank",
    "UBA",
    "Zenith Bank",
    "Fidelity Bank",
    "FCMB",
    "Sterling Bank",
    "Union Bank",
    "Wema Bank",
    "Polaris Bank",
    "Stanbic IBTC",
    "Heritage Bank",
    "Keystone Bank",
  ];

  void _handleSetPrimary(String accountId) {
    setState(() {
      selectedAccount = accountId;
    });
    // Here you would typically make an API call to update the primary account
  }

  void _handleAddAccount() {
    // Here you would typically make an API call to add the new account
    setState(() {
      showAddAccount = false;
      newAccount['bankName'] = '';
      newAccount['accountNumber'] = '';
      newAccount['accountName'] = '';
      newAccount['accountType'] = 'savings';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  HoopBackButton(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Account',
                        style: TextStyle(
                          color: HoopTheme.primaryBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your withdrawal accounts',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Info Banner
                    Container(
                      decoration: BoxDecoration(
                        color: HoopTheme.lightBlue,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: HoopTheme.primaryBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: HoopTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Primary Account Info',
                                  style: TextStyle(
                                    color: HoopTheme.primaryBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your primary account is used for automatic withdrawals when groups mature. You can change this anytime and add multiple accounts for backup.',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Current Accounts
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Accounts',
                          style: TextStyle(
                            color: HoopTheme.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAccountCard(account),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Account Verification Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Security',
                          style: TextStyle(
                            color: HoopTheme.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: HoopTheme.successGreen.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.verified,
                                      size: 20,
                                      color: HoopTheme.successGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bank Verification Number (BVN)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Linked and verified',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: HoopTheme.successGreen.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.phone_android,
                                      size: 20,
                                      color: HoopTheme.successGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Phone Number',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '+234 *** *** **34 • Verified',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
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
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Transaction Limits
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Limits',
                          style: TextStyle(
                            color: HoopTheme.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Daily Withdrawal Limit',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '₦500,000',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Monthly Withdrawal Limit',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '₦5,000,000',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Minimum Withdrawal',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '₦1,000',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.grey[400] : Colors.grey[600];
    final isPrimary = account['isPrimary'] == true;
    final isVerified = account['isVerified'] == true;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary ? HoopTheme.primaryBlue : Colors.grey[200]!,
          width: isPrimary ? 2 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? HoopTheme.primaryBlue
                            : isDark
                            ? Colors.white10
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        color: isPrimary ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              account['bankName'],
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isPrimary)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: HoopTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Primary',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? HoopTheme.successGreen
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isVerified ? Icons.check : Icons.info_outline,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${account['accountNumber']} • ${account['accountType']}',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account['accountName'],
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (!isPrimary)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _handleSetPrimary(account['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HoopTheme.primaryBlue,
                      side: BorderSide(color: HoopTheme.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Set as Primary',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Add Account Dialog (Optional - if you want to implement the add account functionality)
class AddAccountDialog extends StatefulWidget {
  final Map<String, dynamic> newAccount;
  final List<String> nigerianBanks;
  final VoidCallback onAddAccount;
  final Function(String, String) onAccountUpdate;

  const AddAccountDialog({
    super.key,
    required this.newAccount,
    required this.nigerianBanks,
    required this.onAddAccount,
    required this.onAccountUpdate,
  });

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  String? _selectedBank;

  @override
  void initState() {
    super.initState();
    _selectedBank = widget.nigerianBanks.isNotEmpty
        ? widget.nigerianBanks[0]
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedBank,
            onChanged: (value) {
              setState(() {
                _selectedBank = value;
              });
            },
            items: widget.nigerianBanks.map((bank) {
              return DropdownMenuItem(value: bank, child: Text(bank));
            }).toList(),
            decoration: const InputDecoration(
              labelText: 'Bank Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accountNumberController,
            decoration: const InputDecoration(
              labelText: 'Account Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accountNameController,
            decoration: const InputDecoration(
              labelText: 'Account Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: 'savings',
            onChanged: (value) {
              // Handle account type change
            },
            items: const [
              DropdownMenuItem(value: 'savings', child: Text('Savings')),
              DropdownMenuItem(value: 'current', child: Text('Current')),
            ],
            decoration: const InputDecoration(
              labelText: 'Account Type',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedBank != null &&
                _accountNumberController.text.isNotEmpty &&
                _accountNameController.text.isNotEmpty) {
              widget.onAddAccount();
              Navigator.pop(context);
            }
          },
          child: const Text('Add Account'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }
}
