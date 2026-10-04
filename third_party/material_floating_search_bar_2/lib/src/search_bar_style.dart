// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:ui';

import 'package:flutter/material.dart';

class FloatingSearchBarStyle {
  const FloatingSearchBarStyle({
    required this.backgroundColor,
    required this.shadowColor,
    required this.padding,
    required this.insets,
    required this.height,
    required this.elevation,
    required this.backdropColor,
    required this.border,
    required this.borderRadius,
    required this.margins,
    required this.maxWidth,
    required this.openMaxWidth,
    required this.axisAlignment,
    required this.openAxisAlignment,
  });
  final Color backgroundColor;
  final Color shadowColor;
  final Color backdropColor;
  final EdgeInsets padding;
  final EdgeInsets insets;
  final EdgeInsets margins;
  final double height;
  final double elevation;
  final BorderSide border;
  final BorderRadius borderRadius;
  final double? maxWidth;
  final double? openMaxWidth;
  final double axisAlignment;
  final double openAxisAlignment;

  FloatingSearchBarStyle scaleTo(FloatingSearchBarStyle b, double t) {
    return FloatingSearchBarStyle(
      height: lerpDouble(height, b.height, t)!,
      elevation: lerpDouble(elevation, b.elevation, t)!,
      maxWidth: b.maxWidth == null ? null : lerpDouble(maxWidth, b.maxWidth, t),
      openMaxWidth: b.openMaxWidth == null
          ? null
          : lerpDouble(openMaxWidth, b.openMaxWidth, t),
      axisAlignment: lerpDouble(axisAlignment, b.axisAlignment, t)!,
      openAxisAlignment: lerpDouble(openAxisAlignment, b.openAxisAlignment, t)!,
      backgroundColor: Color.lerp(backgroundColor, b.backgroundColor, t)!,
      backdropColor: Color.lerp(backdropColor, b.backdropColor, t)!,
      shadowColor: Color.lerp(shadowColor, b.shadowColor, t)!,
      insets: EdgeInsets.lerp(insets, b.insets, t)!,
      margins: EdgeInsets.lerp(margins, b.margins, t)!,
      padding: EdgeInsets.lerp(padding, b.padding, t)!,
      border: BorderSide.lerp(border, b.border, t),
      borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
    );
  }

  @override
  String toString() {
    return 'FloatingSearchBarStyle(backgroundColor: $backgroundColor, shadowColor: $shadowColor, padding: $padding, insets: $insets, height: $height, elevation: $elevation, backdropColor: $backdropColor, border: $border, borderRadius: $borderRadius, margins: $margins, maxWidth: $maxWidth, openMaxWidth: $openMaxWidth, axisAlignment: $axisAlignment, openAxisAlignment: $openAxisAlignment)';
  }
}

class FloatingSearchAppBarStyle {
  const FloatingSearchAppBarStyle({
    required this.accentColor,
    required this.backgroundColor,
    required this.shadowColor,
    required this.iconColor,
    required this.colorOnScroll,
    required this.padding,
    required this.insets,
    required this.height,
    required this.elevation,
    required this.liftOnScrollElevation,
    required this.hintStyle,
    required this.queryStyle,
  });
  final Color accentColor;
  final Color backgroundColor;
  final Color shadowColor;
  final Color iconColor;
  final Color? colorOnScroll;
  final EdgeInsets padding;
  final EdgeInsets insets;
  final double height;
  final double elevation;
  final double liftOnScrollElevation;
  final TextStyle? hintStyle;
  final TextStyle? queryStyle;

  FloatingSearchAppBarStyle scaleTo(FloatingSearchAppBarStyle b, double t) {
    return FloatingSearchAppBarStyle(
      height: lerpDouble(height, b.height, t)!,
      elevation: lerpDouble(elevation, b.elevation, t)!,
      liftOnScrollElevation:
          lerpDouble(liftOnScrollElevation, b.liftOnScrollElevation, t)!,
      accentColor: Color.lerp(accentColor, b.accentColor, t)!,
      backgroundColor: Color.lerp(backgroundColor, b.backgroundColor, t)!,
      colorOnScroll: Color.lerp(colorOnScroll, b.colorOnScroll, t),
      shadowColor: Color.lerp(shadowColor, b.shadowColor, t)!,
      iconColor: Color.lerp(iconColor, b.iconColor, t)!,
      insets: EdgeInsets.lerp(insets, b.insets, t)!,
      padding: EdgeInsets.lerp(padding, b.padding, t)!,
      hintStyle: TextStyle.lerp(hintStyle, b.hintStyle, t),
      queryStyle: TextStyle.lerp(queryStyle, b.queryStyle, t),
    );
  }

  @override
  String toString() {
    return 'FloatingSearchAppBarStyle(accentColor: $accentColor, backgroundColor: $backgroundColor, shadowColor: $shadowColor, iconColor: $iconColor, colorOnScroll: $colorOnScroll, padding: $padding, insets: $insets, height: $height, elevation: $elevation, liftOnScrollElevation: $liftOnScrollElevation, hintStyle: $hintStyle, queryStyle: $queryStyle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is FloatingSearchAppBarStyle &&
        other.accentColor == accentColor &&
        other.backgroundColor == backgroundColor &&
        other.shadowColor == shadowColor &&
        other.iconColor == iconColor &&
        other.colorOnScroll == colorOnScroll &&
        other.padding == padding &&
        other.insets == insets &&
        other.height == height &&
        other.elevation == elevation &&
        other.liftOnScrollElevation == liftOnScrollElevation &&
        other.hintStyle == hintStyle &&
        other.queryStyle == queryStyle;
  }

  @override
  int get hashCode {
    return accentColor.hashCode ^
        backgroundColor.hashCode ^
        shadowColor.hashCode ^
        iconColor.hashCode ^
        colorOnScroll.hashCode ^
        padding.hashCode ^
        insets.hashCode ^
        height.hashCode ^
        elevation.hashCode ^
        liftOnScrollElevation.hashCode ^
        hintStyle.hashCode ^
        queryStyle.hashCode;
  }
}
