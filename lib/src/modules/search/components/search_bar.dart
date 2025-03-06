import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../../components/atoms/blur_background.dart';
import '../../../hooks/floating_search_bar_controller.dart';
import '../../navigation/navigation.provider.dart';
import '../search.provider.dart';
import 'search_results_list.dart';

/// Search bar widget
class SearchBar extends HookConsumerWidget {
  /// Constructor
  const SearchBar({
    super.key,
    // required this.onFocusChanged,
    // required this.showSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryProvider = ref.watch(searchQueryProvider.notifier);
    final currentRoute = ref.watch(navigationProvider);
    final results = ref.watch(searchResultsProvider);
    final isLoading = useState(false);
    final controller = useFloatingSearchBarController();
    final showSearch = useState(false);

    useEffect(() {
      showSearch.value = currentRoute == NavigationRoutes.searchScreen;
      return;
    }, [currentRoute]);

    useEffect(() {
      if (showSearch.value) {
        controller.open();
      } else {
        controller.clear();
        controller.close();
      }
      return;
    }, [showSearch.value]);

    // ignore: avoid_positional_boolean_parameters
    void onFocusChanged(bool focus) {
      if (!focus) {
        ref.read(navigationProvider.notifier).goBack();
      }
    }

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: showSearch.value
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox(height: 0),
      secondChild: Container(
        constraints: BoxConstraints(
          maxHeight: showSearch.value ? MediaQuery.of(context).size.height : 0,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const BlurBackground(
              strength: 15,
            ),
            FloatingSearchBar(
              hint: context.i18n('modules:search.components.search'),
              controller: controller,
              progress: isLoading.value,
              shadowColor: Colors.transparent,
              transitionDuration: const Duration(milliseconds: 300),
              transitionCurve: Curves.easeInOut,
              margins: const EdgeInsets.fromLTRB(0, 10, 0, 0),

              physics: const BouncingScrollPhysics(),
              debounceDelay: const Duration(milliseconds: 200),
              width: MediaQuery.of(context).size.width / 1.5,
              backdropColor: Colors.black.withAlpha((255 * 0.5).round()),
              onFocusChanged: onFocusChanged,
              // transition: CircularFloatingSearchBarTransition(),
              scrollPadding: const EdgeInsets.all(0),
              onQueryChanged: (query) async {
                if (query.isNotEmpty) {
                  isLoading.value = true;
                }
                queryProvider.state = query;
                await Future.delayed(const Duration(milliseconds: 250));
                isLoading.value = false;
              },
              actions: [
                FloatingSearchBarAction.searchToClear(
                  showIfClosed: false,
                ),
              ],
              builder: (context, transition) {
                if (results.isEmpty && queryProvider.state.isEmpty) {
                  return const SizedBox(height: 0);
                }
                if (results.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      context.i18n(
                        'modules:search.components.noResults',
                      ),
                    ),
                  );
                }

                return SearchResultsList(results);
              },
            ),
          ],
        ),
      ),
    );
  }
}
