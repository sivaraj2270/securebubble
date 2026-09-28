import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NukezeroShieldApp());
}

class NukezeroShieldApp extends StatelessWidget {
  const NukezeroShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "NukeZero",
          themeMode: currentMode,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
            primaryColor: ZentraTheme.primaryBlue,
            colorScheme: const ColorScheme.light(
              primary: ZentraTheme.primaryBlue,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF070A12),
            primaryColor: ZentraTheme.primaryBlue,
            colorScheme: const ColorScheme.dark(
              primary: ZentraTheme.primaryBlue,
              surface: Color(0xFF0F172A),
              onSurface: Colors.white,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}