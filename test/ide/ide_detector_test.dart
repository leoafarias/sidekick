import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/src/modules/ide/ide.provider.dart';
import 'package:sidekick/src/modules/ide/ide_detector.dart';
import 'package:sidekick/src/modules/ide/ide_environment.dart';
import 'package:sidekick/src/modules/ide/ide_launch_plan.dart';
import 'package:sidekick/src/modules/ide/ide_launcher.dart';

import 'fake_ide_environment.dart';

const _home = '/Users/me';

/// PATH of an app started from Finder or the Dock
const _guiPath = '/usr/bin:/bin:/usr/sbin:/sbin';

FakeIdeEnvironment _mac({
  Iterable<String> files = const [],
  Iterable<String> directories = const [],
  Map<String, IdeProcessResult>? processes,
}) {
  return FakeIdeEnvironment(
    platform: HostPlatform.macos,
    variables: {'HOME': _home, 'PATH': _guiPath},
    files: files,
    directories: directories,
    processes: processes,
  );
}

IdeLauncher _launcher(String id) => ideLauncherById(id)!;

Future<List<String>> _detectedIds(IdeEnvironment env) async {
  final detected = await IdeDetector(env).detectAll();
  return detected.map((ide) => ide.id).toList();
}

Future<IdeLaunchCommand> _command(
  IdeEnvironment env,
  String id,
  String folder,
) async {
  final ide = await IdeDetector(env).detect(_launcher(id));
  expect(ide, isNotNull, reason: '$id should be detected');
  return (await buildLaunchPlan(ide!, folder, env)).command;
}

