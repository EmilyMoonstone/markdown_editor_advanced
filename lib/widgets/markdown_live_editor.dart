import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../src/constants.dart';
import '../src/emoji_input_formatter.dart';
import '../src/toolbar.dart';
import 'markdown_toolbar.dart';

/// A unified markdown editor widget that provides line-aware live preview.
///
/// This widget replaces [MarkdownAutoPreview], [MarkdownField],
/// and [SplittedMarkdownFormField] with a single widget featuring line-aware rendering:
/// - When focused: shows an editable field with all lines as raw markdown
/// - When unfocused: displays fully rendered markdown preview  
/// - Provides toolbar integration and form field capabilities
///
/// This approach provides a clean editing experience while maintaining compatibility
/// with all markdown features including headers, emphasis, lists, code blocks,
/// blockquotes, links, images, and tables.
class MarkdownLiveEditor extends StatefulWidget {
  const MarkdownLiveEditor({
    super.key,
    this.controller,
    this.scrollController,
    this.onChanged,
    this.style,
    this.onTap,
    this.cursorColor,
    this.toolbarBackground,
    this.expandableBackground,
    this.maxLines,
    this.minLines,
    this.markdownSyntax,
    this.emojiConvert = false,
    this.enableToolBar = true,
    this.showEmojiSelection = true,
    this.autoCloseAfterSelectEmoji = true,
    this.textCapitalization = TextCapitalization.sentences,
    this.readOnly = false,
    this.expands = false,
    this.decoration = const InputDecoration(isDense: true),
    this.hintText,
    this.validator,
    this.autovalidateMode,
    this.onSaved,
    this.focusNode,
  });

  /// Markdown syntax to reset the field to
  final String? markdownSyntax;

  /// Hint text to show when the field is empty
  final String? hintText;

  /// For enable toolbar options
  ///
  /// if false, toolbar widget will not display
  final bool enableToolBar;

  /// Enable Emoji options
  ///
  /// if false, Emoji selection widget will not be displayed
  final bool showEmojiSelection;

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [TextEditingController].
  final TextEditingController? controller;

  final ScrollController? scrollController;

  /// Configures how the platform keyboard will select an uppercase or lowercase keyboard.
  final TextCapitalization textCapitalization;

  /// Called when the text changes
  final ValueChanged<String>? onChanged;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// to enable auto convert emoji
  ///
  /// if true, the string will be automatically converted to emoji
  ///
  /// example: :smiley: => 😃
  final bool emojiConvert;

  /// Called for each distinct tap
  final VoidCallback? onTap;

  /// if you set it to false,
  /// the modal will not disappear after you select the emoji
  final bool autoCloseAfterSelectEmoji;

  /// Whether the text can be changed.
  final bool readOnly;

  /// The color of the cursor.
  final Color? cursorColor;

  /// The toolbar background color
  final Color? toolbarBackground;

  /// The expandable background color
  final Color? expandableBackground;

  /// Customise the decoration of this text field
  final InputDecoration decoration;

  /// The maximum number of lines to show at one time
  final int? maxLines;

  /// The minimum number of lines to occupy
  final int? minLines;

  /// Whether this widget's height will be sized to fill its parent.
  final bool expands;

  /// Validator for FormField integration
  final String? Function(String?)? validator;

  /// Autovalidate mode for FormField integration
  final AutovalidateMode? autovalidateMode;

  /// OnSaved callback for FormField integration
  final void Function(String?)? onSaved;

  /// Focus node for the text field
  final FocusNode? focusNode;

  @override
  State<MarkdownLiveEditor> createState() => _MarkdownLiveEditorState();
}

class _MarkdownLiveEditorState extends State<MarkdownLiveEditor> {
  late TextEditingController _internalController;
  late FocusNode _internalFocusNode;
  late Toolbar _toolbar;

  int _currentCursorLine = 0;
  List<String> _lines = [];
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _internalFocusNode = widget.focusNode ?? FocusNode();

