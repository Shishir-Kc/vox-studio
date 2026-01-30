import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_blog/main.dart';

void main() {
  testWidgets('App renders editor and preview', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TheBlogApp());

    // Verify that the app title is present (part of the default markdown text)
    expect(find.textContaining('Dark Mode Pro'), findsWidgets);
    
    // Verify we have a TextField (Editor)
    expect(find.byType(TextField), findsOneWidget);

    // Verify we have some text from the preview
    expect(find.textContaining('Design is not just'), findsWidgets);
  });
}
