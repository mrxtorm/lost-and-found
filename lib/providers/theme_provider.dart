import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Owns the user's light/dark/system appearance choice.
///
/// [AppColors] exposes the neutral colours as plain static getters (so
/// screens don't need a BuildContext to read them). Because of that, a
/// theme change can't rely on `Theme.of` dependencies alone - after
/// swapping the palette this marks every element in the tree dirty so all
/// screens, including ones further down the navigation stack, repaint.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  static const _prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool get isDark => AppColors.isDark;

  /// Loads the saved choice and applies it before the first frame, so the
  /// app never flashes the wrong theme on launch.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      _mode = ThemeMode.system;
    }
    _applyPalette();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    _refresh();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // Not critical - the choice still applies for this session.
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (_mode == ThemeMode.system) _refresh();
  }

  bool _resolveDark() {
    switch (_mode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return WidgetsBinding
                .instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  /// Returns true if the palette actually changed.
  bool _applyPalette() {
    final palette = _resolveDark() ? AppPalette.dark : AppPalette.light;
    if (identical(palette, AppColors.palette)) return false;
    AppColors.usePalette(palette);
    return true;
  }

  void _refresh() {
    final changed = _applyPalette();
    notifyListeners();
    if (changed) _rebuildAll();
  }

  void _rebuildAll() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
