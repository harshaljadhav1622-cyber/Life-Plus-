import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'app_theme.dart';
import 'auth_gate.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('LIFEPLUS 1: main started');

  try {
    debugPrint('LIFEPLUS 2: Initializing Firebase');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('LIFEPLUS 3: Firebase initialized');
  } catch (e, stackTrace) {
    debugPrint('LIFEPLUS ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  debugPrint('LIFEPLUS 4: Calling runApp');
  runApp(const LifePlusApp());
}

class LifePlusApp extends StatelessWidget {
  const LifePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifePlus - Smart Personal Health Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
