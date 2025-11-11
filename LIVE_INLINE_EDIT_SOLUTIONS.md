# Live Inline Markdown Editing Widget - Solution Approaches

## Overview
This document explores multiple architectural approaches for implementing a live inline markdown editing widget that replaces `markdown_auto_preview`, `markdown_field`, and `splitted_markdown_form_field`. The key feature is that the line/paragraph with the text cursor shows raw markdown, while all other content is rendered as formatted markdown.

## Core Requirements
- **Live inline editing**: Current line/paragraph shows raw markdown; all others show rendered output
- **Full markdown support**: Headers, emphasis, lists, blockquotes, code blocks, links, images, tables, horizontal rules, etc.
- **Smooth transitions**: No flickering when cursor moves between lines
- **Performance**: Efficient for documents with many lines
- **Text editing semantics**: Proper cursor positioning, selection, IME support

## Key Challenges
1. **Cursor position tracking**: Knowing which line/paragraph contains the cursor
2. **Synchronized rendering**: Keeping raw and rendered content in sync
3. **Multi-line constructs**: Handling code blocks, lists, tables that span multiple lines
4. **Performance**: Re-rendering only what's necessary
5. **Text measurement**: Calculating correct cursor positions in mixed raw/rendered content
6. **Selection behavior**: Handling text selection across raw and rendered boundaries

---

## Solution 1: Custom RenderObject with Mixed Paragraph Rendering

### Approach
Build a custom `RenderObject` that acts like a text field but internally manages multiple text/widget segments. Each segment is either a raw text span or a rendered markdown widget. The render object handles cursor positioning, text input, and switching between raw and rendered modes based on cursor location.

### Architecture
```
CustomRenderObject
├── TextEditingController (single source of truth)
├── Cursor position tracker
├── Line/paragraph parser
├── Segment manager
│   ├── Raw text segments (for current line)
│   └── Rendered markdown widgets (for other lines)
└── Custom text painter for cursor and selection
```

### Implementation Details
1. **Text storage**: Use a single `TextEditingController` for all content
2. **Parsing**: Split text into lines/paragraphs, identify which contains cursor
3. **Rendering**: 
   - Current line: Render as editable text with raw markdown visible
   - Other lines: Convert to markdown widgets and embed in render tree
4. **Input handling**: Capture all keyboard input, update controller, re-parse and re-render
5. **Cursor positioning**: Calculate cursor position considering rendered heights

### Pros
- ✅ Complete control over rendering and layout
- ✅ Can optimize performance with custom paint
- ✅ Seamless integration of raw and rendered content
- ✅ Full control over cursor and selection behavior

### Cons
- ❌ Complex to implement - requires deep Flutter rendering knowledge
- ❌ Must reimplement text editing features (selection, IME, accessibility)
- ❌ High maintenance burden
- ❌ Risk of bugs in text input handling
- ❌ Challenging to handle platform-specific text behaviors

### Complexity: ⭐⭐⭐⭐⭐ (Very High)

---

## Solution 2: Stack-Based Overlay with TextField + Markdown Widgets

### Approach
Use a `Stack` to overlay a transparent `TextField` on top of positioned markdown widgets. The TextField handles all input and cursor positioning. Parse the text to determine which lines are "raw" (near cursor) vs "rendered" (far from cursor). Position rendered markdown widgets precisely behind the TextField, with transparent gaps where raw text should show through.

### Architecture
```
Stack
├── Markdown Widget Layer (bottom)
│   └── Positioned widgets for each rendered paragraph
└── TextField (top, partially transparent)
    ├── Full text content
    └── Custom TextStyle with selective transparency
```

### Implementation Details
1. **TextField**: Contains all text, handles input, cursor, and selection
2. **Text styling**: Use transparent color for text that should show rendered markdown below
3. **Positioning**: Calculate exact positions for markdown widgets to align with text
4. **Synchronization**: On text change or cursor move, recompute which lines to render
5. **Measurement**: Use `TextPainter` to measure line heights and positions

### Pros
- ✅ Leverages native TextField for input handling
- ✅ Good text editing experience (IME, selection, etc.)
- ✅ Markdown rendering uses standard flutter_markdown widgets
- ✅ Moderate complexity

### Cons
- ❌ Complex positioning calculations required
- ❌ Potential alignment issues between TextField and markdown widgets
- ❌ Transparency tricks may not work well on all backgrounds
- ❌ Performance concerns with many positioned widgets
- ❌ Selection highlighting may look wrong over rendered content
- ❌ Scrolling synchronization can be tricky

### Complexity: ⭐⭐⭐⭐ (High)

---

## Solution 3: Line-by-Line Widget List with Dynamic Switching

