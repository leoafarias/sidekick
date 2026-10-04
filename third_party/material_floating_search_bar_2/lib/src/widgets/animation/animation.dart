import 'package:flutter/animation.dart';

export 'animated_translation.dart';
export 'animated_value.dart';
export 'circular_reveal_transition.dart';
export 'implicit_animation_builder.dart';
export 'implicitly_animated_widget.dart';
export 'size_fade_transition.dart';

/// A [TweenSequence] that goes from 0 to 1 and back to 0.
class PeakingTween extends TweenSequence<double> {
  /// Creates a [TweenSequence] that goes from 0 to 1 and back to 0.
  PeakingTween()
      : super(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0), weight: 0.5),
          TweenSequenceItem<double>(
              tween: Tween<double>(begin: 1.0, end: 0.0), weight: 0.5),
        ]);
}

/// A [TweenSequence] that goes from 1 to 0 and back to 1.
class ValleyingTween extends TweenSequence<double> {
  /// Creates a [TweenSequence] that goes from 1 to 0 and back to 1.
  ValleyingTween()
      : super(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
              tween: Tween<double>(begin: 1.0, end: 0.0), weight: 0.5),
          TweenSequenceItem<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0), weight: 0.5),
        ]);
}
