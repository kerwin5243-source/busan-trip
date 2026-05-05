// ════════════════════════════════════════════════════════════════
// 主題切換 Provider (Riverpod + SharedPreferences)
// ════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

const _kThemeKeyPref = 'app_theme_key';

/// 全域主題 provider
/// 使用方式:
///   final theme = ref.watch(themeProvider);
///   ref.read(themeProvider.notifier).setTheme(ThemeKey.animeDemon);
final themeProvider =
    StateNotifierProvider<ThemeController, AppThemeData>((ref) {
  return ThemeController();
});

class ThemeController extends StateNotifier<AppThemeData> {
  ThemeController() : super(AppThemes.defaultBeige) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kThemeKeyPref);
    final key = ThemeKeyExt.fromId(id);
    state = AppThemes.byKey(key);
  }

  Future<void> setTheme(ThemeKey key) async {
    state = AppThemes.byKey(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKeyPref, key.id);
  }
}