### Approach
Represent the document as a `ListView` where each line/paragraph is a separate widget. Each widget can be in one of two states: "edit mode" (shows raw markdown in a TextField) or "view mode" (shows rendered markdown). Only the widget containing the cursor is in edit mode; all others are in view mode. Cursor movement triggers state changes.

### Architecture
```
ListView
├── EditableLine 1 (StatefulWidget)
│   ├── State: EditMode or ViewMode
│   ├── TextField (edit mode)
│   └── MarkdownBody (view mode)
├── EditableLine 2
├── EditableLine 3
└── ...
```

### Implementation Details
1. **Text splitting**: Split document into lines/paragraphs
2. **Widget per line**: Each line is an `EditableLine` widget with its own state
3. **Focus management**: Track which line has focus, switch it to edit mode
4. **Text synchronization**: When editing, update a master text model
5. **Cursor navigation**: Handle arrow keys to move between lines, transfer focus

### Pros
- ✅ Clear separation of concerns (each line manages itself)
- ✅ Easy to understand and maintain
- ✅ Good performance (only focused line is editable)
- ✅ Natural scrolling behavior

### Cons
- ❌ Complex focus management between many TextFields
- ❌ Cursor navigation between lines is not native (must be implemented)
- ❌ Multi-line constructs (code blocks, lists) are difficult to handle
- ❌ Selection across lines doesn't work naturally
- ❌ Each line switch causes widget rebuild (potential flicker)
- ❌ Copy/paste of multiple lines is problematic

### Complexity: ⭐⭐⭐ (Moderate-High)

---

## Solution 4: Rich Text with Custom TextSpan and InlineSpan

### Approach
Use a single `EditableText` widget with a custom `TextSpan` tree. Implement custom `InlineSpan` subclasses that can render markdown widgets inline. Parse the text to determine which parts should be raw vs rendered, and build the span tree accordingly. The challenge is that standard `TextSpan` doesn't support widget embedding well.

### Architecture
```
EditableText
└── TextSpan (root)
    ├── TextSpan (raw text for current line)
    ├── WidgetSpan (rendered markdown for line 2)
    ├── WidgetSpan (rendered markdown for line 3)
    └── ...
```

### Implementation Details
1. **EditableText**: Single editable text widget
2. **TextSpan building**: Parse text, build span tree with mix of TextSpan and WidgetSpan
3. **Cursor tracking**: Listen to cursor position, rebuild spans when cursor moves
4. **Widget embedding**: Use `WidgetSpan` for rendered markdown (Flutter has limitations here)
5. **Synchronization**: Rebuild span tree on every text change

### Pros
- ✅ Uses native EditableText for input
- ✅ Single text controller (simple state management)
- ✅ Native cursor and selection behavior

