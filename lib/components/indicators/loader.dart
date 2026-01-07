// components/ui/wave_loader.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoop/constants/themes.dart';
import 'package:hoop/states/auth_state.dart';

class WaveLoader extends StatefulWidget {
  final double size;
  final Color? waveColor;
  final Duration? waveDuration;

   WaveLoader({
    Key? key,
    this.size = 128,
    this.waveColor,
    this.waveDuration,
  }) : super(key: key);

  @override
  State<WaveLoader> createState() => _WaveLoaderState();
}

class _WaveLoaderState extends State<WaveLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _opacity1;
  late Animation<double> _opacity2;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.waveDuration ?? const Duration(milliseconds: 2200),
    )..repeat();
    
    // First wave animation
    _animation1 = Tween<double>(begin: 1.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _opacity1 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 0.25),
        weight: 0.7,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.25, end: 0.0),
        weight: 0.3,
      ),
    ]).animate(_controller);
    
    // Second wave animation (delayed)
    _animation2 = Tween<double>(begin: 1.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _opacity2 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.40, end: 0.10),
        weight: 0.7,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.10, end: 0.0),
        weight: 0.3,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final avatarUrl = user?.imageUrl;
    final waveColor = widget.waveColor ?? HoopTheme.vibrantOrange;
    final centerSize = widget.size * 0.5; // 50% of the container size
    final waveSize = widget.size * 0.75; // 75% of the container size

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // First expanding wave
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation1.value,
                  child: Opacity(
                    opacity: _opacity1.value,
                    child: Container(
                      width: waveSize,
                      height: waveSize,
                      decoration: BoxDecoration(
                        color: waveColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Second expanding wave (delayed)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation2.value,
                  child: Opacity(
                    opacity: _opacity2.value,
                    child: Container(
                      width: waveSize,
                      height: waveSize,
                      decoration: BoxDecoration(
                        color: waveColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Center avatar container with white border
            Container(
              width: centerSize,
              height: centerSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackAvatar();
                        },
                      )
                    : _buildFallbackAvatar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Center(
      child: Image.asset(
        'assets/images/hoop-inner.png', // Update with your actual asset path
        width: widget.size * 0.3, // 30% of container size
        height: widget.size * 0.3,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // If asset doesn't exist, show default icon
          return Icon(
            Icons.account_circle,
            size: widget.size * 0.3,
            color: HoopTheme.primaryBlue,
          );
        },
      ),
    );
  }
}

// Alternative simplified version without Provider dependency
class SimpleWaveLoader extends StatelessWidget {
  final double size;
  final String? avatarUrl;
  final Color? waveColor;
  final Widget? fallbackWidget;

  const SimpleWaveLoader({
    Key? key,
    this.size = 128,
    this.avatarUrl,
    this.waveColor,
    this.fallbackWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final waveColor = this.waveColor ?? HoopTheme.vibrantOrange;
    final centerSize = size * 0.5;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // First wave
              _buildWave(color: waveColor.withOpacity(0.4), delay: 0),
              // Second wave
              _buildWave(color: waveColor.withOpacity(0.10), delay: 600),
              
              // Center avatar
              Container(
                width: centerSize,
                height: centerSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? Image.network(
                          avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : (fallbackWidget ?? _defaultFallback(size)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWave({
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 4.0),
      duration: const Duration(milliseconds: 2200),
      // delay: Duration(milliseconds: delay),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Opacity(
          opacity: _calculateOpacity(scale),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size * 0.75,
              height: size * 0.75,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateOpacity(double scale) {
    if (scale < 1.7) {
      return 0.85 - (scale - 1) * 0.6; // Fade from 0.85 to 0.25
    } else {
      return 0.25 - (scale - 1.7) * 0.083; // Fade from 0.25 to 0
    }
  }

  Widget _defaultFallback(double size) {
    return Center(
      child: Image.asset(
        'assets/images/hoop-inner.png',
        width: size * 0.3,
        height: size * 0.3,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.account_circle,
            size: size * 0.3,
            color: HoopTheme.primaryBlue,
          );
        },
      ),
    );
  }
}