void main() {
  group('catalog', () {
    test('ids are unique', () {
      final ids = ideLaunchers.map((launcher) => launcher.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('includes the required launchers', () {
      for (final id in [
        'VSCode',
        'XCode',
        'Custom',
        'Cursor',
        'AndroidStudio',
        'Claude',
        'Codex',
        'T3Code',
        'Paseo',
      ]) {
        expect(ideLauncherById(id), isNotNull, reason: id);
      }
    });

    test('url launchers have a template with a path placeholder', () {
      for (final launcher in ideLaunchers) {
        if (launcher.kind != IdeOpenKind.url) continue;
        expect(launcher.urlTemplate, contains('{path}'), reason: launcher.id);
      }
    });
  });

  group('stored settings values', () {
    test('values saved by older versions keep working', () {
      // The old `SupportedIDE` enum names
      expect(migrateIdeId('VSCode'), 'VSCode');
      expect(migrateIdeId('XCode'), 'XCode');
      expect(migrateIdeId('Custom'), 'Custom');
      expect(ideLauncherById('XCode')!.name, 'Xcode');
    });

    test('ids match case-insensitively and legacy aliases resolve', () {
      expect(migrateIdeId('Xcode'), 'XCode');
      expect(migrateIdeId('vscode'), 'VSCode');
    });

    test('none and empty values mean no IDE', () {
      expect(migrateIdeId(null), isNull);
      expect(migrateIdeId(''), isNull);
      expect(migrateIdeId('none'), isNull);
    });

    test('unknown values are kept', () {
      expect(migrateIdeId('SomeFutureIde'), 'SomeFutureIde');
      expect(ideLauncherById('SomeFutureIde'), isNull);
    });
  });

  group('macOS detection', () {
    test('finds nothing on an empty machine', () async {
      expect(await _detectedIds(_mac()), isEmpty);
    });

    test('finds app bundles in /Applications and ~/Applications', () async {
      final env = _mac(directories: [
        '/Applications/Cursor.app',
        '$_home/Applications/Android Studio.app',
        '/Applications/Xcode.app',
      ]);
      expect(
        await _detectedIds(env),
        ['Cursor', 'AndroidStudio', 'XCode'],
      );
    });

    test('prefers the CLI inside the bundle', () async {
      final env = _mac(
        directories: ['/Applications/Visual Studio Code.app'],
        files: [
          '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code',
        ],
      );
      final command = await _command(env, 'VSCode', '/work/my app');
      expect(command.executable,
          '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code');
      expect(command.arguments, ['/work/my app']);
      expect(command.runInShell, isFalse);
    });

    test('falls back to open -a when the bundle has no CLI', () async {
      final env = _mac(directories: ['/Applications/Zed.app']);
      final command = await _command(env, 'Zed', '/work/app');
      expect(command.executable, 'open');
      expect(command.arguments, ['-a', '/Applications/Zed.app', '/work/app']);
    });

    test('JetBrains apps get the folder as an argument', () async {
      final env = _mac(directories: ['/Applications/IntelliJ IDEA.app']);
      final command = await _command(env, 'IntelliJ', '/work/app');
      expect(command.arguments,
          ['-na', '/Applications/IntelliJ IDEA.app', '--args', '/work/app']);
    });

    test('finds CLIs outside the minimal GUI PATH', () async {
      final env = _mac(files: [
        '$_home/.local/bin/cursor',
        '/opt/homebrew/bin/subl',
        '$_home/Library/Application Support/JetBrains/Toolbox/scripts/studio',
      ]);
      final detected = await IdeDetector(env).detectAll();
      expect(
        {for (final ide in detected) ide.id: ide.executable},
        {
          'Cursor': '$_home/.local/bin/cursor',
          'AndroidStudio':
              '$_home/Library/Application Support/JetBrains/Toolbox/scripts/studio',
          'SublimeText': '/opt/homebrew/bin/subl',
        },
      );
    });

    test('looks up apps elsewhere by bundle id with Spotlight', () async {
      final env = _mac(
        directories: [
          '/Volumes/Zed/Zed.app',
          '$_home/Downloads/Zed.app',
        ],
        processes: {
          "mdfind kMDItemCFBundleIdentifier == 'dev.zed.Zed'":
              const IdeProcessResult(
            0,
            '/Volumes/Zed/Zed.app\n$_home/Downloads/Zed.app\n',
          ),
        },
      );
      final ide = await IdeDetector(env).detect(_launcher('Zed'));
      // The mounted installer image is ignored
      expect(ide?.appPath, '$_home/Downloads/Zed.app');
    });

    test('Spotlight results that no longer exist are ignored', () async {
      final env = _mac(processes: {
        "mdfind kMDItemCFBundleIdentifier == 'dev.zed.Zed'":
            const IdeProcessResult(0, '/Applications/Old/Zed.app\n'),
      });
      expect(await IdeDetector(env).detect(_launcher('Zed')), isNull);
    });

    test('Xcode opens the iOS workspace when there is one', () async {
      final env = _mac(directories: [
        '/Applications/Xcode.app',
        '/work/app/ios/Runner.xcworkspace',
      ]);
      final command = await _command(env, 'XCode', '/work/app');
      expect(command.arguments, [
        '-a',
        '/Applications/Xcode.app',
        '/work/app/ios/Runner.xcworkspace'
      ]);
    });

    test('Xcode opens the folder when there is no workspace', () async {
      final env = _mac(directories: ['/Applications/Xcode.app']);
      final command = await _command(env, 'XCode', '/work/app');
      expect(command.arguments, ['-a', '/Applications/Xcode.app', '/work/app']);
    });

    test('Claude and Codex open deep links with the encoded folder', () async {
      final env = _mac(directories: [
        '/Applications/Claude.app',
        '/Applications/ChatGPT.app',
        '$_home/Applications/Claude Code URL Handler.app',
      ]);
      expect(await _detectedIds(env), ['Claude', 'ClaudeCode', 'Codex']);

      const folder = '/Users/me/my app&co';
      expect((await _command(env, 'Claude', folder)).url,
          'claude://code/new?folder=%2FUsers%2Fme%2Fmy%20app%26co');
      expect((await _command(env, 'ClaudeCode', folder)).url,
          'claude-cli://open?cwd=%2FUsers%2Fme%2Fmy%20app%26co');
      expect((await _command(env, 'Codex', folder)).url,
          'codex://threads/new?path=%2FUsers%2Fme%2Fmy%20app%26co');
    });

    test('T3 Code needs both the app and its t3 launcher', () async {
      final appOnly = _mac(directories: ['/Applications/T3 Code.app']);
      expect(await IdeDetector(appOnly).detect(_launcher('T3Code')), isNull);

      final launcherOnly = _mac(files: ['$_home/.t3/bin/t3']);
      expect(
          await IdeDetector(launcherOnly).detect(_launcher('T3Code')), isNull);

      final both = _mac(
        directories: ['/Applications/T3 Code (Nightly).app'],
        files: ['$_home/.t3/bin/t3'],
      );
      final ide = await IdeDetector(both).detect(_launcher('T3Code'));
      final plan = await buildLaunchPlan(ide!, '/work/app', both);
      expect(plan.command.executable, '$_home/.t3/bin/t3');
      expect(plan.command.arguments, ['app', '/work/app']);
      expect(plan.command.waitForExit, isTrue);
      expect(plan.startApp?.arguments,
          ['-a', '/Applications/T3 Code (Nightly).app']);
    });

    test('Paseo uses its bundled CLI', () async {
      final env = _mac(
        directories: ['/Applications/Paseo.app'],
        files: ['/Applications/Paseo.app/Contents/Resources/bin/paseo'],
      );
      final command = await _command(env, 'Paseo', '/work/app');
      expect(command.executable,
          '/Applications/Paseo.app/Contents/Resources/bin/paseo');
      expect(command.arguments, ['/work/app']);
    });

    test('custom application opens with open -a', () async {
      final env = _mac();
      final ide = customIde('/Applications/Nova.app')!;
      final plan = await buildLaunchPlan(ide, '/work/app', env);
      expect(plan.command.executable, 'open');
      expect(plan.command.arguments,
          ['-a', '/Applications/Nova.app', '/work/app']);
    });
  });

  group('Windows detection', () {
    const localAppData = r'C:\Users\me\AppData\Local';
    const programFiles = r'C:\Program Files';

    FakeIdeEnvironment windows({
      Iterable<String> files = const [],
      Iterable<String> directories = const [],
      Map<String, IdeProcessResult>? processes,
      String path = r'C:\Windows\system32;C:\Windows',
    }) {
      return FakeIdeEnvironment(
        platform: HostPlatform.windows,
        variables: {
          'USERPROFILE': r'C:\Users\me',
          // Windows variable names are case-insensitive
          'LocalAppData': localAppData,
          'APPDATA': r'C:\Users\me\AppData\Roaming',
          'ProgramFiles': programFiles,
          'Path': path,
        },
        files: files,
        directories: directories,
        processes: processes,
      );
    }

    test('finds user installs and runs .cmd scripts in a shell', () async {
      final env = windows(files: [
        '$localAppData\\Programs\\Microsoft VS Code\\bin\\code.cmd',
        '$localAppData\\Programs\\cursor\\resources\\app\\bin\\cursor.cmd',
      ]);
      expect(await _detectedIds(env), ['VSCode', 'Cursor']);

      final command = await _command(env, 'VSCode', r'C:\work\my app');
      expect(command.executable,
          '$localAppData\\Programs\\Microsoft VS Code\\bin\\code.cmd');
      expect(command.arguments, [r'C:\work\my app']);
      expect(command.runInShell, isTrue);
    });

    test('expands versioned JetBrains folders, newest first', () async {
      final env = windows(files: [
        '$programFiles\\JetBrains\\IntelliJ IDEA 2024.1\\bin\\idea64.exe',
        '$programFiles\\JetBrains\\IntelliJ IDEA 2025.3\\bin\\idea64.exe',
        '$programFiles\\Android\\Android Studio\\bin\\studio64.exe',
      ]);
      final detected = await IdeDetector(env).detectAll();
      expect(
        {for (final ide in detected) ide.id: ide.executable},
        {
          'AndroidStudio':
              '$programFiles\\Android\\Android Studio\\bin\\studio64.exe',
          'IntelliJ':
              '$programFiles\\JetBrains\\IntelliJ IDEA 2025.3\\bin\\idea64.exe',
        },
      );
    });

    test('searches PATH with Windows extensions', () async {
      final env = windows(
        path: r'C:\Windows;C:\tools\zed',
        files: [r'C:\tools\zed\zed.exe'],
      );
      final ide = await IdeDetector(env).detect(_launcher('Zed'));
      expect(ide?.executable, r'C:\tools\zed\zed.exe');
    });

    test('finds Toolbox scripts', () async {
      final env = windows(files: [
        '$localAppData\\JetBrains\\Toolbox\\scripts\\studio.cmd',
      ]);
      final ide = await IdeDetector(env).detect(_launcher('AndroidStudio'));
      expect(ide?.executable,
          '$localAppData\\JetBrains\\Toolbox\\scripts\\studio.cmd');
    });

    test('detects deep link apps by their registered URL scheme', () async {
      final env = windows(processes: {
        r'reg query HKCR\codex': const IdeProcessResult(0, ''),
      });
      expect(await _detectedIds(env), ['Codex']);
    });

    test('detects packaged apps by their protocol extension', () async {
      final env = windows(processes: {
        r'reg query HKCU\Software\Classes\Local Settings\Software\Microsoft'
                r'\Windows\CurrentVersion\AppModel\PackageRepository'
                r'\Extensions\windows.protocol\claude':
            const IdeProcessResult(0, ''),
      });
      expect(await _detectedIds(env), ['Claude']);
    });

    test('Xcode is never offered', () async {
      final env = windows(files: [r'C:\Applications\Xcode.app']);
      expect(await IdeDetector(env).detect(_launcher('XCode')), isNull);
    });
  });

  group('Linux detection', () {
    FakeIdeEnvironment linux({
      Iterable<String> files = const [],
      Map<String, IdeProcessResult>? processes,
    }) {
      return FakeIdeEnvironment(
        platform: HostPlatform.linux,
        variables: {'HOME': '/home/me', 'PATH': '/usr/bin:/bin'},
        files: files,
        processes: processes,
      );
    }

    test('finds snap, flatpak, /opt and Toolbox installs', () async {
      final env = linux(files: [
        '/snap/bin/code',
        '/var/lib/flatpak/exports/bin/dev.zed.Zed',
        '/opt/android-studio/bin/studio.sh',
        '/home/me/.local/share/JetBrains/Toolbox/scripts/idea',
      ]);
      final detected = await IdeDetector(env).detectAll();
      expect(
        {for (final ide in detected) ide.id: ide.executable},
        {
          'VSCode': '/snap/bin/code',
          'Zed': '/var/lib/flatpak/exports/bin/dev.zed.Zed',
          'AndroidStudio': '/opt/android-studio/bin/studio.sh',
          'IntelliJ': '/home/me/.local/share/JetBrains/Toolbox/scripts/idea',
        },
      );
    });

    test('detects deep link apps through xdg-mime', () async {
      final env = linux(processes: {
        'xdg-mime query default x-scheme-handler/claude-cli':
            const IdeProcessResult(0, 'claude-code-url-handler.desktop\n'),
        // Exit code 0 with no handler means it is not registered
        'xdg-mime query default x-scheme-handler/codex':
            const IdeProcessResult(0, '\n'),
      });
      expect(await _detectedIds(env), ['ClaudeCode']);
    });

    test('custom executable runs directly', () async {
      final env = linux();
      final plan = await buildLaunchPlan(
          customIde('/opt/kate/bin/kate')!, '/work/app', env);
      expect(plan.command.executable, '/opt/kate/bin/kate');
      expect(plan.command.arguments, ['/work/app']);
    });

    test('custom without a location opens the folder', () async {
      final env = linux();
      final ide = DetectedIde(_launcher('Custom'));
      final plan = await buildLaunchPlan(ide, '/work/app', env);
      expect(plan.command.executable, 'xdg-open');
    });
  });

  group('selected IDE', () {
    final vscode = DetectedIde(_launcher('VSCode'), executable: '/bin/code');

    test('resolves an installed launcher', () {
      expect(resolveSelectedIde('VSCode', [vscode]), same(vscode));
    });

    test('is null when the saved launcher is no longer installed', () {
      expect(resolveSelectedIde('Cursor', [vscode]), isNull);
      expect(resolveSelectedIde('SomeFutureIde', [vscode]), isNull);
      expect(resolveSelectedIde(null, [vscode]), isNull);
    });

    test('custom resolves with its location', () {
      final ide = resolveSelectedIde('Custom', const [],
          customLocation: '/Applications/Nova.app');
      expect(ide?.executable, '/Applications/Nova.app');
    });
  });
}
