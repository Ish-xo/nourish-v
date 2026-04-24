import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ----- Reusable Animation Extensions -----

extension AnimateWidgetExtensions on Widget {
  /// Fade in from transparent
  Widget fadeInAnimation({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return animate(delay: delay).fadeIn(duration: duration);
  }

  /// Slide up from below with fade
  Widget slideUpAnimation({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 500),
    double beginOffset = 30,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .slideY(
          begin: beginOffset / 100,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }

  /// Scale in from small
  Widget scaleInAnimation({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 400),
    double begin = 0.8,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .scale(
          begin: Offset(begin, begin),
          end: const Offset(1, 1),
          duration: duration,
          curve: Curves.easeOutBack,
        );
  }

  /// Slide in from the right
  Widget slideInRightAnimation({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .slideX(
          begin: 0.3,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

/// ----- Cascade Helper for Lists -----

class CascadeAnimationHelper {
  /// Returns a delay for list item at [index] for staggered cascade effect
  static Duration cascadeDelay(int index, {int baseMs = 60}) {
    return Duration(milliseconds: index * baseMs);
  }
}

/// ----- Custom Page Route Transitions -----

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

class FadeScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScalePageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// ----- Pulsing Offline Indicator Widget -----

class PulsingDot extends StatelessWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = const Color(0xFFF39C12),
    this.size = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.4, 1.4),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.4, 1.4),
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
  }
}

/// ----- Tap Scale Button Wrapper -----

class TapScaleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TapScaleWrapper({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<TapScaleWrapper> createState() => _TapScaleWrapperState();
}

class _TapScaleWrapperState extends State<TapScaleWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// ----- Loading Pulse Widget -----

class LoadingPulse extends StatelessWidget {
  final Color? color;
  final double size;

  const LoadingPulse({
    super.key,
    this.color,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final pulseColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: pulseColor,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: pulseColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.2, 1.2),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
              )
              .fadeOut(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}
