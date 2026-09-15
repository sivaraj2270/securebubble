import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SecureBubble AI",
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: ZentraTheme.background,
        primaryColor: ZentraTheme.primaryBlue,
      ),
      home: const SplashScreen(),
    );
  }
}