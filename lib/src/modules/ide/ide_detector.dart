import 'package:path/path.dart' as p;

import 'ide_environment.dart';
import 'ide_launcher.dart';

/// A launcher found on this machine
class DetectedIde {
  const DetectedIde(
    this.launcher, {
    this.appPath,
    this.executable,
  });

  final IdeLauncher launcher;

  /// macOS `.app` bundle, if one was found
  final String? appPath;

  /// CLI or binary that opens a folder, if one was found. For the custom
  /// launcher this is the location the user picked.
  final String? executable;

  String get id => launcher.id;

  String get name => launcher.name;

  @override
  String toString() =>
      'DetectedIde(${launcher.id}, app: $appPath, executable: $executable)';
}

/// Finds which launchers are installed.
///
/// Apps started from Finder, the Dock or the Start menu don't inherit the
/// login shell's PATH (on macOS it is just `/usr/bin:/bin:/usr/sbin:/sbin`),
/// so besides PATH this checks app bundles and the well-known install and
/// bin directories of each platform.
class IdeDetector {
  IdeDetector(this.env);

  final IdeEnvironment env;

  bool get _isWindows => env.platform == HostPlatform.windows;

  p.Context get _path => _isWindows ? p.windows : p.posix;

  /// Case-insensitive lookup, Windows variable names vary in case
  String? _variable(String name) {
    final value = env.variables[name];
    if (value != null) return value;
    final lower = name.toLowerCase();
    for (final entry in env.variables.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }

  String? get _home =>
      _isWindows ? _variable('USERPROFILE') : _variable('HOME');

  /// Replaces `{home}`-style placeholders, null if one is not set
  String? _expandTemplate(String template) {
    final values = <String, String?>{
      'home': _home,
      'userProfile': _variable('USERPROFILE'),
      'localAppData': _variable('LOCALAPPDATA'),
      'appData': _variable('APPDATA'),
      'programFiles': _variable('ProgramFiles'),
      'programFilesX86': _variable('ProgramFiles(x86)'),
    };
    var missing = false;
    final expanded = template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (match) {
      final value = values[match.group(1)];
      if (value == null || value.isEmpty) missing = true;
      return value ?? '';
    });
    return missing ? null : expanded;
  }

  /// Directories searched for CLIs: PATH, then well-known locations
  List<String> get searchDirectories {
    final pathVariable = _variable('PATH') ?? '';
    final entries = pathVariable
        .split(_isWindows ? ';' : ':')
        .where((entry) => entry.isNotEmpty)
        .toList();

    final wellKnown = switch (env.platform) {
      HostPlatform.macos => [
          '/opt/homebrew/bin',
          '/usr/local/bin',
          '/usr/bin',
          '/bin',
          '{home}/.local/bin',
          '{home}/bin',
          '{home}/Library/Application Support/JetBrains/Toolbox/scripts',
        ],
      HostPlatform.linux => [
          '/usr/local/bin',
          '/usr/bin',
          '/bin',
          '/snap/bin',
          '{home}/.local/bin',
          '{home}/bin',
          '{home}/.local/share/JetBrains/Toolbox/scripts',
        ],
      HostPlatform.windows => [
          r'{localAppData}\JetBrains\Toolbox\scripts',
          r'{userProfile}\.local\bin',
          r'{appData}\npm',
        ],
    };

    final directories = <String>[];
    for (final entry in [
      ...entries,
      ...wellKnown.map(_expandTemplate).whereType<String>(),
    ]) {
      if (!directories.contains(entry)) directories.add(entry);
    }
    return directories;
  }

  /// Detects all launchers supported on this platform, except custom
  Future<List<DetectedIde>> detectAll() async {
    final directories = searchDirectories;
    final results = await Future.wait(
      ideLaunchers.map((launcher) => detect(launcher, directories)),
    );
    return results.whereType<DetectedIde>().toList();
  }

  /// Detects a single launcher, null if it is not installed
  Future<DetectedIde?> detect(
    IdeLauncher launcher, [
    List<String>? directories,
  ]) async {
    if (launcher.isCustom || !launcher.platforms.contains(env.platform)) {
      return null;
    }

    final appPath =
        env.platform == HostPlatform.macos ? await _findMacApp(launcher) : null;
    final executable = await _findExecutable(
      launcher,
      appPath,
      directories ?? searchDirectories,
    );

    final found = switch (launcher.kind) {
      IdeOpenKind.cli => appPath != null || executable != null,
      IdeOpenKind.xcode => appPath != null,
      IdeOpenKind.url => appPath != null ||
          executable != null ||
          (env.platform != HostPlatform.macos &&
              await _isUrlSchemeRegistered(launcher)),
      // The `t3` launcher runs the app's own binary, so on macOS both must be
      // there. Without the launcher a folder can't be opened at all.
      IdeOpenKind.t3 => executable != null &&
          (env.platform != HostPlatform.macos || appPath != null),
      IdeOpenKind.custom => false,
    };

    if (!found) return null;
    return DetectedIde(launcher, appPath: appPath, executable: executable);
  }

