import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData get darkPurpleTheme {
  return _customThemeBuilder(
    cardColor: const Color(0xFF180D2F),
    scaffoldBackgroundColor: const Color(0xFF0F0823),
    primarySwatch: Colors.deepOrange,
    accentColor: Colors.deepOrangeAccent,
  );
}

ThemeData get darkBlueTheme {
  return _customThemeBuilder(
    cardColor: const Color(0xFF092045),
    scaffoldBackgroundColor: const Color(0xFF081231),
    primarySwatch: Colors.cyan,
    accentColor: Colors.cyan,
  );
}

ThemeData get darkTheme {
  return _customThemeBuilder(
    cardColor: const Color(0xFF2B2D2F),
    scaffoldBackgroundColor: const Color(0xFF1D1E1F),
    primarySwatch: Colors.cyan,
    accentColor: Colors.cyan,
  );
}

ThemeData _customThemeBuilder({
  Color? cardColor,
  Color? scaffoldBackgroundColor,
  MaterialColor? primarySwatch,
  Color? accentColor,
  Brightness brightness = Brightness.dark,
}) {
  ThemeData baseTheme;
  if (brightness == Brightness.dark) {
    baseTheme = ThemeData.dark();
  } else {
    baseTheme = ThemeData.light();
  }
  return ThemeData(
    textTheme: GoogleFonts.ibmPlexSansTextTheme(baseTheme.textTheme),
    brightness: brightness,
    primarySwatch: primarySwatch,
    cardColor: cardColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    colorScheme: baseTheme.colorScheme.copyWith(
      secondary: accentColor,
    ),
    dividerColor: Colors.white10,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey,
        backgroundColor: Colors.grey[850],
        side: BorderSide(
          color: Colors.grey[800] ?? Colors.grey,
        ),
      ),
    ),
    textButtonTheme: _textButtonThemeData,
    popupMenuTheme: PopupMenuThemeData(
      shape: _roundedShape,
    ),
    dialogTheme: DialogThemeData(
      shape: _roundedShape,
      backgroundColor: scaffoldBackgroundColor,
      titleTextStyle: ThemeData.dark().textTheme.displayLarge,
      contentTextStyle: ThemeData.dark().textTheme.bodyLarge,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.black54,
    ),
    chipTheme: ThemeData.dark().chipTheme.copyWith(
          backgroundColor: Colors.black12,
        ),
  ).copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

ThemeData get lightTheme {
  return ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    colorScheme: ThemeData.light().colorScheme.copyWith(
          secondary: Colors.blue,
        ),
    dividerColor: Colors.black12,
    scaffoldBackgroundColor: const Color(0xfffafafa),
    textButtonTheme: _textButtonThemeData,
    cardTheme: const CardThemeData(
      elevation: 3,
      shadowColor: Colors.black45,
    ),
    dialogTheme: DialogThemeData(
      shape: _roundedShape,
      titleTextStyle: ThemeData.light().textTheme.displaySmall,
      contentTextStyle: ThemeData.light().textTheme.bodyLarge,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFFF6F4F6),
      iconTheme: IconThemeData(),
    ),
  ).copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

TextButtonThemeData get _textButtonThemeData {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(horizontal: 20),
    ),
  );
}

RoundedRectangleBorder get _roundedShape {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10.0),
  );
}

bool isNumeric(String? s) {
  if (s == null) {
    return false;
  }
  return double.tryParse(s) != null;
}

double getWindowsBuild() {
  final osVer =
      Platform.operatingSystemVersion.replaceAll(RegExp(r'[^\w\s\.]+'), '');

  final splitOsVer = osVer.split(' ');

  final nums = splitOsVer.where((element) => isNumeric(element)).toList();
  return double.parse(nums.last);
}

Color platformBackgroundColor(BuildContext context) {
  final themeBrightness = Theme.of(context).brightness;
  final platformBrightness = MediaQuery.of(context).platformBrightness;
  final brightnessMatches = themeBrightness == platformBrightness;

  // Brightness matches doesn't work on Windows 10

  if (Platform.isWindows) {
    if (getWindowsBuild() >= 22000) {
      Window.setEffect(
          effect: WindowEffect.mica,
          color: Theme.of(context).cardColor.withAlpha(0),
          dark: Theme.of(context).brightness == Brightness.dark);
      return Colors.transparent;
    } else if (getWindowsBuild() >= 10240) {
      // Acrylic causes issues on W10
      Window.setEffect(
        effect: WindowEffect.aero,
        color: Theme.of(context).cardColor.withAlpha(200),
      );
      return Colors.transparent;
    }
    return Theme.of(context).cardColor;
  }

  if (brightnessMatches && Platform.isMacOS) {
    Window.setEffect(
      effect: WindowEffect.sidebar,
      color: Colors.transparent,
    );
    return Colors.transparent;
  } else {
    return Theme.of(context).cardColor;
  }
}
