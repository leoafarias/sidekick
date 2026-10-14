// Catalog of the IDEs, editors and coding agents Sidekick can open a project
// folder in. This file is pure Dart (no Flutter) so detection can be tested.

/// Platforms Sidekick runs on
enum HostPlatform { macos, windows, linux }

/// How a launcher opens a folder once it has been detected
enum IdeOpenKind {
  /// Run `<executable> <folder>`. On macOS, when only the app bundle was
  /// found, fall back to `open -a <App> <folder>`.
  cli,

  /// Open a deep link built from [IdeLauncher.urlTemplate].
  url,

  /// Open the Xcode workspace of the Flutter project.
  xcode,

  /// T3 Code: `t3 app <folder>`, which needs the desktop app running.
  t3,

  /// User selected executable or app.
  custom,
}

/// How a macOS app bundle receives a folder when there is no CLI
enum MacAppOpenMode {
  /// `open -a <App> <folder>`: the folder is passed as a document.
  document,

  /// `open -na <App> --args <folder>`: the folder is passed in argv. JetBrains
  /// IDEs and Paseo document this; the new instance hands the folder over to
  /// an already running one.
  arguments,
}

/// A supported launcher and where to look for it on each platform.
///
/// Path templates may use `{home}`, `{localAppData}`, `{appData}`,
/// `{programFiles}`, `{programFilesX86}` and `{userProfile}`, and a `*`
/// wildcard inside a single path segment.
class IdeLauncher {
  const IdeLauncher({
    required this.id,
    required this.name,
    required this.kind,
    this.legacyIds = const [],
    this.macBundleIds = const [],
    this.macAppNames = const [],
    this.macBundleCli = const [],
    this.macAppOpenMode = MacAppOpenMode.document,
    this.cliNames = const [],
    this.macPaths = const [],
    this.windowsPaths = const [],
    this.linuxPaths = const [],
    this.urlTemplate,
    this.urlSchemes = const [],
    this.platforms = HostPlatform.values,
  });

  /// Value persisted in settings (`SidekickSettings.ide`)
  final String id;

  /// Display name, a brand name so it is not translated
  final String name;

  final IdeOpenKind kind;

  /// Older stored values that resolve to this launcher
  final List<String> legacyIds;

  /// macOS bundle identifiers, looked up with Spotlight
  final List<String> macBundleIds;

  /// macOS app bundle names, looked up in /Applications and ~/Applications
  final List<String> macAppNames;

  /// CLI inside the app bundle, relative to the `.app` directory
  final List<String> macBundleCli;

  final MacAppOpenMode macAppOpenMode;

  /// Executable names searched in PATH and well-known bin directories. On
  /// Windows `.exe`, `.cmd` and `.bat` are tried.
  final List<String> cliNames;

  /// Absolute executable path templates per platform
  final List<String> macPaths;
  final List<String> windowsPaths;
  final List<String> linuxPaths;

  /// Deep link for [IdeOpenKind.url]; `{path}` is replaced with the
  /// URL-encoded absolute folder path.
  final String? urlTemplate;

  /// URL schemes whose registration marks the launcher as installed on
  /// Windows and Linux, where there is no app bundle to look for.
  final List<String> urlSchemes;

  final List<HostPlatform> platforms;

  bool get isCustom => kind == IdeOpenKind.custom;

  /// Whether a stored settings value refers to this launcher
  bool matchesId(String value) {
    final lower = value.toLowerCase();
    return id.toLowerCase() == lower ||
        legacyIds.any((legacy) => legacy.toLowerCase() == lower);
  }
}

/// Settings value of the custom launcher
const customIdeId = 'Custom';

