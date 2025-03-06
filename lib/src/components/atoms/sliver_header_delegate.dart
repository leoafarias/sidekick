import 'package:flutter/material.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

/// Sliver header delegate
class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  /// Constructor
  SliverHeaderDelegate({
    required this.title,
    this.count = 0,
    this.onPress,
    this.height = 60,
  });

  /// Title
  final String title;

  /// Count
  final int count;

  /// On press handler
  final void Function()? onPress;

  /// height
  final double height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Theme.of(context).cardColor.withAlpha((255 * 0.2).round()),
      ),
      child: ListTile(
        title: Text(
          title,
        ),
        trailing: Text(
          context.i18n('components:atoms.countFound', variables: {
            'count': count,
          }),
        ),
        onTap: onPress,
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}
