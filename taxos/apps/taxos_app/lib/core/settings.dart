import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.reducedEffects = false,
    this.apiBaseUrl = 'http://localhost:8080',
  });

  final ThemeMode themeMode;

  /// Turns backdrop blur off (low-end devices / accessibility).
  final bool reducedEffects;
  final String apiBaseUrl;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? reducedEffects,
    String? apiBaseUrl,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        reducedEffects: reducedEffects ?? this.reducedEffects,
        apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void toggleTheme() {
    final next =
        state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: next);
  }

  void setReducedEffects(bool v) => state = state.copyWith(reducedEffects: v);
  void setApiBaseUrl(String v) => state = state.copyWith(apiBaseUrl: v);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
