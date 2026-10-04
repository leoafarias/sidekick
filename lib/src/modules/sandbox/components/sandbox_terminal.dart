import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fvm/fvm.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../components/mdi_icons.dart';

import '../../../modules/common/dto/release.dto.dart';
import '../../../modules/common/utils/notify.dart';
import '../sandbox.provider.dart';

/// Sandbox terminal
class SandboxTerminal extends HookConsumerWidget {
  /// Constructor
  const SandboxTerminal({
    required this.project,
    required this.release,
    super.key,
  });

  /// Project
  final Project project;

  /// Release
  final ReleaseDto release;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminalState = ref.watch(sandboxProvider);
    final terminal = ref.watch(sandboxProvider.notifier);

    final textController = useTextEditingController();
    final scrollController = useScrollController();

    final currentCmdIdx = useState(0);

    final focus = useFocusNode();
    final keyListenerFocus = useFocusNode();

    final processing = terminalState.processing;

    void onSubmit(
      String value,
    ) {
      try {
        /// Don't do anything if its empty
        if (value.isEmpty) return;
        // Reset command index
        currentCmdIdx.value = 0;
        // Add to the beginning of list
        textController.clear();
        terminal.sendIsolate(
          value,
          release,
          project,
        );
      } on Exception catch (e) {
        notifyError(e.toString());
      }
    }

    useEffect(() {
      /// Cannot modify state before render
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await terminal.reboot(release, project);
      });
      return;
    }, [release]);

    // ignore: missing_return
    useEffect(() {
      // Gain back focus
      if (!terminalState.processing) {
        focus.requestFocus();
      }
      return;
    }, [processing]);

    useEffect(() {
      /// Scroll to bottom
      if (scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
          );
        });
      }
      return;
    }, [terminalState.lines]);

    void moveCmdIndex(int step) {
      final cmds = terminalState.cmdHistory;
      final currentIdx = currentCmdIdx.value;
      final nextIdx = currentIdx + step;
      // Do not go through commands if its not empty
      // if its not next command and idx is 0
      // Check if it has command history

      if (textController.text.isNotEmpty &&
          textController.text != cmds[currentIdx]) {
        return;
      }

      // Get command from history
      final cmd = cmds[nextIdx];

      textController.text = cmd;

      // Set next index
      currentCmdIdx.value = nextIdx;

      // Trigger cursor move post frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        textController.selection = TextSelection.collapsed(
          offset: textController.text.length,
        );
      });
    }

    void handlekeyDown(KeyEvent key) {
      if (key.runtimeType.toString() == 'RawKeyDownEvent') {
        if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (terminalState.cmdHistory.length > currentCmdIdx.value) {
            moveCmdIndex(1);
          }
        }
        if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (currentCmdIdx.value > 0) {
            moveCmdIndex(-1);
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            primary: false,
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectableText.rich(
                TextSpan(
                  children: terminalState.lines
                      .map(
                        (e) => TextSpan(
                          text: '${e.text}\n',
                          style: e.style,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: KeyboardListener(
                  focusNode: keyListenerFocus,
                  onKeyEvent: handlekeyDown,
                  child: TextField(
                    focusNode: focus,
                    enabled: !terminalState.processing,
                    controller: textController,
                    onSubmitted: onSubmit,
                    decoration: InputDecoration(
                      icon: Icon(MdiIcons.chevronRight),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              terminalState.processing
                  ? SpinKitFadingFour(
                      color: Theme.of(context).colorScheme.secondary,
                      size: 15,
                    )
                  : Container()
            ],
          ),
        ),
      ],
    );
  }
}
