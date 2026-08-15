import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:app/screens/home_screen.dart';

void main() {
  runApp(const IconGeneratorApp());
}

class IconGeneratorApp extends StatelessWidget {
  const IconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IconGeneratorScreen(),
    );
  }
}

class IconGeneratorScreen extends StatefulWidget {
  const IconGeneratorScreen({super.key});

  @override
  State<IconGeneratorScreen> createState() => _IconGeneratorScreenState();
}

class _IconGeneratorScreenState extends State<IconGeneratorScreen> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureAndSave();
    });
  }

  Future<void> _captureAndSave() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // wait for fonts
      final boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = File('assets/icon.png');
      await file.writeAsBytes(bytes);
      print('=== ICON SAVED SUCCESSFULLY ===');
      exit(0);
    } catch (e) {
      print('=== ERROR SAVING ICON: $e ===');
      exit(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: RepaintBoundary(
          key: _globalKey,
          child: Container(
            width: 512,
            height: 512,
            color: const Color(0xFF141218), // CallMeTheme.surfaceLow
            child: const Center(
              child: AnimatedMeshNetworkIcon(size: 400),
            ),
          ),
        ),
      ),
    );
  }
}
