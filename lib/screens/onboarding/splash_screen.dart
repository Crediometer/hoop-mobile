// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hoop/constants/strings.dart';
import 'package:hoop/constants/themes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scale = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _slide = Tween(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(

        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return Opacity(
                opacity: _fade.value,
                child: Transform.translate(
                  offset: Offset(0, _slide.value),
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Spacer(),
                        _Logo(),
                        const SizedBox(height: 28),
                        _Title(isDark: isDark),
                        const SizedBox(height: 10),
                        _Tagline(isDark: isDark),
                        const SizedBox(height: 48),
                        const _Loader(),
                        Spacer(),
                        _ParentCompnay(isDark: isDark),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// LOGO
/// ------------------------------------------------------------
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
   
      child: SvgPicture.string(
        LOGO_SVG,
      ),
    );
  }
}


class _Title extends StatelessWidget {
  final bool isDark;
  const _Title({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            HoopTheme.vibrantOrange,
            isDark ? Colors.white : HoopTheme.primaryBlue,
          ],
        ).createShader(bounds);
      },
      child: const Text(
        'HOOP AFRICA',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// TAGLINE
/// ------------------------------------------------------------
class _Tagline extends StatelessWidget {
  final bool isDark;
  const _Tagline({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      'The Community Circle',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: HoopTheme.getTextSecondary(isDark).withOpacity(0.75),
      ),
    );
  }
}

class _ParentCompnay extends StatelessWidget {
  final bool isDark;
  const _ParentCompnay({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      'By Crediometer',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: HoopTheme.getTextSecondary(isDark).withOpacity(0.75),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// LOADER
/// ------------------------------------------------------------
class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor:
            AlwaysStoppedAnimation<Color>(HoopTheme.vibrantOrange),
      ),
    );
  }
}
