import 'package:flutter/material.dart';

import 'implicit_animation_builder.dart';

// ignore_for_file: public_member_api_docs

class AnimatedTranslation extends StatelessWidget {
  const AnimatedTranslation({
    super.key,
    required this.translation,
    required this.duration,
    required this.child,
    this.curve = Curves.linear,
    this.isFractional = false,
  });
  final Offset translation;
  final Duration duration;
  final Widget child;
  final Curve curve;
  final bool isFractional;

  @override
  Widget build(BuildContext context) {
    return ImplicitAnimationBuilder<Offset>(
      lerp: (Offset a, Offset b, double t) => Offset.lerp(a, b, t)!,
      value: translation,
      curve: curve,
      duration: duration,
      builder: (BuildContext context, Offset value, _) {
        if (isFractional) {
          return FractionalTranslation(
            translation: value,
            child: child,
          );
        } else {
          return Transform.translate(
            offset: value,
            child: child,
          );
        }
      },
    );
  }
}
