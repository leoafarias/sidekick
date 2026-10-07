import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../mdi_icons.dart';

/// Checkbox button
class SkCheckBox extends HookWidget {
  /// Constructor
  const SkCheckBox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Current value of checkbox
  final bool value;

  /// On change handler
  final Function(bool) onChanged;

  /// Button label
  final String label;
  @override
  Widget build(BuildContext context) {
    final active = useState(false);

    // Render icon logic
    Icon renderIcon() {
      return Icon(
        value ? MdiIcons.checkboxMarked : MdiIcons.checkboxBlankOutline,
        size: 15,
      );
    }

    return OutlinedButton.icon(
      label: Text(label),
      icon: renderIcon(),
      onPressed: () {
        active.value = !active.value;
        onChanged(active.value);
      },
    );
  }
}
