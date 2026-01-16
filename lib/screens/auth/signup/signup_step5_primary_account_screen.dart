import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/states/OnboardingService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoop/screens/tabs/community_tab.dart';

class SetupPrimaryAccountScreen extends StatefulWidget {
  const SetupPrimaryAccountScreen({super.key, required bool popOnAdd});

  @override
  State<SetupPrimaryAccountScreen> createState() =>
      _SetupPrimaryAccountScreenState();
}

class _SetupPrimaryAccountScreenState extends State<SetupPrimaryAccountScreen> {
  String? selectedBank;
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController accountNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fieldBg = isDark ? const Color(0xFF1E2235) : const Color(0xFFF1F3F6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black45;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1016) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1F2E)
                    : const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: Colors.orangeAccent,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              "Setup Primary Account",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Add your bank account for transactions",
              style: TextStyle(color: hintColor, fontSize: 15),
            ),
            const SizedBox(height: 30),

            // Bank Name dropdown
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Bank Name",
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBank,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: hintColor,
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E2235)
                      : Colors.white,
                  hint: Text(
                    "Select your bank",
                    style: TextStyle(color: hintColor),
                  ),
                  items:
                      [
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
                          ]
                          .map(
                            (toElement) => DropdownMenuItem(
                              value: toElement,
                              child: Text(toElement),
                            ),
                          )
                          .toList(),

                  onChanged: (value) {
                    setState(() => selectedBank = value);
                  },
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Account Number Field
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Account Number",
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: accountNumberController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Enter your account number",
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Account Name Field
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Account Name",
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: accountNameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Enter account holder name",
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Secure Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF141827)
                    : const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Secure & Encrypted",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Your banking information is encrypted and secure. We never store your login credentials.",
                          style: TextStyle(color: hintColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Add Account Button
            HoopButton(
              buttonText: "Add Account",
              onPressed: () async {
                // Proceed to verification step; when it returns true, bubble up
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerifyPrimaryAccountScreen(),
                  ),
                );
                if (ok == true) {
                  if (mounted) Navigator.pop(context, true);
                }
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';

class VerifyPrimaryAccountScreen extends StatefulWidget {
  const VerifyPrimaryAccountScreen({super.key});

  @override
  State<VerifyPrimaryAccountScreen> createState() =>
      _VerifyPrimaryAccountScreenState();
}

class _VerifyPrimaryAccountScreenState
    extends State<VerifyPrimaryAccountScreen> {
  bool isAgreed = false;
  Duration remaining = const Duration(minutes: 9, seconds: 46);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final secondsLeft = 9 * 60 + 46 - elapsed.inSeconds;
    if (secondsLeft <= 0) {
      _ticker.stop();
      setState(() => remaining = Duration.zero);
    } else {
      setState(() => remaining = Duration(seconds: secondsLeft));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C1F2E) : Colors.white;
    final bgColor = isDark ? const Color(0xFF0E1016) : const Color(0xFFF6F8FC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1F2E)
                    : const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: Colors.orangeAccent,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              "Setup Primary Account",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Add your bank account for transactions",
              style: TextStyle(color: subTextColor, fontSize: 15),
            ),
            const SizedBox(height: 30),

            // Consent Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Consent",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "I authorize Hoop to debit my primary bank account for contributions and payouts.",
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: isAgreed,
                        onChanged: (v) => setState(() => isAgreed = v ?? false),
                        activeColor: isDark
                            ? Colors.blueAccent
                            : const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "I agree to the mandate terms.",
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Verify with Micro-Transfer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Verify with Micro-Transfer",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Send ₦100.00 to verify your mandate.",
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  _buildRow("Amount", "₦100.00", textColor, subTextColor),
                  const SizedBox(height: 8),
                  _buildRow(
                    "Account Number",
                    "0123456789",
                    textColor,
                    subTextColor,
                  ),
                  const SizedBox(height: 8),
                  _buildRow("Bank", "GTBank (058)", textColor, subTextColor),
                  const SizedBox(height: 8),
                  _buildRow(
                    "Time remaining",
                    _formattedTime,
                    textColor,
                    subTextColor,
                    isTime: true,
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: HoopButton(
                          onPressed: isAgreed
                              ? () async {
                                  try {
                                    await OnboardingService.markOnboardingComplete();

                                    Navigator.pop(context, true);
                                  } on Exception catch (e) {
                                    debugPrint("Stakkkkk -==== "+e.toString());
                                    // TODO
                                  }
                                }
                              : null,
                          buttonText: "I have sent ₦100.00",
                          disabled: !isAgreed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white30
                                  : const Color(0xFF1E3A8A),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Back",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    Color textColor,
    Color subTextColor, {
    bool isTime = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTime ? Colors.blueAccent : textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Simple ticker class for countdown
class Ticker {
  final void Function(Duration) onTick;
  bool _running = false;
  final Stopwatch _stopwatch = Stopwatch();

  Ticker(this.onTick);

  void start() {
    _running = true;
    _stopwatch.start();
    _tick();
  }

  void _tick() async {
    while (_running) {
      await Future.delayed(const Duration(seconds: 1));
      onTick(_stopwatch.elapsed);
    }
  }

  void stop() {
    _running = false;
    _stopwatch.stop();
  }

  void dispose() => stop();
}

/// ✅ Success Screen (after Add Account)
// import 'package:flutter/material.dart';

class AddAccountScreen extends StatelessWidget {
  const AddAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1016) : Colors.white,
      appBar: AppBar(
        title: Text(
          "Setup Primary Account",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Bank Name",
                hintText: "Select your bank",
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E2235)
                    : const Color(0xFFF6F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Account Number",
                hintText: "Enter your account number",
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E2235)
                    : const Color(0xFFF6F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Account Name",
                hintText: "Enter your account name",
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E2235)
                    : const Color(0xFFF6F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1A6C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SuccessScreen()),
                  );
                },
                child: const Text(
                  "Add Account",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final boxColor = isDark ? const Color(0xFF1E2235) : const Color(0xFFF6F6F9);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1016) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Setup Primary Account",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2235)
                    : const Color(0xFFF2F4FF),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(15),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFF0B1A6C),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Setup Primary Account",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Add your bank account for transactions",
              style: TextStyle(color: subColor, fontSize: 15),
            ),
            const SizedBox(height: 30),

            // Consent section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Consent",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "I authorize Hoop to debit my primary bank account for contributions and payouts.",
                    style: TextStyle(color: subColor, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: true,
                        onChanged: (_) {},
                        activeColor: const Color(0xFF0B1A6C),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "I agree to the mandate terms.",
                          style: TextStyle(color: subColor, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Verify section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Verify with Micro-Transfer",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Send ₦100.00 to verify your mandate.",
                    style: TextStyle(color: subColor, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  _buildKeyValueRow("Amount", "₦100.00", textColor, subColor),
                  const SizedBox(height: 8),
                  _buildKeyValueRow(
                    "Account Number",
                    "0123456789",
                    textColor,
                    subColor,
                  ),
                  const SizedBox(height: 8),
                  _buildKeyValueRow(
                    "Bank",
                    "GTBank (058)",
                    textColor,
                    subColor,
                  ),
                  const SizedBox(height: 8),
                  _buildKeyValueRow(
                    "Time remaining",
                    "09:46",
                    textColor,
                    subColor,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1A6C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MandateActivatedScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text("I have sent ₦100.00"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyValueRow(
    String key,
    String value,
    Color textColor,
    Color subColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: TextStyle(color: subColor, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class MandateActivatedScreen extends StatelessWidget {
  const MandateActivatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final bgColor = isDark ? const Color(0xFF0E1016) : Colors.white;
    final iconBg = isDark ? const Color(0xFF1E2235) : const Color(0xFFF2F4FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Setup Primary Account",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Wallet Icon
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(15),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF0B1A6C),
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              "Setup Primary Account",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Add your bank account for transactions",
              style: TextStyle(color: subColor, fontSize: 15),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Green Circle with check icon
            Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(24),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),

            // Mandate Activated
            Text(
              "Mandate Activated",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your primary account is set up. You can now contribute and receive payouts automatically.",
              textAlign: TextAlign.center,
              style: TextStyle(color: subColor, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Go to Home Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1A6C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const CommunityScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Go to Home",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
