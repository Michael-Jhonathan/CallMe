import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/home_screen.dart';

void main() {
  testWidgets('Generate Icon PNG', (WidgetTester tester) async {
    const size = 512.0;

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('icon'),
            child: Container(
              width: size,
              height: size,
              color: const Color(
                0xFF141218,
              ), // CallMeTheme.surfaceLow equivalent
              child: const Center(child: AnimatedMeshNetworkIcon(size: 350)),
            ),
          ),
        ),
      ),
    );

    // Give it a frame to render
    await tester.pump(const Duration(seconds: 1));

    final finder = find.byKey(const ValueKey('icon'));
    final boundary = tester.firstRenderObject<RenderRepaintBoundary>(finder);
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final file = File('assets/icon.png');
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      await file.writeAsBytes(byteData.buffer.asUint8List());
      print('Icon generated successfully at assets/icon.png');
    }
  });
}
