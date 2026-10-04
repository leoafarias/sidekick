import 'package:flutter/material.dart'
    hide ImplicitlyAnimatedWidget, ImplicitlyAnimatedWidgetState;

import 'implicitly_animated_widget.dart';

// ignore_for_file: public_member_api_docs

class ImplicitAnimationBuilder<T> extends ImplicitlyAnimatedWidget {
  const ImplicitAnimationBuilder({
    Key? key,
    required Duration duration,
    Curve curve = Curves.linear,
    required this.lerp,
    required this.value,
    required this.builder,
    this.child,
  }) : super(key, duration, curve);
  final T Function(T a, T b, double t) lerp;
  final T value;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  @override
  State<ImplicitAnimationBuilder<T>> createState() =>
      _ImplicitAnimationBuilderState<T>();
}

class _ImplicitAnimationBuilderState<T>
    extends ImplicitlyAnimatedWidgetState<T, ImplicitAnimationBuilder<T>> {
  @override
  T get newValue => widget.value;

  @override
  T lerp(T a, T b, double t) => widget.lerp(a, b, t);

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, value, widget.child);
}
