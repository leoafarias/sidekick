import 'package:sidekick/src/modules/ide/ide_environment.dart';
import 'package:sidekick/src/modules/ide/ide_launcher.dart';

/// In-memory [IdeEnvironment]: a set of files and directories, environment
/// variables and canned helper process results.
class FakeIdeEnvironment implements IdeEnvironment {
  FakeIdeEnvironment({
    required this.platform,
    Map<String, String>? variables,
    Iterable<String> files = const [],
    Iterable<String> directories = const [],
    Map<String, IdeProcessResult>? processes,
  })  : variables = variables ?? {},
        files = {...files},
        directories = {...directories},
        processes = processes ?? {} {
    // Parents of every file and directory exist too
    for (final path in [...this.files, ...this.directories]) {
      var parent = _parent(path);
      while (parent != null) {
        this.directories.add(parent);
        parent = _parent(parent);
      }
    }
  }

  @override
  final HostPlatform platform;

  @override
  final Map<String, String> variables;

  final Set<String> files;
  final Set<String> directories;

  /// Keyed by `executable arg1 arg2`
  final Map<String, IdeProcessResult> processes;

  /// Every process that was run, for assertions
  final List<String> ran = [];

  String get _separator => platform == HostPlatform.windows ? r'\' : '/';

  String? _parent(String path) {
    final index = path.lastIndexOf(_separator);
    if (index <= 0) return null;
    final parent = path.substring(0, index);
    // Stop at a Windows drive root like `C:`
    if (parent.endsWith(':')) return null;
    return parent;
  }

  @override
  Future<bool> fileExists(String path) async => files.contains(path);

  @override
  Future<bool> directoryExists(String path) async => directories.contains(path);

  @override
  Future<List<String>> listDirectory(String path) async {
    final prefix = '$path$_separator';
    return {
      for (final entry in [...files, ...directories])
        if (entry.startsWith(prefix))
          entry.substring(prefix.length).split(_separator).first,
    }.toList();
  }

  @override
  Future<IdeProcessResult> run(
      String executable, List<String> arguments) async {
    final key = [executable, ...arguments].join(' ');
    ran.add(key);
    return processes[key] ?? const IdeProcessResult(1, '');
  }
}
