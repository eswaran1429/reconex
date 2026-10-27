import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reconex/core/custom_widgets/custom_sizedbox/custom_sizedbox.dart';
import 'package:reconex/core/custom_widgets/custom_text/custom_text.dart';
import 'package:reconex/core/themes/app_colors.dart';
import 'package:reconex/core/themes/app_tokens.dart';
import 'package:reconex/features/splash/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradientButton),
        child: SafeArea(
          child: Column(
            children: [const Spacer(), const _AnimatedLogo(), const Spacer(), const _DelayedLoader(), 40.height],
          ),
        ),
      ),
    );
  }
}

/// Logo card that drops in over expanding pulse rings, gets a light sweep,
/// then the wordmark rises in letter by letter.
class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo();

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> with TickerProviderStateMixin {
  static const String _name = 'Reconex';
  static const double _card = 120;

  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..forward();

  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
    ..repeat();

  late final Animation<double> _cardIn = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
  );
  late final Animation<double> _cardFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
  );
  late final Animation<double> _shine = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.35, 0.65, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _card * 2,
          width: _card * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++) _ring(i),
              AnimatedBuilder(
                animation: _intro,
                builder: (context, child) => Opacity(
                  opacity: _cardFade.value,
                  child: Transform.rotate(
                    angle: (1 - _cardIn.value) * -math.pi / 8,
                    child: Transform.scale(scale: 0.3 + 0.7 * _cardIn.value, child: child),
                  ),
                ),
                child: _logoCard(),
              ),
            ],
          ),
        ),
        AppSpacing.md.height,
        _wordmark(),
      ],
    );
  }

  /// Staggered rings that grow and fade out from behind the card.
  Widget _ring(int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _intro]),
      builder: (context, _) {
        final t = (_pulse.value + index / 3) % 1.0;
        final size = _card * (1 + t);
        return Opacity(
          opacity: (1 - t) * 0.35 * _cardFade.value,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg * (1 + t)),
              border: Border.all(color: AppColors.white, width: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _logoCard() {
    return Container(
      height: _card,
      width: _card,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.rLg, boxShadow: AppShadows.lg),
      child: ClipRRect(
        borderRadius: AppRadius.rLg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/reconex_logo.png', fit: BoxFit.cover),
            // Diagonal light band that sweeps across the logo once.
            AnimatedBuilder(
              animation: _shine,
              builder: (context, _) {
                if (_shine.value == 0 || _shine.value == 1) return const SizedBox.shrink();
                final x = -1.5 + 3 * _shine.value;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(x - 0.4, -1),
                      end: Alignment(x + 0.4, 1),
                      colors: [
                        AppColors.white.withValues(alpha: 0),
                        AppColors.amber200.withValues(alpha: 0.7),
                        AppColors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Each letter fades and rises in turn after the card lands.
  Widget _wordmark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _name.length; i++)
          AnimatedBuilder(
            animation: _intro,
            builder: (context, child) {
              final start = 0.45 + i * 0.05;
              final t = Curves.easeOutCubic.transform(((_intro.value - start) / 0.2).clamp(0.0, 1.0));
              return Opacity(
                opacity: t,
                child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
              );
            },
            child: CustomText(
              text: _name[i],
              fontSize: AppTextTokens.displaySize + 4,
              fontWeight: AppTextTokens.displayWeight,
              color: AppColors.white,
              letterSpacing: 1.2,
            ),
          ),
      ],
    );
  }
}

/// Bouncing dots that fade in after the intro, so they do not compete with the logo.
class _DelayedLoader extends StatelessWidget {
  const _DelayedLoader();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1800),
      curve: const Interval(0.75, 1, curve: Curves.easeOut),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: const _BouncingDots(),
    );
  }
}

/// Three dots that rise and brighten one after another in a loop.
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with SingleTickerProviderStateMixin {
  static const int _count = 3;
  static const double _dot = 10;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _count; i++) ...[if (i > 0) AppSpacing.sm.width, _buildDot(i)],
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    // Each dot bounces during its own slice of the cycle, then rests.
    final t = ((_controller.value - index * 0.15) % 1.0) / 0.5;
    final lift = t < 1 ? math.sin(t * math.pi) : 0.0;
    return Transform.translate(
      offset: Offset(0, -12 * lift),
      child: Container(
        height: _dot,
        width: _dot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withValues(alpha: 0.5 + 0.5 * lift),
        ),
      ),
    );
  }
}
