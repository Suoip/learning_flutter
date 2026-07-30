import 'package:flutter/material.dart';

/// Plays a quick spring-like scale bounce on [child] whenever [active] flips
/// from false to true - a physical-feeling reinforcement for toggles like
/// favorite/pin/like, layered on top of the haptic tap already fired by the
/// button itself. Deliberately doesn't bounce on the reverse transition
/// (un-favoriting etc.), matching the common "burst only on becoming active"
/// convention (e.g. a like button's heart burst).
class PopOnChange extends StatefulWidget {
  const PopOnChange({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      weight: 40,
      tween: Tween(
        begin: 1.0,
        end: 1.35,
      ).chain(CurveTween(curve: Curves.easeOut)),
    ),
    TweenSequenceItem(
      weight: 60,
      tween: Tween(
        begin: 1.35,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant PopOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}
