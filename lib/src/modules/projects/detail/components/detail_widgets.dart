import 'package:flutter/material.dart';

import '../../../../components/atoms/typography.dart';

/// Centered icon and message, for empty and error states
class DetailMessage extends StatelessWidget {
  /// Constructor
  const DetailMessage({
    required this.icon,
    required this.message,
    this.action,
    super.key,
  });

  /// Icon
  final IconData icon;

  /// Message
  final String message;

  /// Optional button
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).disabledColor),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: 15),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Highlighted notice with an optional action
class NoticeBanner extends StatelessWidget {
  /// Constructor
  const NoticeBanner({
    required this.message,
    this.icon = Icons.info_outline,
    this.color = Colors.deepOrange,
    this.action,
    super.key,
  });

  /// Message
  final String message;

  /// Icon
  final IconData icon;

  /// Accent color
  final Color color;

  /// Optional button
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      padding: const EdgeInsets.fromLTRB(15, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Caption(message)),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Label and value row
class InfoRow extends StatelessWidget {
  /// Constructor
  const InfoRow({
    required this.label,
    required this.child,
    super.key,
  });

  /// Label
  final String label;

  /// Value
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Caption(label)),
          Expanded(child: child),
        ],
      ),
    );
  }
}
