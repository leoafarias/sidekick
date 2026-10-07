import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

export 'extensions.dart';
export 'handler.dart';

// ignore_for_file: public_member_api_docs

double interval(double begin, double end, double t,
    {Curve curve = Curves.linear}) {
  if (t < begin) {
    return 0.0;
  }
  if (t > end) {
    return 1.0;
  }

  final double v = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(v);
}

void postFrame(VoidCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback((_) => callback());
}

bool get isAvailableSwipeBack {
  bool macLand = false;
  if (!kIsWeb) {
    macLand = Platform.isIOS | Platform.isMacOS;
  }
  return macLand;
}
