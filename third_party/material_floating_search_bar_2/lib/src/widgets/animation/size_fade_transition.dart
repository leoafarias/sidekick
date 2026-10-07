import 'package:flutter/material.dart';

// ignore_for_file: public_member_api_docs

class SizeFadeTransition extends StatefulWidget {
  const SizeFadeTransition({
    super.key,
    required this.animation,
    this.sizeFraction = 0.5,
    this.curve = Curves.linear,
    this.axis = Axis.vertical,
    this.axisAlignment = 0.0,
    this.child,
  }) : assert(sizeFraction >= 0.0 && sizeFraction <= 1.0);
  final Animation<double> animation;
  final Curve curve;
  final double sizeFraction;
  final Axis axis;
  final double axisAlignment;
  final Widget? child;

  @override
  State<SizeFadeTransition> createState() => _SizeFadeTransitionState();
}

class _SizeFadeTransitionState extends State<SizeFadeTransition> {
  late final CurvedAnimation curve =
      CurvedAnimation(parent: widget.animation, curve: widget.curve);
  late final CurvedAnimation size =
      CurvedAnimation(curve: Interval(0.0, widget.sizeFraction), parent: curve);
  late final CurvedAnimation opacity =
      CurvedAnimation(curve: Interval(widget.sizeFraction, 1.0), parent: curve);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: size,
      axis: widget.axis,
      axisAlignment: widget.axisAlignment,
      child: FadeTransition(
        opacity: opacity,
        child: widget.child,
      ),
    );
  }
}
