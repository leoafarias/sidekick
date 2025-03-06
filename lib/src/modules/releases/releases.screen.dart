import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/atoms/sliver_animated_switcher.dart';
import '../../components/atoms/typography.dart';
import '../../components/molecules/version_install_button.dart';
import '../../components/organisms/screen.dart';
import '../../modules/common/utils/helpers.dart';
import 'components/channel_showcase_item.dart';
import 'components/release_list_item.dart';
import 'releases.provider.dart';

class ReleasesScreen extends ConsumerWidget {
  const ReleasesScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider.notifier);
    final versions = ref.watch(filterableReleasesProvider);
    final releases = ref.watch(releasesStateProvider);

    return SkScreen(
      extendBody: false,
      title: context.i18n('modules:releases.releases'),
      child: CustomScrollView(
        primary: false,
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              // TODO: Check if need to add the height
              height: 80,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withAlpha((255 * 0.1).round()),
                    border: Border.all(
                      color: Colors.deepOrange,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Subheading(
                        context.i18n('components:molecules.master'),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Caption(
                          context.i18n(
                              'modules:releases.theCurrentTipoftreeAbsoluteLatestCuttingEdgeBuildUsuallyFunctional'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      releases.master != null
                          ? VersionInstallButton(releases.master!)
                          : Container(),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 140.0,
            elevation: 1,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            pinned: true,
            excludeHeaderSemantics: true,
            actions: [Container()],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: releases.channels.map((channel) {
                    return Expanded(
                      child: ChannelShowcaseItem(channel),
                    );
                  }).toList(),
                ),
              ),
            ),
            title: SliverAnimatedSwitcher(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: releases.channels.map((channel) {
                  return Expanded(child: ReleaseListItem(channel));
                }).toList(),
              ),
            ),
          ),
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 0),
            ),
            automaticallyImplyLeading: false,
            // actions: [Container()],
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Heading(
                      context.i18n('modules:releases.versions'),
                    ),
                    const SizedBox(width: 10),
                    Chip(label: Text(versions.length.toString())),
                  ],
                ),
                DropdownButton<String>(
                  value: filter.state.name,
                  icon: const Icon(Icons.filter_list),
                  underline: Container(),
                  items: Filter.values.map((Filter filter) {
                    final text = filter != Filter.all
                        ? filter.name.capitalize()
                        : context.i18n('modules:releases.all');

                    return DropdownMenuItem(
                      value: filter.name,
                      child: Text(text),
                    );
                  }).toList(),
                  onChanged: (value) {
                    filter.state = filterFromName(value!);
                  },
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ReleaseListItem(versions[index]);
              },
              childCount: versions.length,
            ),
          ),
        ],
      ),
    );
  }
}
