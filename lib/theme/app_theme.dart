import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary_item.dart';

// ─── Color System (matching Shikoku PWA) ─────────────────────────────────────
class C {
  static const bgBody    = Color(0xFFF6F3EE); // 米白背景
  static const bgCard    = Color(0xB8FFFFFF); // 半透明白卡片 (72%)
  static const ink       = Color(0xFF1E1E1E); // 主文字
  static const ink2      = Color(0xFF6F6A62); // 次文字
  static const divider   = Color(0xFFE9E1D6); // 分割線
  static const primary   = Color(0xFF2B2723); // 深灰棕
  static const accent    = Color(0xFFB08A5B); // 金棕強調

  // Tag 顏色
  static const tagFood      = Color(0xFFD28A3A);
  static const tagSight     = Color(0xFF2F8F5B);
  static const tagTransport = Color(0xFF3D6EA9);
  static const tagHotel     = Color(0xFF7A4FA8);
  static const tagShop      = Color(0xFFE1C820);
  static const tagOther     = Color(0xFFB9B2AA);

  // Shadows
  static const shadowSoft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 26, offset: Offset(0, 10)),
  ];
  static const shadowCard = [
    BoxShadow(color: Color(0x12000000), blurRadius: 30, offset: Offset(0, 14)),
  ];
  static const shadowNav = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 50, offset: Offset(0, 16)),
  ];
}

// ─── Tag helpers ─────────────────────────────────────────────────────────────
Color tagColor(ItemTag tag) {
  switch (tag) {
    case ItemTag.transport: return C.tagTransport;
    case ItemTag.food:      return C.tagFood;
    case ItemTag.sight:     return C.tagSight;
    case ItemTag.hotel:     return C.tagHotel;
    case ItemTag.shop:      return C.tagShop;
    default:                return C.tagOther;
  }
}

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
  // Noto Serif TC — 標題
  static TextStyle serifTitle(double size, {Color? color}) =>
      GoogleFonts.notoSerifTc(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color ?? C.ink,
        height: 1.15,
      );

  // Noto Sans TC — 正文
  static TextStyle sans(double size, {FontWeight fw = FontWeight.w400, Color? color}) =>
      GoogleFonts.notoSansTc(
        fontSize: size,
        fontWeight: fw,
        color: color ?? C.ink,
      );

  // Roboto Mono — 時間
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
      colorScheme: const ColorScheme.light(
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