  Future<String?> _findMacApp(IdeLauncher launcher) async {
    final home = _home;
    final directories = [
      '/Applications',
      if (home != null) '$home/Applications',
      '/Applications/Setapp',
      if (home != null) '$home/Applications/JetBrains Toolbox',
    ];
    for (final name in launcher.macAppNames) {
      for (final directory in directories) {
        final candidate = '$directory/$name';
        if (await env.directoryExists(candidate)) return candidate;
      }
    }

    // Apps installed elsewhere, found by bundle id through Spotlight
    for (final bundleId in launcher.macBundleIds) {
      final result = await env.run(
        'mdfind',
        ["kMDItemCFBundleIdentifier == '$bundleId'"],
      );
      if (result.exitCode != 0) continue;
      final candidates = result.stdout
          .split('\n')
          .map((line) => line.trim())
          .where(_isUsableMacApp)
          .toList()
        // Prefer the shortest path, e.g. /Applications over a nested copy
        ..sort((a, b) => a.length.compareTo(b.length));
      for (final candidate in candidates) {
        if (await env.directoryExists(candidate)) return candidate;
      }
    }
    return null;
  }

  /// Skips mounted installers, the Trash and build products
  static bool _isUsableMacApp(String path) {
    return path.endsWith('.app') &&
        !path.startsWith('/Volumes/') &&
        !path.contains('/.Trash/') &&
        !path.contains('/DerivedData/') &&
        !path.contains('/Build/Products/');
  }

  Future<String?> _findExecutable(
    IdeLauncher launcher,
    String? appPath,
    List<String> directories,
  ) async {
    if (appPath != null) {
      for (final relative in launcher.macBundleCli) {
        final candidate = '$appPath/$relative';
        if (await env.fileExists(candidate)) return candidate;
      }
    }

    final templates = switch (env.platform) {
      HostPlatform.macos => launcher.macPaths,
      HostPlatform.windows => launcher.windowsPaths,
      HostPlatform.linux => launcher.linuxPaths,
    };
    for (final template in templates) {
      final expanded = _expandTemplate(template);
      if (expanded == null) continue;
      for (final candidate in await _expandWildcards(expanded)) {
        if (await env.fileExists(candidate)) return candidate;
      }
    }

    final extensions = _isWindows ? const ['.exe', '.cmd', '.bat'] : const [''];
    for (final directory in directories) {
      for (final name in launcher.cliNames) {
        for (final extension in extensions) {
          final candidate = _path.join(directory, '$name$extension');
          if (await env.fileExists(candidate)) return candidate;
        }
      }
    }
    return null;
  }

  /// Expands `*` inside path segments, e.g. `IntelliJ IDEA*`
  Future<List<String>> _expandWildcards(String path) async {
    if (!path.contains('*')) return [path];
    final segments = _path.split(path);
    var current = <String>[segments.first];
    for (final segment in segments.skip(1)) {
      if (!segment.contains('*')) {
        current = [for (final base in current) _path.join(base, segment)];
        continue;
      }
      final pattern = RegExp(
        '^${segment.split('*').map(RegExp.escape).join('.*')}\$',
        caseSensitive: !_isWindows,
      );
      final next = <String>[];
      for (final base in current) {
        final names = [...await env.listDirectory(base)]
          // Newest versions sort last, try them first
          ..sort((a, b) => b.compareTo(a));
        next.addAll([
          for (final name in names)
            if (pattern.hasMatch(name)) _path.join(base, name),
        ]);
      }
      current = next;
    }
    return current;
  }

  Future<bool> _isUrlSchemeRegistered(IdeLauncher launcher) async {
    for (final scheme in launcher.urlSchemes) {
      if (_isWindows) {
        // Classic installers register under HKCR, packaged (MSIX/Store) apps
        // under the AppModel package repository of the user.
        for (final key in [
          'HKCR\\$scheme',
          r'HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows'
              r'\CurrentVersion\AppModel\PackageRepository\Extensions'
              '\\windows.protocol\\$scheme',
        ]) {
          final result = await env.run('reg', ['query', key]);
          if (result.exitCode == 0) return true;
        }
      } else {
        final result = await env.run(
          'xdg-mime',
          ['query', 'default', 'x-scheme-handler/$scheme'],
        );
        if (result.exitCode == 0 && result.stdout.trim().isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }
}
