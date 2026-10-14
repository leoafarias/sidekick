import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

/// Refresh button
class RefreshButton extends HookWidget {
  /// Constructor
  const RefreshButton({
    required this.onPressed,
    super.key,
  });

  /// On press handler
  final Future Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final refreshing = useState(false);
    Future<void> handleOnPress() async {
      if (refreshing.value) return;
      refreshing.value = true;
      try {
        await onPressed();
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      } finally {
        // Errors must not leave the button spinning forever
        if (context.mounted) refreshing.value = false;
      }
    }

    // Renders the refreshing indicator
    Widget renderIndicator() {
      return const Padding(
        padding: EdgeInsets.only(left: 5),
        child: SizedBox(
          height: 15,
          width: 15,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      label: Text(context.i18n('components:atoms.refresh')),
      icon: refreshing.value
          ? renderIndicator()
          : Icon(MdiIcons.refresh, size: 20),
      onPressed: handleOnPress,
    );
  }
}
