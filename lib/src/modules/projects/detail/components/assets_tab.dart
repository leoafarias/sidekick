import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../../../../components/mdi_icons.dart';
import '../../../common/utils/helpers.dart';
import '../project_assets.dart';
import '../project_detail.provider.dart';
import '../project_details.dart';
import 'detail_widgets.dart';

/// Basic explorer for the project's asset folders
class AssetsTab extends HookConsumerWidget {
  /// Constructor
  const AssetsTab({required this.details, super.key});

  /// Details read from disk
  final ProjectDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roots = [
      for (final root in details.assetRoots) p.join(details.path, root),
    ];
    // null shows the list of roots when there are several
    final current = useState<String?>(roots.length == 1 ? roots.first : null);

    if (roots.isEmpty) {
      return DetailMessage(
        icon: Icons.photo_library_outlined,
        message: context.i18n('modules:projects.detail.noAssets'),
      );
    }

    final directory = current.value;
    final List<AssetEntry> entries;
    if (directory == null) {
      entries = [for (final root in roots) AssetFolder(root)];
    } else {
      final listing = ref.watch(assetFolderProvider(directory));
      if (listing.hasError) {
        return DetailMessage(
          icon: Icons.error_outline,
          message: listing.error.toString(),
        );
      }
      final value = listing.value;
      if (value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      entries = value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Breadcrumbs(
          projectPath: details.path,
          directory: directory,
          canGoToRoots: roots.length > 1,
          onSelected: (path) => current.value = path,
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? DetailMessage(
                  icon: MdiIcons.folder,
                  message: context.i18n('modules:projects.detail.emptyFolder'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return AssetTile(
                      entry,
                      onTap: () {
                        if (entry is AssetFolder) {
                          current.value = entry.path;
                        } else {
                          OpenFile.open(entry.path);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({
    required this.projectPath,
    required this.directory,
    required this.canGoToRoots,
    required this.onSelected,
  });

  final String projectPath;
  final String? directory;
  final bool canGoToRoots;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final directory = this.directory;
    final segments = directory == null
        ? <String>[]
        : p.split(p.relative(directory, from: projectPath));

    final crumbs = <Widget>[];
    if (canGoToRoots || segments.isEmpty) {
      crumbs.add(_crumb(
        context,
        context.i18n('modules:projects.detail.assets'),
        segments.isEmpty ? null : () => onSelected(null),
      ));
    }
    for (var i = 0; i < segments.length; i++) {
      final path = p.joinAll([projectPath, ...segments.take(i + 1)]);
      final isLast = i == segments.length - 1;
      // The root can only be left when there are several roots
      final canOpen = !isLast;
      if (crumbs.isNotEmpty) {
        crumbs.add(const Icon(Icons.chevron_right, size: 16));
      }
      crumbs.add(_crumb(
        context,
        segments[i],
        canOpen ? () => onSelected(path) : null,
      ));
    }

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(children: crumbs),
      ),
    );
  }

  Widget _crumb(BuildContext context, String label, VoidCallback? onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        disabledForegroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      child: Text(label),
    );
  }
}

/// Folder, image preview or file icon
class AssetTile extends StatelessWidget {
  /// Constructor
  const AssetTile(this.entry, {this.onTap, super.key});

  /// Entry
  final AssetEntry entry;

  /// Tap handler
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final Widget preview;
    var variants = const <double>[];

    switch (entry) {
      case AssetFolder():
        preview = Icon(
          MdiIcons.folder,
          size: 48,
          color: Theme.of(context).colorScheme.secondary,
        );
      case AssetFile(isImage: true):
        variants = entry.variants;
        preview = Image.file(
          File(entry.path),
          fit: BoxFit.contain,
          cacheWidth: 256,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        );
      case AssetFile():
        variants = entry.variants;
        preview = Icon(
          _fileIcon(entry.path),
          size: 40,
          color: Theme.of(context).disabledColor,
        );
    }

    return Tooltip(
      message: variants.isEmpty
          ? entry.name
          : context.i18n(
              'modules:projects.detail.variants',
              variables: {'variants': variants.map(_ratio).join(', ')},
            ),
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: Center(child: preview)),
                    if (variants.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: _VariantsBadge(variants),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantsBadge extends StatelessWidget {
  const _VariantsBadge(this.variants);

  final List<double> variants;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withAlpha(200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        variants.map(_ratio).join(' '),
        style: const TextStyle(fontSize: 9, color: Colors.black),
      ),
    );
  }
}

String _ratio(double ratio) {
  final text = ratio == ratio.roundToDouble()
      ? ratio.toStringAsFixed(0)
      : ratio.toString();
  return '${text}x';
}

IconData _fileIcon(String path) {
  switch (p.extension(path).toLowerCase()) {
    case '.svg':
      return Icons.image_outlined;
    case '.json':
    case '.yaml':
    case '.yml':
    case '.txt':
    case '.md':
    case '.arb':
      return Icons.description_outlined;
    case '.ttf':
    case '.otf':
      return Icons.font_download_outlined;
    case '.mp3':
    case '.wav':
    case '.ogg':
      return Icons.audiotrack_outlined;
    case '.mp4':
    case '.mov':
      return Icons.movie_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}
