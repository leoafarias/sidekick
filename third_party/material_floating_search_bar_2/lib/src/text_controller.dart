import 'package:flutter/material.dart';

/// A [TextEditingController] that wraps a [FocusNode]
/// and maintains the selection extent when the text
/// changes.
class TextController extends TextEditingController {
  /// Creates a [TextEditingController] that wraps a [FocusNode]
  /// and maintains the selection extent when the text
  /// changes.
  TextController();

  /// The [FocusNode] of this [TextController].
  final FocusNode node = FocusNode();

  @override
  set text(String newText) {
    int offset = selection.extentOffset;

    // When the current selection is at the end of the
    // query, adjust the selection to the new end of the
    // query.
    final bool isSelectionAtTextEnd = text.length == offset;
    if (isSelectionAtTextEnd) {
      offset = newText.length;
    }

    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }

  /// Moves the Cursor to the end of the current text.
  void moveCursorToEnd() =>
      selection = TextSelection.collapsed(offset: text.length);

  /// Request focus for the [FocusNode] wrapped by this
  /// [TextController].
  void requestFocus() {
    node.requestFocus();
  }

  /// Cleares the focus of the [FocusNode] wrapped by this
  /// [TextController].
  void clearFocus() {
    node.unfocus(
      disposition: UnfocusDisposition.previouslyFocusedChild,
    );
  }

  /// Whether the [FocusNode] wrapped by this
  /// [TextController] is currenty focused.
  bool get hasFocus => node.hasFocus;

  @override
  void dispose() {
    node.dispose();
    super.dispose();
  }
}
