import 'dart:math';

import 'package:flutter/material.dart';

import 'floating_search_bar.dart';
import 'util/util.dart';

// ignore_for_file: public_member_api_docs

/// A utility widget that wraps its child in a [SingleChildScrollView]
/// and dismisses the [FloatingSearchBar] when it was tapped below the
/// child.
///
/// This widget is necessary as a [Scrollable] expands to fill its
/// available space and also intercepts all touch events, thus we need
/// to wrap the [Scrollable] inside a [GestureDetector], intercept the tap
/// events before they get to the [Scrollable] and then decide based on the
/// height of the child, whether a tap was below the content.
class FloatingSearchBarDismissable extends StatefulWidget {
  const FloatingSearchBarDismissable({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.physics,
  });
  final Widget child;

  /// The amount of space by which to inset the child.
  final EdgeInsetsGeometry? padding;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Must be null if [primary] is true.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController? controller;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  @override
  State<FloatingSearchBarDismissable> createState() =>
      _FloatingSearchBarDismissableState<dynamic>();
}

class _FloatingSearchBarDismissableState<E>
    extends State<FloatingSearchBarDismissable> {
  final GlobalKey<State<StatefulWidget>> childKey = GlobalKey();

  double childHeight = 0.0;
  double tapDy = 0.0;

  double scrollOffset = 0.0;

  void _measure() {
    postFrame(
      () => childHeight = childKey.height ?? 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    _measure();

    final EdgeInsets padding =
        widget.padding?.resolve(Directionality.of(context)) ?? EdgeInsets.zero;

    return GestureDetector(
      onTapDown: (TapDownDetails details) => tapDy = details.localPosition.dy,
      onPanDown: (DragDownDetails details) => tapDy = details.localPosition.dy,
      onPanUpdate: (DragUpdateDetails details) =>
          tapDy = details.localPosition.dy,
      onTap: () {
        final double offset = max(scrollOffset - padding.top, 0.0);

        void close() => FloatingSearchBar.of(context)!.close();

        if (tapDy < padding.top) {
          close();
        } else if (tapDy > (childHeight - offset)) {
          close();
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          final ScrollMetrics metrics = notification.metrics;

          if (metrics.axis == Axis.vertical) {
            scrollOffset = metrics.pixels;
          }

          return false;
        },
        child: SingleChildScrollView(
          controller: widget.controller,
          physics: widget.physics,
          padding: padding.add(
            EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
          ),
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (_) {
              _measure();
              return true;
            },
            child: SizeChangedLayoutNotifier(
              key: childKey,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
