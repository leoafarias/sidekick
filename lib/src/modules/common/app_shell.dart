import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:sidekick/src/components/organisms/app_bottom_bar.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';
import 'package:sidekick/src/modules/common/utils/indexed_transition_switcher.dart';
import 'package:sidekick/src/modules/common/utils/notify.dart';
import 'package:sidekick/src/modules/compatibility_checks/compat.provider.dart';
import 'package:sidekick/src/modules/compatibility_checks/compat.screen.dart';
import 'package:sidekick/src/modules/search/components/search_bar.dart' as sb;
import 'package:sidekick/src/modules/selected_detail/components/info_drawer.dart';

import '../../components/molecules/top_app_bar.dart';
import '../../components/organisms/shortcut_manager.dart';
import '../../modules/common/utils/layout_size.dart';
import '../../theme.dart';
import '../fvm/fvm.screen.dart';
import '../navigation/navigation.provider.dart';
import '../projects/projects.screen.dart';
import '../releases/releases.screen.dart';
import '../selected_detail/selected_detail.provider.dart';
import 'constants.dart';

final _scaffoldKey = GlobalKey<ScaffoldState>();

const pages = [
  FVMScreen(),
  ProjectsScreen(),
  ReleasesScreen(),
];

/// Main widget of the app
class AppShell extends HookConsumerWidget {
  /// Constructor
  const AppShell({
    super.key,
  });

  NavigationRailDestination renderNavButton(
    BuildContext context,
    String label,
    IconData iconData,
  ) {
    return NavigationRailDestination(
      icon: Icon(iconData, size: 20),
      selectedIcon: Icon(
        iconData,
        size: 20,
        color: Theme.of(context).colorScheme.secondary,
      ),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    LayoutSize.init(context);
    final navigation = ref.watch(navigationProvider.notifier);
    final currentRoute = ref.watch(navigationProvider);
    final selectedInfo = ref.watch(selectedDetailProvider);
    final compatInfo = ref.watch(compatProvider);
    final focusNode = useFocusNode();

    // Index of item selected
    final selectedIndex = useState(0);

    // Side effect when route changes
    useEffect(() {
      // Do not set index if its search
      if (currentRoute != NavigationRoutes.searchScreen) {
        selectedIndex.value = currentRoute.index;
      }
      return;
    }, [currentRoute]);

    // Side effect when info is selected
    useEffect(() {
      if (_scaffoldKey.currentState == null) return;
      final isOpen = _scaffoldKey.currentState?.isEndDrawerOpen;
      final hasInfo = selectedInfo?.release != null;

      // Open drawer if not large layout and its not open
      if (hasInfo && isOpen != true) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scaffoldKey.currentState?.openEndDrawer();
        });
      }
      return;
    }, [selectedInfo]);

    if (!compatInfo.ready && !compatInfo.waiting) {
      notify("Sidekick is missing key components to work", error: true);
      Future.delayed(Duration.zero).then((value) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CompatCheckScreen(),
            ),
          );
        }
      });
    }

    return SkShortcutManager(
      focusNode: focusNode,
      child: Scaffold(
        appBar: const SkAppBar(),
        bottomNavigationBar: const AppBottomBar(),
        endDrawer: const SelectedDetailDrawer(),
        backgroundColor: platformBackgroundColor(context),
        key: _scaffoldKey,
        body: Row(
          children: [
            NavigationRail(
              key: Key("NavigationRail${selectedIndex.value}"),
              backgroundColor: platformBackgroundColor(context),
              selectedIndex: selectedIndex.value,
              minWidth: kNavigationWidth,
              minExtendedWidth: kNavigationWidthExtended,
              extended: !LayoutSize.isSmall,
              onDestinationSelected: (index) {
                navigation.goTo(NavigationRoutes.values[index]);
              },
              destinations: [
                renderNavButton(
                  context,
                  context.i18n('modules:common.navButtonDashboard'),
                  Icons.category,
                ),
                renderNavButton(
                  context,
                  context.i18n('modules:common.navButtonProjects'),
                  MdiIcons.folderMultiple,
                ),
                renderNavButton(
                  context,
                  context.i18n('modules:common.navButtonExplore'),
                  Icons.explore,
                ),
              ],
            ),
            if (!Platform.isWindows)
              const VerticalDivider(
                thickness: 1,
                width: 1,
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: Platform.isWindows
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(12),
                            )
                          : null,
                      border: Platform.isWindows
                          ? Border.all(
                              color: Theme.of(context).dividerColor,
                            )
                          : null,
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: ClipRRect(
                      // This is the main content.
                      borderRadius: Platform.isWindows
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(12),
                            )
                          : BorderRadius.zero,
                      child: IndexedTransitionSwitcher(
                        // Need to update IndexTransitionSwitcher on theme change
                        key: Key(Theme.of(context).brightness.toString()),
                        duration: const Duration(milliseconds: 250),
                        reverse:
                            selectedIndex.value < (navigation.previous.index),
                        transitionBuilder: (
                          child,
                          animation,
                          secondaryAnimation,
                        ) {
                          return SharedAxisTransition(
                            fillColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? lightTheme.scaffoldBackgroundColor
                                    : darkTheme.scaffoldBackgroundColor,
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.vertical,
                            child: child,
                          );
                        },
                        index: selectedIndex.value,
                        children: pages,
                      ),
                    ),
                  ),
                  const sb.SearchBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
