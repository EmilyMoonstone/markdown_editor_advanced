# Markdown Editor Plus

This is a fork of [markdown_editor_plus by OmkarDabade](https://github.com/OmkarDabade/markdown_editor_plus)
with contributions from [zahnia88](https://github.com/zahniar88) and [fossfreaks](https://github.com/fossfreaks)

Advanced markdown editor library For flutter.


## Features
- ✅ Convert to Bold, Italic, Strikethrough
- ✅ Convert to Code, Quote, Links
- ✅ Convert to Heading (H1, H2, H3).
- ✅ Convert to unorder list and checkbox list
- ✅ Support multiline convert
- ✅ Support auto convert emoji
- ✅ **NEW**: Unified editor with live preview (MarkdownLiveEditor)

## Usage

Add dependencies to your `pubspec.yaml`

```yaml
dependencies:
    markdown_editor_advanced: ^latest
```

Run `flutter pub get` to install.

## How it works

Import library

```dart
import 'package:markdown_editor_advanced/markdown_editor_advanced.dart';
```

Initialize controller and focus node. These controllers and focus nodes are optional because if you don't create them, the editor will create them themselves

```dart
TextEditingController _controller = TextEditingController();
```

### NEW: MarkdownLiveEditor - Unified Editor with Live Preview

A new unified widget that replaces the functionality of `MarkdownAutoPreview`, `MarkdownField`, and `SplittedMarkdownFormField`:

```dart
// Unified editor with live preview
// Click to edit (shows raw markdown), click outside to preview (shows rendered markdown)
MarkdownLiveEditor(
    controller: _controller,
    emojiConvert: true,
    decoration: InputDecoration(
        hintText: 'Type markdown here...',
        border: OutlineInputBorder(),
    ),
)
```

Features:
- When focused: shows editable raw markdown text with toolbar
- When unfocused: displays fully rendered markdown preview
- Supports all markdown features (headers, lists, emphasis, code, links, tables, etc.)
- Includes toolbar, emoji conversion, and form field capabilities
- Keyboard shortcuts (Ctrl+B for bold, Ctrl+I for italic)

### Original Widgets

Show widget for editor

```dart
// editable text with toolbar by default
MarkdownAutoPreview(
    controller: _controller,
    emojiConvert: true,
)

// editable text without toolbar
MarkdownField(
    controller: _controller,
    emojiConvert: true,
    enableToolBar: false,
)
```

if you want to parse text into markdown you can use the following widget:

```dart
String data = '''
**bold**
*italic*

#hashtag
@mention
'''

MarkdownParse(
    data: data,
    onTapHastag: (String name, String match) {
        // name => hashtag
        // match => #hashtag
    },
    onTapMention: (String name, String match) {
        // name => mention
        // match => #mention
    },
)
```

In order to set the colors

```dart
MarkdownAutoPreview(
    controller: _controller,
    enableToolBar: true,
    emojiConvert: true,
    autoCloseAfterSelectEmoji: false,
    // toolbar's background color, text color will be based on theme
    toolbarBackground: Colors.blue,
    // toolbar's expandable widget colors like headings, ordering
    expandableBackground: Colors.blue[200],
)
```

___
