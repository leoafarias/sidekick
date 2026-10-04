import 'dart:math' as math;

import 'package:flutter/material.dart';

// ignore_for_file: public_member_api_docs

extension NumExtension on num {
  double get radians => this * (math.pi / 180.0);

  double get degrees => this * (180.0 / math.pi);
}

extension GlobalKeyExtension on GlobalKey {
  RenderBox? get renderBox => currentContext?.renderBox;

  Size? get size => renderBox?.hasSize ?? false ? renderBox?.size : Size.zero;
  double? get height => size?.height;
  double? get width => size?.width;
}

extension BuildContextUiExtension on BuildContext {
  RenderBox? get renderBox => findRenderObject() as RenderBox?;

  Size? get size => renderBox?.hasSize ?? false ? renderBox?.size : Size.zero;
  double? get height => size?.height;
  double? get width => size?.width;
}
