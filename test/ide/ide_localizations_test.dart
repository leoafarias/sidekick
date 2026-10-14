import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// i18next has no fallback language here, so every key used by the IDE
/// launcher UI must exist in every locale.
void main() {
  const keys = [
    'settings.scenes.ideSelection',
    'settings.scenes.whatIdeDoYouWantToOpenYourProjectsWith',
    'settings.scenes.ideNone',
    'settings.scenes.ideCustom',
    'settings.scenes.ideNotFound',
    'settings.scenes.ideNotFoundDescription',
    'settings.scenes.detectIdesAgain',
    'settings.scenes.detectingIdes',
    'projects.components.openIde',
    'projects.components.openIn',
    'projects.components.couldNotOpenIde',
    'projects.components.noIdesFound',
  ];

  final locales =
      Directory('localizations').listSync().whereType<Directory>().toList();

  test('all 22 locales are checked', () {
    expect(locales, hasLength(22));
  });

  for (final locale in locales) {
    test('${locale.path} has the IDE launcher keys', () {
      final modules = json.decode(
        File('${locale.path}/modules.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final key in keys) {
        dynamic value = modules;
        for (final part in key.split('.')) {
          value = (value as Map<String, dynamic>)[part];
        }
        expect(value, isA<String>(), reason: key);
        expect((value as String).trim(), isNotEmpty, reason: key);
        if (key.endsWith('ideNotFound') ||
            key.endsWith('ideNotFoundDescription') ||
            key.endsWith('couldNotOpenIde')) {
          expect(value, contains('{{ideName}}'), reason: key);
        }
      }
    });
  }
}
