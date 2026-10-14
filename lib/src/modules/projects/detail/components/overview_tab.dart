import 'package:flutter/material.dart';

import '../../../../components/atoms/typography.dart';
import '../../../common/utils/helpers.dart';
import '../../project.dto.dart';
import '../project_details.dart';
import '../project_packages.dart';
import 'detail_widgets.dart';

/// Project summary: icon, description, Flutter version, platforms
class OverviewTab extends StatelessWidget {
  /// Constructor
  const OverviewTab({
    required this.project,
    required this.details,
    super.key,
  });

  /// Project
  final FlutterProject project;

  /// Details read from disk
  final ProjectDetails details;

  @override
  Widget build(BuildContext context) {
    final pinned = project.pinnedVersion?.nameWithAlias;
    final dependencies = details.packages
        .where((p) => p.section == DependencySection.dependencies)
        .length;
    final devDependencies = details.packages.length - dependencies;
    final description = details.description ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: FutureBuilder<Widget>(
                  future: project.icon,
                  initialData: project.cachedIcon,
                  builder: (context, snapshot) =>
                      snapshot.data ?? const SizedBox(),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Caption(details.rawVersion ??
                      context.i18n('modules:projects.detail.noVersion')),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Paragraph(description),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 10),
        InfoRow(
          label: context.i18n('modules:projects.detail.flutterVersion'),
          child: Text(
            pinned ?? context.i18n('modules:projects.detail.notPinned'),
          ),
        ),
        InfoRow(
          label: context.i18n('modules:projects.detail.dartSdk'),
          child: Text(details.dartSdk ?? '-'),
        ),
        InfoRow(
          label: context.i18n('modules:projects.detail.platforms'),
          child: details.platforms.isEmpty
              ? Text(context.i18n('modules:projects.detail.noPlatforms'))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final platform in details.platforms)
                      PlatformChip(platform),
                  ],
                ),
        ),
        InfoRow(
          label: context.i18n('modules:projects.detail.packages'),
          child: Text(context.i18n(
            'modules:projects.detail.dependencyCount',
            variables: {
              'dependencies': dependencies,
              'devDependencies': devDependencies,
            },
          )),
        ),
        InfoRow(
          label: context.i18n('modules:projects.detail.location'),
          child: SelectableText(project.path),
        ),
      ],
    );
  }
}

/// Chip with the icon and name of a platform
class PlatformChip extends StatelessWidget {
  /// Constructor
  const PlatformChip(this.platform, {super.key});

  /// Platform
  final ProjectPlatform platform;

  static const _labels = {
    ProjectPlatform.android: 'Android',
    ProjectPlatform.ios: 'iOS',
    ProjectPlatform.macos: 'macOS',
    ProjectPlatform.web: 'Web',
    ProjectPlatform.windows: 'Windows',
    ProjectPlatform.linux: 'Linux',
  };

  static const _icons = {
    ProjectPlatform.android: Icons.android,
    ProjectPlatform.ios: Icons.phone_iphone,
    ProjectPlatform.macos: Icons.laptop_mac,
    ProjectPlatform.web: Icons.language,
    ProjectPlatform.windows: Icons.desktop_windows_outlined,
    ProjectPlatform.linux: Icons.terminal,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[platform], size: 15),
          const SizedBox(width: 6),
          Caption(_labels[platform]!),
        ],
      ),
    );
  }
}