### Cons
- ❌ `WidgetSpan` has significant limitations (can't be edited, sizing issues)
- ❌ Complex span tree building logic
- ❌ Performance issues with frequent rebuilds
- ❌ WidgetSpan doesn't support all markdown features (tables, code blocks)
- ❌ Cursor positioning in WidgetSpan is problematic
- ❌ May not be technically feasible for all markdown elements

### Complexity: ⭐⭐⭐⭐ (High)
### Feasibility: ⚠️ Limited by Flutter's WidgetSpan capabilities

---

## Solution 5: Hybrid Column with Segmented Text Fields

### Approach
Split the document into segments (paragraphs). Use a `Column` to display segments sequentially. The segment containing the cursor is a `TextField` showing raw markdown. All other segments are read-only markdown widgets. When the user navigates out of a segment (e.g., presses down arrow at end), focus moves to the next segment.

### Architecture
```
Column
├── DocumentSegment 1
│   ├── TextField (if focused) OR
│   └── MarkdownBody (if not focused)
├── DocumentSegment 2
├── DocumentSegment 3
└── ...
```

### Implementation Details
1. **Segmentation**: Split text by paragraphs (double newline) or logical blocks
2. **Focus tracking**: Track which segment has focus
3. **Conditional rendering**: Focused segment = TextField, others = MarkdownBody
4. **Navigation**: Intercept arrow keys to move focus between segments
5. **Text sync**: Update master text from individual segment controllers

### Pros
- ✅ Cleaner than line-by-line (fewer widgets)
- ✅ Better handles multi-line constructs (whole paragraph is one segment)
- ✅ Moderate complexity
- ✅ Good performance (only one TextField at a time)
- ✅ Easy to understand

### Cons
- ❌ Cursor navigation between segments must be custom
- ❌ Selection across segments doesn't work naturally
- ❌ Focus management is complex with multiple TextFields
- ❌ Segmentation logic for complex markdown is non-trivial
- ❌ Potential flicker when switching segments
- ❌ Copy/paste across segments needs special handling

### Complexity: ⭐⭐⭐ (Moderate)

---

## Solution 6: Single TextField with Custom InputFormatter and TextPainter Overlay

### Approach
Use a single `TextField` for all editing. The TextField always shows raw markdown. Overlay a custom-painted layer on top that paints rendered markdown over the areas where the cursor is NOT present. When the cursor enters a line, clear the overlay for that line. Use `TextPainter` to render markdown in overlay.

### Architecture
```
Stack
├── TextField (full raw markdown text)
└── CustomPaint
    └── Paints rendered markdown on top of TextField
        (except for current line)
```

### Implementation Details
1. **TextField**: Contains full text, all raw markdown, fully editable
2. **Cursor tracking**: Listen to cursor position changes
3. **Overlay painting**: Use `CustomPaint` to draw rendered markdown
4. **Line masking**: Don't paint overlay on current line (let TextField show through)
5. **Hit testing**: Ensure TextField receives all input events

### Pros
- ✅ Single TextField = simple text editing
- ✅ Native cursor, selection, IME support
- ✅ Relatively simple architecture
- ✅ Good performance (just painting)

### Cons
- ❌ Custom painting of markdown is very complex
- ❌ Must reimplement markdown rendering (can't use flutter_markdown easily)
- ❌ Aligning painted content with TextField text is difficult
- ❌ Font rendering, styling, layout all custom
- ❌ No rich markdown features (tables, images) in overlay
- ❌ Overlay may not look exactly like flutter_markdown output

### Complexity: ⭐⭐⭐⭐ (High)
### Feasibility: ⚠️ Limited markdown feature support

---

## Solution 7: ReorderableListView with Block-Level Editing

### Approach
Similar to Solution 5, but use markdown "blocks" (headers, paragraphs, lists, code blocks) as the unit of segmentation. Each block is a widget that can be in edit or view mode. This aligns better with markdown semantics than line-based approaches.

### Architecture
```
ListView/Column
├── MarkdownBlock (Header)
│   └── TextField or Text widget
├── MarkdownBlock (Paragraph)
├── MarkdownBlock (Code Block)
├── MarkdownBlock (List)
└── ...
```

### Implementation Details
1. **Markdown parsing**: Use existing markdown parser to identify blocks
2. **Block widgets**: Create custom widget for each block type
3. **Edit mode**: Double-click or focus to enter edit mode for a block
4. **View mode**: Render using flutter_markdown or custom widgets
5. **Navigation**: Arrow keys move between blocks

### Pros
- ✅ Semantically correct (aligns with markdown structure)
- ✅ Each block type can have custom edit UI
- ✅ Good for complex markdown documents
- ✅ Leverages existing markdown parsers
- ✅ Natural for block-level operations (reorder, delete)

### Cons
- ❌ Complex block type handling (many special cases)
- ❌ Inline markdown (bold, italic) within blocks still needs handling
- ❌ Cursor navigation between blocks is not native
- ❌ Block parsing can be expensive
- ❌ Selection across blocks is difficult
- ❌ Initial implementation is time-consuming

### Complexity: ⭐⭐⭐⭐ (High)

---

## Solution 8: Virtual Scrolling with Viewport-Based Rendering

### Approach
Implement a virtual scrolling text editor where only visible lines are rendered. Compute which line contains the cursor and render it as raw text. Render visible lines without cursor as markdown widgets. This is similar to Solution 3 but with virtualization for performance.

### Architecture
```
CustomScrollView
├── Sliver (renders only visible lines)
│   ├── Line 10 (raw TextField)
│   ├── Line 11 (MarkdownBody)
│   ├── Line 12 (MarkdownBody)
│   └── ...
└── Sliver (invisible lines are not rendered)
```

### Implementation Details
1. **Virtual scrolling**: Use `ListView.builder` or `CustomScrollView`
2. **Line rendering**: Compute visible range, render only those lines
3. **Focus handling**: Track focused line, render as TextField
4. **Performance**: Only render what's visible + some buffer

### Pros
- ✅ Excellent performance for large documents
- ✅ Scalable to very long documents
- ✅ Only renders what's needed

### Cons
- ❌ Still has focus management issues like Solution 3
- ❌ Virtual scrolling adds complexity
- ❌ Cursor navigation between lines needs custom logic
- ❌ Selection across lines is problematic
- ❌ Overkill for small/medium documents

### Complexity: ⭐⭐⭐⭐ (High)

---

## Solution 9: TextEditingController with Custom TextSpan Builder and Paragraph Detection

### Approach
Use a standard `TextField` with a custom `buildTextSpan` callback. In the callback, detect which paragraph contains the cursor and return appropriate `TextSpan` objects: plain text for the current paragraph, and styled text that mimics rendered markdown for other paragraphs. This doesn't embed widgets but uses rich text styling to approximate markdown rendering.

### Architecture
```
TextField
├── TextEditingController
└── buildTextSpan callback
    └── Returns TextSpan tree with styling
        ├── Plain TextSpan (current paragraph)
        └── Styled TextSpans (other paragraphs - bold, italic, different sizes for headers, etc.)
```

### Implementation Details
1. **TextField with buildTextSpan**: Override the span building
2. **Cursor detection**: Find which paragraph contains cursor
3. **Styling**: Apply text styles (bold, italic, size) to non-current paragraphs to simulate markdown
4. **Limitations**: Can only use text styling, no real widget embedding

### Pros
- ✅ Simple architecture (single TextField)
- ✅ Native text editing experience
- ✅ Good performance
- ✅ Easy to implement basic styling
- ✅ Works well for simple markdown (bold, italic, headers)

### Cons
- ❌ Limited to text styling only (no images, tables, complex layouts)
- ❌ Cannot truly render markdown (just approximates with styles)
- ❌ Code blocks, lists, blockquotes are hard to style convincingly
- ❌ Not a true "rendered" experience

### Complexity: ⭐⭐ (Low-Moderate)
### Feasibility: ⚠️ Limited to text styling approximations

---

## Solution 10: Slate.js-Inspired Approach with Immutable Document Model

### Approach
Inspired by web editors like Slate.js, maintain an immutable document model representing the markdown structure. The UI is a list of "leaf" components that render based on the model and cursor position. Editing operations create a new document model. The view is a pure function of the model and cursor state.

### Architecture
```
Immutable Document Model
├── Block nodes (paragraphs, headers, lists, etc.)
└── Cursor state

React-like View
├── Renders blocks based on model + cursor
├── EditableBlock (if cursor is in this block)
└── RenderedBlock (if cursor is NOT in this block)
```

### Implementation Details
1. **Document model**: Immutable data structure representing markdown
2. **Cursor state**: Separate state for cursor position
3. **View function**: Pure function that renders model + cursor to widgets
4. **Edit operations**: Transform model immutably, trigger re-render
5. **State management**: Use Provider, Riverpod, or similar for state

### Pros
- ✅ Clean separation of data and view
- ✅ Testable (model transformations are pure functions)
- ✅ Predictable behavior (immutability)
- ✅ Good architecture for complex editors
- ✅ Easy to implement undo/redo

### Cons
- ❌ Complex to implement from scratch
- ❌ Performance overhead of immutability for large documents
- ❌ Still need to solve the edit mode vs view mode rendering problem
- ❌ Requires learning/implementing new architectural patterns
- ❌ May be over-engineered for this use case

### Complexity: ⭐⭐⭐⭐ (High)

---

## Comparison Matrix

| Solution | Complexity | Feasibility | Features | Performance | Maintenance |
|----------|------------|-------------|----------|-------------|-------------|
| 1. Custom RenderObject | ⭐⭐⭐⭐⭐ | Medium | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ |
| 2. Stack Overlay | ⭐⭐⭐⭐ | Medium | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| 3. Widget List | ⭐⭐⭐ | High | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 4. Rich Text Spans | ⭐⭐⭐⭐ | Low | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| 5. Segmented Fields | ⭐⭐⭐ | High | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 6. Overlay Painting | ⭐⭐⭐⭐ | Medium | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| 7. Block-Level Edit | ⭐⭐⭐⭐ | High | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| 8. Virtual Scrolling | ⭐⭐⭐⭐ | Medium | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| 9. TextSpan Builder | ⭐⭐ | High | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 10. Immutable Model | ⭐⭐⭐⭐ | High | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## Recommended Solutions

### For MVP / Quick Implementation
**Solution 9: TextSpan Builder** - Simplest to implement, provides a reasonable approximation of the desired behavior using text styling. Good starting point.

### For Production / Full Feature Set
**Solution 5: Segmented Fields** or **Solution 7: Block-Level Edit** - Better balance of complexity, features, and maintainability. Can support all markdown features with moderate implementation effort.

### For Advanced/Custom Experience
**Solution 1: Custom RenderObject** - If you need complete control and are willing to invest significant development time. Best performance and flexibility, but highest complexity.

---

## Next Steps

1. **Review this document** and provide feedback
2. **Select an approach** or suggest modifications/combinations
3. **Define API and widget name** for the new widget
4. **Create implementation plan** with milestones
5. **Begin implementation** of selected solution

---

## Questions for Consideration

1. **Granularity**: Should the unit be line, paragraph, or markdown block?
2. **Transition**: Should there be animation when switching between raw and rendered?
3. **Multi-line**: How to handle constructs that span multiple lines (lists, code blocks)?
4. **Navigation**: Should cursor navigation work exactly like a normal text field?
5. **Selection**: Should users be able to select across raw and rendered boundaries?
6. **Performance**: What is the maximum expected document size?
7. **Mobile**: Are there special considerations for mobile (touch, keyboard)?
8. **Accessibility**: What accessibility features are required?

