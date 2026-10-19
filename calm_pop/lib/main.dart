import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/sfx.dart';
import 'home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  Sfx.instance.init();
  runApp(const CalmPopApp());
}

class CalmPopApp extends StatelessWidget {
  const CalmPopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calm Pop',
      debugShowCheckedModeBanner: false,
      theme: buildCalmTheme(),
      home: const HomeScreen(),
    );
  }
}
