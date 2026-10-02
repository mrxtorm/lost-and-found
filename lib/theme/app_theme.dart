import 'package:flutter/material.dart';

/// Central place for the app's [ThemeData], matching the light blue
/// Material 3 theme the app previously built inline in `main.dart`.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      );
}
