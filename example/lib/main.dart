import 'package:flutter/material.dart';
import 'package:markdown_editor_advanced/markdown_editor_advanced.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Markdown Editor Advanced Demo"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New: Markdown Live Editor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unified widget that replaces the three widgets below. '
              'Click to edit (shows raw markdown), click outside to preview (shows rendered markdown).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const MarkdownLiveEditor(
              decoration: InputDecoration(
                hintText: 'Type markdown here...',
                border: OutlineInputBorder(),
              ),
              emojiConvert: true,
              minLines: 3,
              maxLines: 10,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Original Widgets:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Markdown Auto Preview',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const MarkdownAutoPreview(
              decoration: InputDecoration(
                hintText: 'Markdown Auto Preview',
              ),
              emojiConvert: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Splitted Markdown FormField',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const SplittedMarkdownFormField(
              markdownSyntax: '## Headline',
              decoration: InputDecoration(
                hintText: 'Splitted Markdown FormField',
              ),
              emojiConvert: true,
            ),
          ],
        ),
      ),
    );
  }
}
