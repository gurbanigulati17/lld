import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time configuration.
///
/// Pass the API with `--dart-define=KARDO_API_URL=https://api.example.com`.
/// Without it the app runs fully on the device: the tax engine is local and
/// sign-in uses demo codes, because there is no server to send an SMS.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  static const appName = 'Kardo';
  static const tagline = 'Taxes, kar do.';

  /// Empty means "no server".
  final String apiBaseUrl;

  bool get hasServer => apiBaseUrl.isNotEmpty;

  static const fromEnvironment = AppConfig(
    apiBaseUrl: String.fromEnvironment('KARDO_API_URL'),
  );
}

final configProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment);
