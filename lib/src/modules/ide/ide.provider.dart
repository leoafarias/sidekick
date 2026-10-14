import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'ide_detector.dart';
import 'ide_environment.dart';
import 'ide_launcher.dart';

/// Machine access used for detection, overridden in tests
final ideEnvironmentProvider = Provider<IdeEnvironment>(
  (ref) => const LocalIdeEnvironment(),
);

/// Installed launchers. Detected in the background the first time it is
/// read and cached until [IdeDetectionNotifier.refresh].
final ideDetectionProvider =
    AsyncNotifierProvider<IdeDetectionNotifier, List<DetectedIde>>(
  IdeDetectionNotifier.new,
);

class IdeDetectionNotifier extends AsyncNotifier<List<DetectedIde>> {
  @override
  Future<List<DetectedIde>> build() {
    return IdeDetector(ref.watch(ideEnvironmentProvider)).detectAll();
  }

  /// Detects again, keeping the previous result while it runs
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// The launcher stored in settings, if it can be used on this machine.
///
/// Returns null when nothing is selected, while detecting, or when the
/// selected launcher is no longer installed.
DetectedIde? resolveSelectedIde(
  String? selectedId,
  List<DetectedIde> detected, {
  String? customLocation,
}) {
  final launcher = ideLauncherById(selectedId);
  if (launcher == null) return null;
  if (launcher.isCustom) {
    return DetectedIde(launcher, executable: customLocation);
  }
  for (final ide in detected) {
    if (ide.launcher.id == launcher.id) return ide;
  }
  return null;
}

/// The custom launcher as a [DetectedIde], null if no location was picked
DetectedIde? customIde(String? customLocation) {
  if (customLocation == null || customLocation.isEmpty) return null;
  return DetectedIde(
    ideLauncherById(customIdeId)!,
    executable: customLocation,
  );
}
