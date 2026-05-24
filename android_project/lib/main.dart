import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'quest_list_screen.dart';
import 'game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const FPAApp());
}

class FPAApp extends StatelessWidget {
  const FPAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FPA — Квест-Плеер',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00D4AA),
          surface: Color(0xFF141A2A),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0E0E0),
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          headlineMedium: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFD0D0D0)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
          labelLarge: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1220),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF141A2A),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

/// Стартовый экран с загрузкой
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final List<Quest> _quests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    try {
      final manifestJson =
          await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
      final questFiles = manifest.keys
          .where((k) => k.startsWith('assets/quests/') && k.endsWith('.json'))
          .toList();

      for (final file in questFiles) {
        try {
          final jsonStr = await rootBundle.loadString(file);
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final fileName = file.split('/').last;
          _quests.add(Quest.fromJson(json, fileName));
        } catch (e) {
          debugPrint('Error loading $file: $e');
        }
      }
    } catch (e) {
      _error = 'Ошибка загрузки квестов: $e';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_stories_rounded,
                  size: 64, color: Color(0xFF6C63FF)),
              const SizedBox(height: 24),
              const Text('FPA', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
              const SizedBox(height: 8),
              const Text('Квест-Плеер', style: TextStyle(fontSize: 16, color: Color(0xFF888888))),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadQuests();
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return QuestListScreen(quests: _quests);
  }
}
