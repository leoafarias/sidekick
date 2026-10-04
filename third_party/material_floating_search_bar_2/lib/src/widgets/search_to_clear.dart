import 'package:flutter/material.dart';

import '../util/util.dart';
import 'widgets.dart';

// ignore_for_file: public_member_api_docs

/// A Widget that animates between a search and
/// a clear icon.
class SearchToClear extends StatelessWidget {
  /// Creates a Widget that animates between a search and
  /// a clear icon.
  const SearchToClear({
    super.key,
    required this.isEmpty,
    required this.onTap,
    this.duration = const Duration(milliseconds: 500),
    this.color,
    this.size = 24.0,
    this.searchButtonSemanticLabel = 'Search',
    this.clearButtonSemanticLabel = 'Clear',
  });

  /// If `true`, the search icon will be shown.
  final bool isEmpty;
  final Duration duration;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  final String searchButtonSemanticLabel;
  final String clearButtonSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedValue(
      value: isEmpty ? 0.0 : 1.0,
      duration: duration,
      builder: (BuildContext context, double value) {
        return CircularButton(
          onPressed: onTap,
          tooltip: value == 0.0
              ? searchButtonSemanticLabel
              : clearButtonSemanticLabel,
          icon: CustomPaint(
            size: Size.square(size),
            painter: _SearchToClearPainter(
              color ?? Theme.of(context).iconTheme.color ?? Colors.black,
              value,
            ),
          ),
        );
      },
    );
  }
}

class _SearchToClearPainter extends CustomPainter {
  _SearchToClearPainter(
    this.color,
    this.progress,
  );
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double t = progress;

    final double circleProgress = interval(0.0, 0.4, t, curve: Curves.easeIn);
    final double lineProgress = interval(0.3, 0.8, t, curve: Curves.ease);
    final double sLineProgress = interval(0.5, 1.0, t, curve: Curves.easeOut);

    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    const double padding = 0.225;
    canvas.translate(w * (padding / 2), h * (padding / 2));
    canvas.scale(1 - padding, 1 - padding);

    final double sw = w * 0.125;
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke;

    final double radius = w * 0.26;
    final double offset = radius + (sw / 2);

    // Draws the handle of the loop.
    final Offset lineStart = Offset(radius * 2, radius * 2);
    final Offset lineEnd = Offset(sw, sw);
    canvas.drawLine(
      Offset.lerp(lineStart, lineEnd, lineProgress)!,
      Offset(w - sw, h - sw),
      paint,
    );

    // Draws the circle of the loop.
    final Offset circleStart = Offset(offset, offset);
    final Offset circleEnd = Offset(-offset, -offset);
    final Path circle = Path()
      ..addArc(
        Rect.fromCircle(
          center: Offset.lerp(circleStart, circleEnd, lineProgress)!,
          radius: radius,
        ),
        32.0.radians,
        (360 * (1 - circleProgress)).radians,
      );
    canvas.drawPath(circle, paint);

    // Draws the second line that will make the cross.
    final Offset sLineStart = Offset(sw, h - sw);
    final Offset sLineEnd = Offset(w - sw, sw);
    canvas.drawLine(
      sLineStart,
      Offset.lerp(sLineStart, sLineEnd, sLineProgress)!,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
