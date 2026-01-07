import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/spellforge_game.dart';
import 'ui/text_renderer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0d1117),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF161b22),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SpellforgeApp());
}

class SpellforgeApp extends StatelessWidget {
  const SpellforgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spellforge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0d1117),
        fontFamily: 'monospace',
      ),
      home: const SpellforgeScreen(),
    );
  }
}

class SpellforgeScreen extends StatefulWidget {
  const SpellforgeScreen({super.key});

  @override
  State<SpellforgeScreen> createState() => _SpellforgeScreenState();
}

class _SpellforgeScreenState extends State<SpellforgeScreen> {
  late SpellforgeGame _game;

  @override
  void initState() {
    super.initState();
    _game = SpellforgeGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      body: SafeArea(
        child: GameWidget<SpellforgeGame>(
          game: _game,
          overlayBuilderMap: {
            'text_ui': (context, game) => TextGameWidget(game: game),
          },
          initialActiveOverlays: const ['text_ui'],
          loadingBuilder: (context) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.amber),
                SizedBox(height: 16),
                Text(
                  'Loading Spellforge...',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          errorBuilder: (context, error) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
