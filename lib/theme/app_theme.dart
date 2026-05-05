// ════════════════════════════════════════════════════════════════
// 動態主題 helper
// C.* 靜態存取會跟著 ThemeBridge 同步更新的主題換色
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary_item.dart';
import '../providers/theme_provider.dart';
import 'app_themes.dart';

// 重新匯出,讓其他檔案 import 'app_theme.dart' 即可拿到 AppThemes / AppThemeData
export 'app_themes.dart';

// ─── Dynamic Color System ─────────────────────────────────────────────────────
/// 全域可變 holder — 由 ThemeBridge 在 build 時更新 _current
/// 舊有 widget 用 `C.primary` 等靜態存取時會讀到目前選定主題。
class C {
  static AppThemeData _current = AppThemes.defaultBeige;
  static void setCurrent(AppThemeData t) => _current = t;

  static Color get bgBody  => _current.bgBody;
  static Color get bgCard  => _current.bgCard;
  static Color get ink     => _current.ink;
  static Color get ink2    => _current.ink2;
  static Color get divider => _current.divider;
  static Color get primary => _current.primary;
  static Color get accent  => _current.accent;
  static Color get accentSoft => _current.accent.withValues(alpha: 0.14);

  static Color tagColor(ItemTag tag) => _current.tagColor(tag);

  // Shadow helpers (non-const since they may vary per theme in the future)
  static List<BoxShadow> get shadowSoft => const [
    BoxShadow(color: Color(0x14000000), blurRadius: 26, offset: Offset(0, 10)),
  ];
  static List<BoxShadow> get shadowCard => const [
    BoxShadow(color: Color(0x12000000), blurRadius: 30, offset: Offset(0, 14)),
  ];
  static List<BoxShadow> get shadowNav => const [
    BoxShadow(color: Color(0x1F000000), blurRadius: 50, offset: Offset(0, 16)),
  ];
}

/// Wrapper widget — 監聽 themeProvider 並同步到 C.* 靜態欄位
class ThemeBridge extends ConsumerWidget {
  final Widget child;
  const ThemeBridge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(themeProvider);
    C.setCurrent(t);
    return child;
  }
}

// ─── Tag helpers ─────────────────────────────────────────────────────────────
/// Backward-compatible standalone tagColor (delegates to C)
Color tagColor(ItemTag tag) => C.tagColor(tag);

String tagLabel(ItemTag tag) {
  switch (tag) {
    case ItemTag.transport: return 'TRANSPORT';
    case ItemTag.food:      return 'FOOD';
    case ItemTag.sight:     return 'SIGHT';
    case ItemTag.hotel:     return 'HOTEL';
    case ItemTag.shop:      return 'SHOP';
    default:                return 'OTHER';
  }
}

// ─── TextStyles ───────────────────────────────────────────────────────────────
class TStyle {
  // Title font — uses current theme's serif/display font
  static TextStyle serifTitle(double size, {Color? color}) =>
      GoogleFonts.getFont(
        C._current.fontTitleFamily,
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color ?? C.ink,
        height: 1.15,
      );

  // Body font — uses current theme's sans font
  static TextStyle sans(double size, {FontWeight fw = FontWeight.w400, Color? color}) =>
      GoogleFonts.getFont(
        C._current.fontSansFamily,
        fontSize: size,
        fontWeight: fw,
        color: color ?? C.ink,
      );

  // Monospace — always Roboto Mono
  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.robotoMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? C.ink2,
      );
}

// ─── Theme ────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: C.bgBody,
      colorScheme: ColorScheme.light(
        primary: C.primary,
        secondary: C.accent,
        surface: C.bgBody,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: C.bgBody,
        foregroundColor: C.ink,
        elevation: 0,
        titleTextStyle: TStyle.serifTitle(18),
      ),
      cardTheme: const CardThemeData(elevation: 0, color: Colors.transparent),
    );
  }
}
