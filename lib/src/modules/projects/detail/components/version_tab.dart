import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../../components/atoms/typography.dart';
import '../../../common/utils/helpers.dart';
import '../../../common/utils/notify.dart';
import '../project_detail.provider.dart';
import '../project_details.dart';
import '../project_version.dart';

/// Shows and bumps the app version in pubspec.yaml
class VersionTab extends HookConsumerWidget {
  /// Constructor
  const VersionTab({required this.details, super.key});

  /// Details read from disk
  final ProjectDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = details.rawVersion;
    final current = details.version;
    final controller = useTextEditingController(text: raw ?? '');
    final input = useValueListenable(controller);
    final saving = useState(false);

    // Show the new version after an edit
    useEffect(() {
      controller.text = raw ?? '';
      return null;
    }, [raw]);

    Version? parsedInput;
    try {
      parsedInput = Version.parse(input.text.trim());
    } on FormatException {
      parsedInput = null;
    }

    Future<void> run(Future<Version> Function() edit) async {
      if (saving.value) return;
      final i18next = context.i18next;
      saving.value = true;
      try {
        final version = await edit();
        notify(i18next.t(
          'modules:projects.detail.versionUpdated',
          variables: {'version': version.toString()},
        ));
      } catch (e) {
        notifyError(e.toString());
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    final editor = ref.read(projectEditorProvider);

    Widget bumpButton(VersionBump bump, String label) {
      final next = bumpVersion(current ?? Version.none, bump);
      final enabled =
          next != null && !saving.value && (current != null || raw == null);
      return SizedBox(
        width: 150,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed:
              enabled ? () => run(() => editor.bump(details.path, bump)) : null,
          child: Column(
            children: [
              Text(context.i18n(label)),
              const SizedBox(height: 4),
              Text(
                next?.toString() ?? '-',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Caption(context.i18n('modules:projects.detail.currentVersion')),
        const SizedBox(height: 5),
        Text(
          raw ?? context.i18n('modules:projects.detail.noVersion'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (raw != null && current == null) ...[
          const SizedBox(height: 5),
          Text(
            context.i18n('modules:projects.detail.invalidVersion'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 25),
        Subheading(context.i18n('modules:projects.detail.bumpVersion')),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            bumpButton(VersionBump.major, 'modules:projects.detail.major'),
            bumpButton(VersionBump.minor, 'modules:projects.detail.minor'),
            bumpButton(VersionBump.patch, 'modules:projects.detail.patch'),
            bumpButton(VersionBump.build, 'modules:projects.detail.build'),
          ],
        ),
        const SizedBox(height: 10),
        Caption(context.i18n('modules:projects.detail.bumpHint')),
        const SizedBox(height: 25),
        Subheading(context.i18n('modules:projects.detail.setVersion')),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: '1.0.0+1',
                  errorText: input.text.trim().isEmpty || parsedInput != null
                      ? null
                      : context.i18n('modules:projects.detail.invalidVersion'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: parsedInput == null ||
                      parsedInput.toString() == raw ||
                      saving.value
                  ? null
                  : () {
                      final version = parsedInput!;
                      run(() async {
                        await editor.setVersion(details.path, version);
                        return version;
                      });
                    },
              child: Text(context.i18n('modules:projects.detail.save')),
            ),
          ],
        ),
      ],
    );
  }
}
