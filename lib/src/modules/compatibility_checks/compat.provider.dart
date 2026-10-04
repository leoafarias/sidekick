import 'dart:io';

import 'package:hooks_riverpod/legacy.dart';
import 'package:sidekick/src/modules/compatibility_checks/compat.utils.dart';
import 'compat.dto.dart';

/// Updater provider
final compatProvider =
    StateNotifierProvider<CompatStateNotifier, CompatibilityCheck>(
        (_) => CompatStateNotifier());

/// Update state notifier
class CompatStateNotifier extends StateNotifier<CompatibilityCheck> {
  /// COnstructor
  CompatStateNotifier() : super(CompatibilityCheck.notReady()) {
    checkRequirements();
  }

  /// Check for latest release
  Future<void> checkRequirements() async {
    final chocoState = Platform.isWindows ? await isChocoInstalled() : false;
    final brewState =
        Platform.isLinux || Platform.isMacOS ? await isBrewInstalled() : false;
    final gitState = await isGitInstalled();
    state = CompatibilityCheck(
      git: gitState,
      choco: chocoState,
      brew: brewState,
    );
  }

  void applyValid() {
    state = state.copyWith(fvm: true, git: true);
  }
}
