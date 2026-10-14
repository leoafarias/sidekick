import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../../components/atoms/typography.dart';
import '../../../common/utils/helpers.dart';
import '../../../common/utils/notify.dart';
import '../project_detail.provider.dart';
import '../project_details.dart';
import '../project_packages.dart';
import '../pub_dev_client.dart';
import 'detail_widgets.dart';

const _actionWidth = 100.0;

/// Dependencies with their resolved and latest versions
class PackagesTab extends ConsumerWidget {
  /// Constructor
  const PackagesTab({required this.details, super.key});

  /// Details read from disk
  final ProjectDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = details.packages;
    if (packages.isEmpty) {
      return DetailMessage(
        icon: Icons.inventory_2_outlined,
        message: context.i18n('modules:projects.detail.noDependencies'),
      );
    }

    final latest = <String, AsyncValue<Version>>{
      for (final package in packages)
        if (package.isOnPubDev)
          package.name: ref.watch(latestVersionProvider(package.name)),
    };

    final outdated = packages.where((package) {
      final status = package.statusFor(latest[package.name]?.value);
      return status == PackageStatus.upgradable ||
          status == PackageStatus.constraintOutdated;
    }).length;

    // Packages whose latest version failed for a reason other than not
    // being published on pub.dev (offline, timeout, server error)
    final unreachable = [
      for (final MapEntry(:key, :value) in latest.entries)
        if (value.hasError && !_isNotFound(value.error)) key,
    ];
    final loading = latest.values.any((value) => value.isLoading);

    void retry() {
      for (final package in unreachable) {
        ref.invalidate(latestVersionProvider(package));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (details.lockOutdated)
          NoticeBanner(
            message: context.i18n('modules:projects.detail.lockOutdated'),
          ),
        if (unreachable.isNotEmpty)
          NoticeBanner(
            icon: Icons.cloud_off,
            color: Colors.redAccent,
            message: context.i18n('modules:projects.detail.pubDevUnavailable'),
            action: TextButton(
              onPressed: retry,
              child: Text(context.i18n('modules:projects.detail.retry')),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
          child: Row(
            children: [
              // The count would be misleading while versions are missing
              if (unreachable.isEmpty) ...[
                Caption(context.i18n(
                  'modules:projects.detail.outdatedCount',
                  variables: {'count': outdated},
                )),
                const SizedBox(width: 10),
              ],
              if (loading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              for (final section in DependencySection.values)
                ..._section(context, section, latest),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context,
    DependencySection section,
    Map<String, AsyncValue<Version>> latest,
  ) {
    final packages = details.packages.where((p) => p.section == section);
    if (packages.isEmpty) return const [];

    final title = section == DependencySection.dependencies
        ? 'modules:projects.detail.dependencies'
        : 'modules:projects.detail.devDependencies';

    return [
      Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 5),
        child: Subheading(context.i18n(title)),
      ),
      _HeaderRow(),
      const Divider(height: 1),
      for (final package in packages)
        PackageRow(
          projectPath: details.path,
          package: package,
          latest: latest[package.name],
        ),
    ];
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget cell(String key, int flex) => Expanded(
          flex: flex,
          child: Caption(context.i18n(key)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          cell('modules:projects.detail.package', 4),
          cell('modules:projects.detail.constraint', 3),
          cell('modules:projects.detail.resolved', 2),
          cell('modules:projects.detail.latest', 2),
          const SizedBox(width: _actionWidth),
        ],
      ),
    );
  }
}

/// One dependency
class PackageRow extends ConsumerWidget {
  /// Constructor
  const PackageRow({
    required this.projectPath,
    required this.package,
    required this.latest,
    super.key,
  });

  /// Project the dependency belongs to
  final String projectPath;

  /// Dependency
  final ProjectPackage package;

  /// Latest version on pub.dev, null if not on pub.dev
  final AsyncValue<Version>? latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestVersion = latest?.value;
    final status = package.statusFor(latestVersion);

    Future<void> upgrade() async {
      final version = latestVersion!;
      final constraint = ProjectPackage.constraintFor(version);
      final i18next = context.i18next;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.i18n(
            'modules:projects.detail.upgradeTitle',
            variables: {'package': package.name},
          )),
          content: Text(context.i18n(
            'modules:projects.detail.upgradeMessage',
            variables: {
              'from': package.constraint ?? 'any',
              'to': constraint,
            },
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.i18n('modules:projects.detail.cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.i18n('modules:projects.detail.upgrade')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      try {
        await ref
            .read(projectEditorProvider)
            .setConstraint(projectPath, package, constraint);
        notify(i18next.t(
          'modules:projects.detail.constraintUpdated',
          variables: {'package': package.name, 'constraint': constraint},
        ));
      } catch (e) {
        notifyError(e.toString());
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              package.name,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: Caption(package.constraint ?? _sourceLabel(package.source)),
          ),
          Expanded(
            flex: 2,
            child: Caption(package.resolved?.toString() ?? '-'),
          ),
          Expanded(flex: 2, child: _latestCell(context, status)),
          SizedBox(
            width: _actionWidth,
            height: 32,
            child: status == PackageStatus.constraintOutdated
                ? Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: upgrade,
                      child: Text(
                        context.i18n('modules:projects.detail.upgrade'),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _latestCell(BuildContext context, PackageStatus status) {
    final latest = this.latest;
    if (latest == null) return const Caption('-');

    final error = latest.error;
    if (error != null) {
      final notFound = _isNotFound(error);
      return Tooltip(
        message: context.i18n(notFound
            ? 'modules:projects.detail.notOnPubDev'
            : 'modules:projects.detail.pubDevUnavailable'),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            notFound ? Icons.help_outline : Icons.cloud_off,
            size: 16,
            color: Theme.of(context).disabledColor,
          ),
        ),
      );
    }

    final version = latest.value;
    if (version == null) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final (color, icon, tooltip) = switch (status) {
      PackageStatus.upToDate => (
          Colors.greenAccent,
          Icons.check_circle_outline,
          'modules:projects.detail.upToDate',
        ),
      PackageStatus.upgradable => (
          Colors.amber,
          Icons.arrow_circle_up,
          'modules:projects.detail.updateAvailable',
        ),
      PackageStatus.constraintOutdated => (
          Colors.deepOrangeAccent,
          Icons.error_outline,
          'modules:projects.detail.constraintOutdated',
        ),
      PackageStatus.unknown => (null, null, null),
    };

    final text = Text(
      version.toString(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
    if (icon == null || tooltip == null) return text;

    return Tooltip(
      message: context.i18n(tooltip),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(child: text),
        ],
      ),
    );
  }
}

String _sourceLabel(DependencySource source) {
  switch (source) {
    case DependencySource.sdk:
      return 'sdk';
    case DependencySource.path:
      return 'path';
    case DependencySource.git:
      return 'git';
    case DependencySource.pubDev:
    case DependencySource.customHosted:
      return 'hosted';
  }
}

bool _isNotFound(Object? error) {
  return error is PubDevException && error.kind == PubDevErrorKind.notFound;
}
