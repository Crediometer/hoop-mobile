// lib/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:hoop/components/buttons/primary_button.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/screens/auth/login_screen.dart';
import 'package:hoop/states/auth_state.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<OnboardingContent> _onboardingContents;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    // Initialize with default theme
    _isDarkMode = false;
    _initializeContent();
  }

  void _initializeContent() {
    _onboardingContents = [
      OnboardingContent(
        title: 'Welcome to Hoop Africa',
        subtitle: 'Where Community Meets Basketball Passion',
        description:
            'Join our vibrant circle of basketball enthusiasts across Africa. Connect, play, and grow together.',
        imageAsset: 'assets/onboarding/community.png',
        icon: Icons.people_alt_rounded,
        circleColor: HoopTheme.vibrantOrange,
        backgroundColor: HoopTheme.vibrantOrange.withOpacity(0.1),
      ),
      OnboardingContent(
        title: 'Community First',
        subtitle: 'We Grow Together',
        description:
            'Connect with players, coaches, and fans in a supportive basketball family. Share experiences and learn from each other.',
        imageAsset: 'assets/onboarding/growth.png',
        icon: Icons.leaderboard,
        circleColor: HoopTheme.primaryBlue, // Use a fixed color instead
        backgroundColor: HoopTheme.primaryBlue.withOpacity(0.1),
      ),
      OnboardingContent(
        title: 'Circle of Excellence',
        subtitle: 'Complete the Hoop',
        description:
            'From grassroots to professional, we complete the basketball journey together. Track progress, set goals, and achieve greatness.',
        imageAsset: 'assets/onboarding/achievement.png',
        icon: Icons.emoji_events,
        circleColor: HoopTheme.successGreen,
        backgroundColor: HoopTheme.successGreen.withOpacity(0.1),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Get theme at build time
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: HoopTheme.getBackgroundColor(_isDarkMode),
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button (only show on first two pages)
            if (_currentPage < _onboardingContents.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                  child: TextButton(
                    onPressed: () {
                      authProv.setNeedsUserOnboarding(false);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: HoopTheme.getTextSecondary(_isDarkMode),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingContents.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  // Handle second page color dynamically
                  Color secondPageColor = index == 1
                      ? HoopTheme.getTextSecondary(_isDarkMode)
                      : _onboardingContents[index].circleColor;

                  Color secondPageBgColor = index == 1
                      ? HoopTheme.getTextSecondary(_isDarkMode).withOpacity(0.1)
                      : _onboardingContents[index].backgroundColor;

                  return OnboardingContent(
                    title: _onboardingContents[index].title,
                    subtitle: _onboardingContents[index].subtitle,
                    description: _onboardingContents[index].description,
                    imageAsset: _onboardingContents[index].imageAsset,
                    icon: _onboardingContents[index].icon,
                    circleColor: index == 1
                        ? secondPageColor
                        : _onboardingContents[index].circleColor,
                    backgroundColor: index == 1
                        ? secondPageBgColor
                        : _onboardingContents[index].backgroundColor,
                  );
                },
              ),
            ),

            // Navigation Dots and Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                children: [
                  // Dots Indicator
                  OnboardingDots(
                    currentPage: _currentPage,
                    totalPages: _onboardingContents.length,
                    activeColor: _currentPage == 1
                        ? HoopTheme.getTextSecondary(_isDarkMode)
                        : _onboardingContents[_currentPage].circleColor,
                    isDarkMode: _isDarkMode,
                  ),

                  const SizedBox(height: 32.0),

                  // Next/Get Started Button
                  SizedBox(
                    width: double.infinity,
                    child: HoopButton(
                      onPressed: () {
                        if (_currentPage < _onboardingContents.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        } else {
                          // Navigate to login/signup
                          authProv.setNeedsUserOnboarding(false);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      buttonText: _currentPage < _onboardingContents.length - 1
                          ? 'Next'
                          : 'Get Started',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String imageAsset;
  final IconData icon;
  final Color circleColor;
  final Color backgroundColor;

  const OnboardingContent({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageAsset,
    required this.icon,
    required this.circleColor,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Animated Circle with Icon
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Circle
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: circleColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Middle Circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: circleColor.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Inner Circle with Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: circleColor.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 40, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: circleColor,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HoopTheme.getTextPrimary(_isDarkMode),
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: HoopTheme.getTextSecondary(_isDarkMode),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Decorative Circles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDecorativeCircle(circleColor, 0.3, 12),
                const SizedBox(width: 8),
                _buildDecorativeCircle(circleColor, 0.5, 16),
                const SizedBox(width: 8),
                _buildDecorativeCircle(circleColor, 0.7, 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(Color color, double opacity, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class OnboardingDots extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color activeColor;
  final bool isDarkMode;

  const OnboardingDots({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.activeColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 30 : 12,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? activeColor
                : HoopTheme.getTextSecondary(isDarkMode).withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
