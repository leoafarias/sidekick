import 'package:flutter/material.dart';

/// A Widget that notifies a parent [FloatingSearchBar] about
/// scroll events of its child [Scrollable].
///
/// This is useful, if you want to implement the common pattern
/// with floating search bars, in which the search bar is hidden
/// when the user scrolls down and shown again when the user scrolls
/// up.
class FloatingSearchBarScrollNotifier extends StatelessWidget {
  /// Creates a [FloatingSearchBarScrollNotifier].
  ///
  /// This widget is useful, if you want to implement the common pattern
  /// with floating search bars, in which the search bar is hidden
  /// when the user scrolls down and shown again when the user scrolls
  /// up.
  const FloatingSearchBarScrollNotifier({
    super.key,
    required this.child,
  });

  /// The vertically scrollable child.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        ScrollMetrics metrics = notification.metrics;
        // Dispatch the notifcation only for vertical
        // scrollables.
        if (metrics.axis == Axis.vertical) {
          // If the scroll notification is due to an "over-scroll" (stretch, or animating the release of a stretch)
          // then force the scroll-metric to it's zero position (position the search bar at it's pinned position).
          // This is to prevent the search bar from animating away, then back again when the stretch animation
          // finishes.
          if (metrics.pixels < 0 || metrics.pixels > metrics.maxScrollExtent) {
            metrics = FixedScrollMetrics(
              pixels: metrics.pixels < 0 ? 0 : metrics.maxScrollExtent,
              axisDirection: metrics.axisDirection,
              maxScrollExtent: metrics.maxScrollExtent,
              minScrollExtent: metrics.minScrollExtent,
              viewportDimension: metrics.viewportDimension,
              devicePixelRatio: metrics.devicePixelRatio,
            );
          }

          FloatingSearchBarScrollNotification(
            metrics,
            context,
          ).dispatch(context);
        }

        return false;
      },
      child: child,
    );
  }
}

/// The [ScrollNotifcation] used by [FloatingSearchBarScrollNotifier].
class FloatingSearchBarScrollNotification extends ScrollNotification {
  /// Creates a [ScrollNotifcation] used by [FloatingSearchBarScrollNotifier].
  FloatingSearchBarScrollNotification(
    ScrollMetrics metrics,
    BuildContext context,
  ) : super(
          metrics: metrics,
          context: context,
        );
}
