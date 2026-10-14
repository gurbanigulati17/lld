import 'package:flutter/material.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../core/settings.dart';

/// Shown for a moment while the saved session is read from secure storage.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Scaffold(
      backgroundColor: t.ground,
      body: Center(
        child: Text(
          AppConfig.appName,
          style: TextStyle(fontFamily: AppTheme.serif, fontSize: 34, fontWeight: FontWeight.w700, color: t.heading),
        ),
      ),
    );
  }
}
