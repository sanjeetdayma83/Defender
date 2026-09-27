import 'package:flutter/material.dart';

import '../screens/saas/saas_portal_screen.dart';

class LossDefenderApp extends StatelessWidget {
  const LossDefenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loss Defender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const LossDefenderHome(),
    );
  }
}

class LossDefenderHome extends StatelessWidget {
  const LossDefenderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const SaaSPortalScreen();
  }
}
