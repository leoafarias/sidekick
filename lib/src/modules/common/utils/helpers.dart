import 'dart:io';

import 'package:flutter/material.dart';
import 'package:i18next/i18next.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../constants.dart';

/// String extensions
extension StringExtension on String {
  ///Capitalizes a string
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

final numberFormatter = NumberFormat('###,###,000');

/// Iterable extension
extension ExtendedIterable<E> on Iterable<E> {
  /// Like Iterable<T>.map but callback have index as second argument
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }

  /// For each with index
  void forEachIndexed(void Function(E e, int i) f) {
    var i = 0;
    forEach((e) => f(e, i++));
  }
}

extension BuildContextExtension on BuildContext {
  String i18n(String key, {Map<String, dynamic>? variables}) {
    return i18next.t(key, variables: variables);
  }

  I18Next get i18next {
    final i18next = I18Next.of(this);
    if (i18next == null) {
      throw Exception('I18Next is null');
    }
    return i18next;
  }

  Locale get locale {
    return i18next.locale;
  }
}

/// Returns a temp `Directory` for sidekick
/// If [subDirectory] is provided it will add to the path
Future<Directory> getSidekickTempDir({
  Directory? subDirectory,
}) async {
  final rootTempDir = await getTemporaryDirectory();
  final appTempDir = Directory(path.join(rootTempDir.path, kAppBundleId));

  // Final temp directory
  var tempDir = appTempDir;

  // If subdirectory add it to app temp directory
  if (subDirectory != null) {
    final subPath = path.join(appTempDir.path, subDirectory.path);
    tempDir = Directory(subPath);
  }

  // Check if it exists if not create it
  if (!await tempDir.exists()) {
    await tempDir.create(recursive: true);
  }

  return tempDir;
}

/// Checks if string contains
bool containsIgnoringWhitespace(String source, String toSearch) {
  return collapseWhitespace(source).contains(collapseWhitespace(toSearch));
}

/// Utility function to collapse whitespace runs to single spaces
/// and strip leading/trailing whitespace.
/// taken from matcher
String collapseWhitespace(String string) {
  var result = StringBuffer();
  var skipSpace = true;
  for (var i = 0; i < string.length; i++) {
    var character = string[i];
    if (_isWhitespace(character)) {
      if (!skipSpace) {
        result.write(' ');
        skipSpace = true;
      }
    } else {
      result.write(character);
      skipSpace = false;
    }
  }
  return result.toString().trim();
}

bool _isWhitespace(String ch) => ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';