/// All launchers. Order is the order shown in the UI.
///
/// The ids `VSCode`, `XCode` and `Custom` are the values older versions of
/// Sidekick stored, so they are kept as they are.
const ideLaunchers = <IdeLauncher>[
  IdeLauncher(
    id: 'VSCode',
    name: 'VS Code',
    kind: IdeOpenKind.cli,
    legacyIds: ['vscode', 'code'],
    macBundleIds: ['com.microsoft.VSCode'],
    macAppNames: ['Visual Studio Code.app'],
    macBundleCli: ['Contents/Resources/app/bin/code'],
    cliNames: ['code'],
    windowsPaths: [
      r'{localAppData}\Programs\Microsoft VS Code\bin\code.cmd',
      r'{programFiles}\Microsoft VS Code\bin\code.cmd',
    ],
    linuxPaths: [
      '/usr/share/code/bin/code',
      '/var/lib/flatpak/exports/bin/com.visualstudio.code',
      '{home}/.local/share/flatpak/exports/bin/com.visualstudio.code',
    ],
  ),
  IdeLauncher(
    id: 'VSCodeInsiders',
    name: 'VS Code Insiders',
    kind: IdeOpenKind.cli,
    macBundleIds: ['com.microsoft.VSCodeInsiders'],
    macAppNames: ['Visual Studio Code - Insiders.app'],
    macBundleCli: ['Contents/Resources/app/bin/code-insiders'],
    cliNames: ['code-insiders'],
    windowsPaths: [
      r'{localAppData}\Programs\Microsoft VS Code Insiders\bin\code-insiders.cmd',
      r'{programFiles}\Microsoft VS Code Insiders\bin\code-insiders.cmd',
    ],
    linuxPaths: ['/usr/share/code-insiders/bin/code-insiders'],
  ),
  IdeLauncher(
    id: 'VSCodium',
    name: 'VSCodium',
    kind: IdeOpenKind.cli,
    macBundleIds: ['com.vscodium'],
    macAppNames: ['VSCodium.app'],
    macBundleCli: ['Contents/Resources/app/bin/codium'],
    cliNames: ['codium'],
    windowsPaths: [
      r'{localAppData}\Programs\VSCodium\bin\codium.cmd',
      r'{programFiles}\VSCodium\bin\codium.cmd',
    ],
    linuxPaths: [
      '/usr/share/codium/bin/codium',
      '/var/lib/flatpak/exports/bin/com.vscodium.codium',
      '{home}/.local/share/flatpak/exports/bin/com.vscodium.codium',
    ],
  ),
  IdeLauncher(
    id: 'Cursor',
    name: 'Cursor',
    kind: IdeOpenKind.cli,
    macBundleIds: ['com.todesktop.230313mzl4w4u92'],
    macAppNames: ['Cursor.app'],
    macBundleCli: ['Contents/Resources/app/bin/cursor'],
    cliNames: ['cursor'],
    windowsPaths: [
      r'{localAppData}\Programs\cursor\resources\app\bin\cursor.cmd',
      r'{programFiles}\cursor\resources\app\bin\cursor.cmd',
    ],
    linuxPaths: [
      '/usr/share/cursor/bin/cursor',
      '/opt/cursor/resources/app/bin/cursor',
      '/opt/Cursor/resources/app/bin/cursor',
    ],
  ),
  // Windsurf was renamed Devin Desktop in 2026. Both names are matched, and
  // `windsurf` is still shipped next to `devin-desktop`.
  IdeLauncher(
    id: 'Windsurf',
    name: 'Windsurf',
    kind: IdeOpenKind.cli,
    macBundleIds: ['com.exafunction.windsurf'],
    macAppNames: ['Windsurf.app', 'Devin.app'],
    macBundleCli: [
      'Contents/Resources/app/bin/windsurf',
      'Contents/Resources/app/bin/devin-desktop',
    ],
    cliNames: ['windsurf', 'devin-desktop'],
    macPaths: ['{home}/.codeium/windsurf/bin/windsurf'],
    windowsPaths: [
      r'{localAppData}\Programs\Windsurf\bin\windsurf.cmd',
      r'{localAppData}\Programs\Devin\bin\devin-desktop.cmd',
    ],
    linuxPaths: [
      '{home}/.codeium/windsurf/bin/windsurf',
      '/usr/share/windsurf/bin/windsurf',
    ],
  ),
  IdeLauncher(
    id: 'Zed',
    name: 'Zed',
    kind: IdeOpenKind.cli,
    macBundleIds: ['dev.zed.Zed'],
    macAppNames: ['Zed.app'],
    macBundleCli: ['Contents/MacOS/cli'],
    cliNames: ['zed', 'zeditor'],
    windowsPaths: [r'{localAppData}\Programs\Zed\bin\zed.exe'],
    linuxPaths: [
      '{home}/.local/zed.app/bin/zed',
      '/var/lib/flatpak/exports/bin/dev.zed.Zed',
      '{home}/.local/share/flatpak/exports/bin/dev.zed.Zed',
    ],
  ),
  // `agy` is not searched: the standalone Antigravity agent CLI uses the same
  // name and would not open the editor.
  IdeLauncher(
    id: 'Antigravity',
    name: 'Antigravity',
    kind: IdeOpenKind.cli,
    macBundleIds: ['com.google.antigravity'],
    macAppNames: ['Antigravity.app'],
    macBundleCli: ['Contents/Resources/app/bin/antigravity'],
    cliNames: ['antigravity'],
    windowsPaths: [
      r'{localAppData}\Programs\Antigravity\bin\antigravity.cmd',
    ],
    linuxPaths: ['/usr/share/antigravity/bin/antigravity'],
  ),
  IdeLauncher(
    id: 'AndroidStudio',
    name: 'Android Studio',
    kind: IdeOpenKind.cli,
    macBundleIds: ['com.google.android.studio'],
    macAppNames: ['Android Studio.app'],
    macAppOpenMode: MacAppOpenMode.arguments,
    // Toolbox generates a `studio` script; the `studio` binary in the bundle
    // is the IDE itself and would start a second instance, so it is not used.
    cliNames: ['studio'],
    windowsPaths: [
      r'{programFiles}\Android\Android Studio\bin\studio64.exe',
      r'{localAppData}\Programs\Android Studio\bin\studio64.exe',
    ],
    linuxPaths: [
      '/opt/android-studio/bin/studio.sh',
      '/usr/local/android-studio/bin/studio.sh',
      '{home}/android-studio/bin/studio.sh',
      '/snap/bin/android-studio',
    ],
  ),
  IdeLauncher(
    id: 'IntelliJ',
    name: 'IntelliJ IDEA',
    kind: IdeOpenKind.cli,
    macBundleIds: ['com.jetbrains.intellij', 'com.jetbrains.intellij.ce'],
    macAppNames: [
      'IntelliJ IDEA.app',
      'IntelliJ IDEA Ultimate.app',
      'IntelliJ IDEA CE.app',
      'IntelliJ IDEA Community Edition.app',
    ],
    macAppOpenMode: MacAppOpenMode.arguments,
    cliNames: ['idea'],
    windowsPaths: [r'{programFiles}\JetBrains\IntelliJ IDEA*\bin\idea64.exe'],
    linuxPaths: [
      '/opt/idea/bin/idea.sh',
      '/opt/intellij-idea*/bin/idea.sh',
      '/snap/bin/intellij-idea',
      '/snap/bin/intellij-idea-ultimate',
      '/snap/bin/intellij-idea-community',
    ],
  ),
  IdeLauncher(
    id: 'SublimeText',
    name: 'Sublime Text',
    kind: IdeOpenKind.cli,
    macBundleIds: ['com.sublimetext.4', 'com.sublimetext.3'],
    macAppNames: ['Sublime Text.app'],
    macBundleCli: ['Contents/SharedSupport/bin/subl'],
    cliNames: ['subl'],
    windowsPaths: [r'{programFiles}\Sublime Text\subl.exe'],
    linuxPaths: ['/opt/sublime_text/sublime_text'],
  ),
  IdeLauncher(
    id: 'XCode',
    name: 'Xcode',
    kind: IdeOpenKind.xcode,
    legacyIds: ['Xcode'],
    macBundleIds: ['com.apple.dt.Xcode'],
    macAppNames: ['Xcode.app'],
    platforms: [HostPlatform.macos],
  ),
  // Claude desktop opens a new Claude Code session on the folder. This is the
  // link the app's own Finder Quick Action ("New Claude Code Session Here")
  // uses.
  IdeLauncher(
    id: 'Claude',
    name: 'Claude',
    kind: IdeOpenKind.url,
    macBundleIds: ['com.anthropic.claudefordesktop'],
    macAppNames: ['Claude.app'],
    windowsPaths: [r'{localAppData}\AnthropicClaude\claude.exe'],
    urlTemplate: 'claude://code/new?folder={path}',
    urlSchemes: ['claude'],
  ),
  // Claude Code in a terminal, through the `claude-cli://` handler the CLI
  // registers (https://code.claude.com/docs/en/deep-links).
  IdeLauncher(
    id: 'ClaudeCode',
    name: 'Claude Code',
    kind: IdeOpenKind.url,
    macBundleIds: ['com.anthropic.claude-code-url-handler'],
    macAppNames: ['Claude Code URL Handler.app'],
    linuxPaths: [
      '{home}/.local/share/applications/claude-code-url-handler.desktop',
    ],
    urlTemplate: 'claude-cli://open?cwd={path}',
    urlSchemes: ['claude-cli'],
  ),
  // Codex app (now shipped as the ChatGPT desktop app on macOS), documented
  // deep link https://learn.chatgpt.com/docs/reference/commands.md
  IdeLauncher(
    id: 'Codex',
    name: 'Codex',
    kind: IdeOpenKind.url,
    macBundleIds: ['com.openai.codex'],
    macAppNames: ['Codex.app', 'ChatGPT.app'],
    urlTemplate: 'codex://threads/new?path={path}',
    urlSchemes: ['codex'],
  ),
  // The T3 Code desktop app ignores folders passed in argv; its `t3` launcher
  // (written by the app to ~/.t3/bin) opens one with `t3 app <folder>`.
  IdeLauncher(
    id: 'T3Code',
    name: 'T3 Code',
    kind: IdeOpenKind.t3,
    macBundleIds: ['com.t3tools.t3code'],
    macAppNames: ['T3 Code.app', 'T3 Code (Nightly).app'],
    cliNames: ['t3'],
    macPaths: ['{home}/.t3/bin/t3'],
    windowsPaths: [r'{userProfile}\.t3\bin\t3.cmd'],
    linuxPaths: ['{home}/.t3/bin/t3'],
  ),
  // Paseo reads an absolute folder from argv, which is what its own CLI does
  // (https://paseo.sh/docs/cli.md).
  IdeLauncher(
    id: 'Paseo',
    name: 'Paseo',
    kind: IdeOpenKind.cli,
    macBundleIds: ['sh.paseo.desktop'],
    macAppNames: ['Paseo.app'],
    macBundleCli: ['Contents/Resources/bin/paseo'],
    macAppOpenMode: MacAppOpenMode.arguments,
    cliNames: ['paseo'],
    windowsPaths: [r'{localAppData}\Programs\Paseo\Paseo.exe'],
    linuxPaths: [
      '/usr/bin/Paseo',
      '/opt/Paseo/Paseo',
      '{home}/Applications/Paseo.AppImage',
    ],
  ),
  IdeLauncher(
    id: customIdeId,
    name: 'Custom',
    kind: IdeOpenKind.custom,
  ),
];

/// Finds a launcher by its stored settings value
IdeLauncher? ideLauncherById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final launcher in ideLaunchers) {
    if (launcher.matchesId(id)) return launcher;
  }
  return null;
}

/// Normalizes a stored `ide` value: legacy ids resolve to the current one,
/// `none` and empty values to null. Unknown values are kept so they can be
/// shown as unavailable instead of being silently dropped.
String? migrateIdeId(String? stored) {
  if (stored == null || stored.isEmpty || stored == 'none') return null;
  return ideLauncherById(stored)?.id ?? stored;
}
