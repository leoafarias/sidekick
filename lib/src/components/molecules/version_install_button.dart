import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../modules/common/dto/release.dto.dart';
import '../../modules/fvm/fvm_queue.provider.dart';

class VersionInstallButton extends HookConsumerWidget {
  final ReleaseDto version;

  const VersionInstallButton(
    this.version, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedMsg =
        context.i18n('components:molecules.versionIsInstalled');
    final notInstalledMsg = context.i18n(
      'components:molecules.versionNotInstalledClickToInstall',
    );
    final isQueued = useState(false);
    final hovering = useState(false);
    final queueProvider = ref.watch(fvmQueueProvider);

    final isCached = version.isCached == true;

    useEffect(() {
      final isInstalling = queueProvider.activeItem != null &&
          queueProvider.activeItem?.version == version;

      if (isInstalling) {
        isQueued.value = true;
        return;
      }

      final queued = queueProvider.queue.firstWhereOrNull(
        (item) => item.version == version,
      );

      isQueued.value = queued != null;
      return;
    }, [queueProvider]);

    Future<void> onInstall() async {
      isQueued.value = true;
      // Add it to queue for installation
      ref.read(fvmQueueProvider.notifier).install(context, version);
    }

    Widget installIcon() {
      if ((isQueued.value && !isCached)) {
        return SizedBox(
          height: 20,
          width: 20,
          child: SpinKitFadingFour(
            size: 15,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
      }

      // Display warning icon instead of download arrow
      if (isCached && version.needSetup) {
        return Icon(MdiIcons.alert, size: 20);
      }

      if (isCached) {
        return Icon(
          Icons.check,
          size: 20,
          color: Theme.of(context).colorScheme.secondary,
        );
      }

      return const Icon(Icons.arrow_downward, size: 20);
    }

    return MouseRegion(
      onHover: (_) {
        if (!hovering.value) {
          hovering.value = true;
        }
      },
      onExit: (_) {
        if (hovering.value) {
          hovering.value = false;
        }
      },
      child: Opacity(
        opacity: isCached ? 0.3 : 1,
        child: IconButton(
          onPressed: onInstall,
          splashRadius: 20,
          icon: Tooltip(
            message: isCached ? installedMsg : notInstalledMsg,
            child: installIcon(),
          ),
        ),
      ),
    );
  }
}
