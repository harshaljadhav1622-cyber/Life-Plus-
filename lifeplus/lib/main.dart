
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'app_theme.dart';
import 'auth_gate.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();

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
