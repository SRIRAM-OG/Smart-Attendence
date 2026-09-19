import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Animation Duration Constants
// ─────────────────────────────────────────────

class Durations {
  static const Duration fastest = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration slower = Duration(milliseconds: 800);
  static const Duration slowest = Duration(milliseconds: 1200);
}

// ─────────────────────────────────────────────
// Custom Curves
// ─────────────────────────────────────────────

class AppCurves {
  static const Curve spring = Curves.elasticOut;
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve entrance = Curves.easeOutQuart;
  static const Curve exit = Curves.easeInCubic;
  static const Curve bounce = Curves.bounceOut;
  static const Curve decelerate = Curves.decelerate;
}

// ─────────────────────────────────────────────
// 3D Tilt Card Widget
// ─────────────────────────────────────────────

/// A wrapper that applies a 3D perspective tilt effect on pointer interaction.
/// The card tilts towards the touch point with a subtle rotation.
class Tilt3DCard extends StatefulWidget {
  final Widget child;
  final double maxTilt; // max tilt angle in radians
  final double perspective;
  final Duration duration;

  const Tilt3DCard({
    super.key,
    required this.child,
    this.maxTilt = 0.06,
    this.perspective = 0.002,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<Tilt3DCard> {
  double _rotateX = 0;
  double _rotateY = 0;
  bool _isHovering = false;

  void _onPointerMove(PointerEvent event, BoxConstraints constraints) {
    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
    final dx = (event.localPosition.dx - center.dx) / center.dx;
    final dy = (event.localPosition.dy - center.dy) / center.dy;

    setState(() {
      _rotateY = dx * widget.maxTilt;
      _rotateX = -dy * widget.maxTilt;
      _isHovering = true;
    });
  }

  void _onPointerExit() {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
      _isHovering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          _onPointerMove(
            event,
            BoxConstraints(maxWidth: box.size.width, maxHeight: box.size.height),
          );
        }
      },
      onPointerUp: (_) => _onPointerExit(),
      onPointerCancel: (_) => _onPointerExit(),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, widget.perspective)
          ..rotateX(_rotateX)
          ..rotateY(_rotateY),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Press Scale Effect Widget
// ─────────────────────────────────────────────

/// Wraps a child and adds a press-down scale effect with spring bounce.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
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

// ─────────────────────────────────────────────
// Animated Counter Widget
// ─────────────────────────────────────────────

/// Animates a number from 0 to [value] with a count-up effect.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final Duration duration;
  final TextStyle? style;
  final String suffix;
  final int decimalPlaces;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    this.suffix = '',
    this.decimalPlaces = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        final text = decimalPlaces > 0
            ? val.toStringAsFixed(decimalPlaces)
            : val.toInt().toString();
        return Text('$text$suffix', style: style);
      },
    );
  }
}

// ─────────────────────────────────────────────
// Glassmorphic Container
// ─────────────────────────────────────────────

/// A frosted glass effect container with backdrop blur.
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsets? padding;
  final Color? color;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.15,
    this.borderRadius = 20,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pulsing Glow Widget
// ─────────────────────────────────────────────

/// Adds a repeating glow pulse effect behind a widget.
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxBlur;
  final Duration duration;

  const PulsingGlow({
    super.key,
    required this.child,
    this.glowColor = Colors.blue,
    this.maxBlur = 20,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.15 + _controller.value * 0.2),
                blurRadius: widget.maxBlur * (0.5 + _controller.value * 0.5),
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────
// Shimmer Loading Placeholder
// ─────────────────────────────────────────────

/// A shimmer loading placeholder card.
class ShimmerCard extends StatelessWidget {
  final double height;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Builds a column of shimmer placeholder cards.
Widget buildShimmerList({int count = 4, double cardHeight = 80}) {
  return Column(
    children: List.generate(count, (_) => ShimmerCard(height: cardHeight)),
  );
}

// ─────────────────────────────────────────────
// Animated Scan Frame (for QR Scanner)
// ─────────────────────────────────────────────

/// An animated scanning frame with pulsing corners and a sweeping scan line.
class AnimatedScanFrame extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedScanFrame({
    super.key,
    this.size = 260,
    this.color = Colors.blue,
  });

  @override
  State<AnimatedScanFrame> createState() => _AnimatedScanFrameState();
}

class _AnimatedScanFrameState extends State<AnimatedScanFrame>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _scanController]),
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ScanFramePainter(
              color: widget.color,
              pulseValue: _pulseController.value,
              scanPosition: _scanController.value,
            ),
          ),
        );
      },
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  final Color color;
  final double pulseValue;
  final double scanPosition;

  _ScanFramePainter({
    required this.color,
    required this.pulseValue,
    required this.scanPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cornerLength = size.width * 0.15;
    final strokeWidth = 3.0 + pulseValue * 1.0;
    final paint = Paint()
      ..color = color.withOpacity(0.7 + pulseValue * 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = 12.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerLength)
        ..lineTo(size.width, size.height - r)
        ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
        ..lineTo(size.width - cornerLength, size.height),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cornerLength, size.height)
        ..lineTo(r, size.height)
        ..quadraticBezierTo(0, size.height, 0, size.height - r)
        ..lineTo(0, size.height - cornerLength),
      paint,
    );

    // Scan line
    final scanY = size.height * scanPosition;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0),
          color.withOpacity(0.6),
          color.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 1, size.width, 2));
    canvas.drawLine(
      Offset(8, scanY),
      Offset(size.width - 8, scanY),
      scanPaint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter old) => true;
}

// ─────────────────────────────────────────────
// Stagger Helper
// ─────────────────────────────────────────────

/// Returns a delay duration for staggered list items based on index.
Duration staggerDelay(int index, {int baseMs = 60}) {
  return Duration(milliseconds: index * baseMs);
}

// ─────────────────────────────────────────────
// Page Transition Builders
// ─────────────────────────────────────────────

/// Fade + Scale page transition.
Widget fadeScaleTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
  );
}

/// Slide from right page transition with slight fade.
Widget slideRightTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    ),
    child: FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

/// Slide up + fade transition.
Widget slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    ),
    child: FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

/// Fade through (cross-fade) page transition.
Widget fadeThroughTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  );
}