    _toolbar = Toolbar(
      controller: _internalController,
      bringEditorToFocus: () {
        if (!_internalFocusNode.hasFocus) {
          _internalFocusNode.requestFocus();
        }
      },
    );

    _internalController.addListener(_onTextChanged);
    _internalFocusNode.addListener(_onFocusChanged);
    _updateLines();
  }

  @override
  void dispose() {
    _internalController.removeListener(_onTextChanged);
    _internalFocusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) {
      _internalController.dispose();
    }
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  void _onTextChanged() {
    _updateLines();
    _updateCursorLine();
    widget.onChanged?.call(_internalController.text);
  }

  void _updateLines() {
    final text = _internalController.text;
    if (text.isEmpty) {
      setState(() {
        _lines = [''];
      });
    } else {
      setState(() {
        _lines = text.split('\n');
      });
    }
  }

  void _updateCursorLine() {
    final text = _internalController.text;
    final cursorPosition = _internalController.selection.baseOffset;

    if (cursorPosition < 0 || text.isEmpty) {
      setState(() {
        _currentCursorLine = 0;
      });
      return;
    }

    int currentLine = 0;
    int charCount = 0;

    for (int i = 0; i < _lines.length; i++) {
      charCount += _lines[i].length;
      if (i < _lines.length - 1) {
        charCount += 1; // Account for newline character
      }

      if (cursorPosition <= charCount) {
        currentLine = i;
        break;
      }
    }

    setState(() {
      _currentCursorLine = currentLine;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
            BoldTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
            ItalicTextIntent(),
      },
      actions: {
        BoldTextIntent: CallbackAction<BoldTextIntent>(
          onInvoke: (intent) {
            _toolbar.action("**", "**");
            setState(() {});
            return null;
          },
        ),
        ItalicTextIntent: CallbackAction<ItalicTextIntent>(
          onInvoke: (intent) {
            _toolbar.action("_", "_");
            setState(() {});
            return null;
          },
        ),
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isFocused)
            _buildPreviewMode()
          else
            _buildEditMode(),
          if (widget.enableToolBar && !widget.readOnly && _isFocused)
            MarkdownToolbar(
              markdownSyntax: widget.markdownSyntax,
              controller: _internalController,
              autoCloseAfterSelectEmoji: widget.autoCloseAfterSelectEmoji,
              toolbar: _toolbar,
              onPreviewChanged: () {
                _internalFocusNode.unfocus();
              },
              unfocus: () {
                _internalFocusNode.unfocus();
              },
              showEmojiSelection: widget.showEmojiSelection,
              emojiConvert: widget.emojiConvert,
              toolbarBackground: widget.toolbarBackground,
              expandableBackground: widget.expandableBackground,
              onActionCompleted: () {
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewMode() {
    return GestureDetector(
      onTap: () {
        _internalFocusNode.requestFocus();
        widget.onTap?.call();
      },
      child: Container(
        constraints: widget.minLines != null
            ? BoxConstraints(
                minHeight: (widget.minLines! * 20.0),
              )
            : null,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _internalController.text.isEmpty
            ? Text(
                widget.hintText ?? 'Type markdown here...',
                style: widget.style?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ) ??
                    const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
              )
            : MarkdownBody(
                data: _internalController.text,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                  textScaleFactor: widget.style?.fontSize != null
                      ? widget.style!.fontSize! / 14.0
                      : 1.0,
                ),
              ),
      ),
    );
  }

  Widget _buildEditMode() {
    return TextFormField(
      controller: _internalController,
      focusNode: _internalFocusNode,
      cursorColor: widget.cursorColor,
      inputFormatters: [
        if (widget.emojiConvert) EmojiInputFormatter(),
      ],
      onChanged: (value) {
        _onTextChanged();
      },
      onTap: () {
        _updateCursorLine();
        widget.onTap?.call();
      },
      readOnly: widget.readOnly,
      scrollController: widget.scrollController,
      style: widget.style,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      decoration: widget.decoration,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onSaved: widget.onSaved,
    );
  }
}
