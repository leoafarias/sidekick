import 'package:flutter/material.dart';

/// An easier to use [IconButton] for [FloatingSearchBar]
/// actions.
class CircularButton extends StatelessWidget {
  /// Creates an easier to use [IconButton] for
  /// [FloatingSearchBar] actions.
  const CircularButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24.0,
    this.padding = const EdgeInsets.all(8),
    this.tooltip,
  });
  // ignore: public_member_api_docs
  final Widget icon;

  // ignore: public_member_api_docs
  final VoidCallback onPressed;

  /// The size of this icon.
  ///
  /// When not specified, defaults to `24.0`.
  final double size;

  /// The padding of this icon.
  ///
  /// When not specified, defaults to
  /// `EdgeInsets.all(8)`.
  final EdgeInsets padding;

  // ignore: public_member_api_docs
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: padding,
          child: icon,
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip ?? '',
        child: button,
      );
    }

    return button;
  }
}
