import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../screens/session/session_gate.dart';
import '../screens/saas/saas_portal_screen.dart';

class LossDefenderApp extends StatelessWidget {
  final bool useSessionGate;

  const LossDefenderApp({super.key, this.useSessionGate = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionProvider>(
      create: (_) => SessionProvider(),
      child: MaterialApp(
        title: 'Loss Defender Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0061FC),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF021F4F),
            elevation: 0,
          ),
        ),
        home: useSessionGate ? const LDSessionGate() : const SaaSPortalScreen(),
      ),
    );
  }
}
