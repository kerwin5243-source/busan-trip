// ════════════════════════════════════════════════════════════════
// 釜山旅遊 App - 主題定義
// 對應 HTML 設計稿的 10 個主題:
//   韓風 3: 韓紙白米 / 青瓷月白 / 丹青宮殿
//   日式 2: 藍染靛青 / 京都夜燈
//   暗色 2: 霓虹賽博 / 酒紅絨夜
//   動漫 3: 鬼滅之刃 / 航海王 / 間諜家家酒
//
// 將此檔放在 lib/theme/app_themes.dart
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary_item.dart';

/// 主題識別 key (儲存到 SharedPreferences)
enum ThemeKey {
  // 預設 (原本的金棕配色)
  defaultBeige,
  // 韓風
  koreanHanji,
  koreanCeladon,
  koreanDancheong,
  // 日式
  jpIndigo,
  jpKyotoNight,
  // 暗色
  darkCyber,
  darkBurgundy,
  // 動漫
  animeDemon,
  animeOnepiece,
  animeSpy,
}

extension ThemeKeyExt on ThemeKey {
  String get id => toString().split('.').last;
  static ThemeKey fromId(String? id) {
    if (id == null) return ThemeKey.defaultBeige;
    return ThemeKey.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ThemeKey.defaultBeige,
    );
  }
}

/// 一個完整的主題色票 + 字體 + 樣式參數
class AppThemeData {
  final ThemeKey key;
  final String name;       // 中文顯示名 (例: 韓紙白米)
  final String sub;        // 英/羅馬拼音副標
  final String family;     // korean / japanese / dark / anime / default

  // 背景與墨色
  final Color bgBody;
  final Color bgCard;       // 卡片(含 alpha)
  final Color ink;          // 主要文字
  final Color ink2;         // 次要文字
  final Color divider;

  // 主色
  final Color primary;
  final Color accent;

  // 標籤色
  final Color tagFood;
  final Color tagSight;
  final Color tagTransport;
  final Color tagHotel;
  final Color tagShop;
  final Color tagOther;

  // 字體 (傳 GoogleFonts 字體名,失敗時 fallback 系統字)
  final String fontTitleFamily;  // 標題用 (襯線 / 顯示字)
  final String fontSansFamily;   // 內文用 (無襯線)

  // 形狀參數
  final double radius;       // 大圓角 (卡片/banner)
  final double cardBlur;     // 毛玻璃模糊量
  final bool dark;           // 暗色主題?

  // 主題裝飾(可選)
  final String? motif;       // 主題符號 (例: ☠ / ★ / 卍)
  final String title;        // App 標題列大字
  final String tagline;      // 副標
  final String chip;         // highlight chip 文字 (例: 必訪 / 必殺)

  // Bottom nav 5 個 tab 的 icon + label
  final List<NavItem> nav;

  const AppThemeData({
    required this.key,
    required this.name,
    required this.sub,
    required this.family,
    required this.bgBody,
    required this.bgCard,
    required this.ink,
    required this.ink2,
    required this.divider,
    required this.primary,
    required this.accent,
    required this.tagFood,
    required this.tagSight,
    required this.tagTransport,
    required this.tagHotel,
    required this.tagShop,
    required this.tagOther,
    required this.fontTitleFamily,
    required this.fontSansFamily,
    required this.radius,
    required this.cardBlur,
    this.dark = false,
    this.motif,
    required this.title,
    required this.tagline,
    required this.chip,
    required this.nav,
  });

  /// 取得 ItemTag 對應的色票 (供 timeline_item.dart 使用)
  Color tagColor(ItemTag tag) {
    switch (tag) {
      case ItemTag.food: return tagFood;
      case ItemTag.sight: return tagSight;
      case ItemTag.transport: return tagTransport;
      case ItemTag.hotel: return tagHotel;
      case ItemTag.shop: return tagShop;
      case ItemTag.route:
      case ItemTag.other:
        return tagOther;
    }
  }

  /// 標題字 TextStyle (透過 GoogleFonts 載入)
  TextStyle titleStyle({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.getFont(
      fontTitleFamily,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w900,
      color: color ?? ink,
    );
  }

  /// 內文字 TextStyle
  TextStyle sansStyle({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.getFont(
      fontSansFamily,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color ?? ink,
    );
  }
}

class NavItem {
  final String icon;   // 顯示用文字符號 (例: 刀 / ⚓ / ★)
  final String label;  // tab 標籤 (例: 討伐錄)
  const NavItem(this.icon, this.label);
}

// ════════════════════════════════════════════════════════════════
// 10 個主題實體定義
// ════════════════════════════════════════════════════════════════

class AppThemes {
  AppThemes._();

  // ─── 預設 (原本的金棕米白) ──────────────────────────
  static const defaultBeige = AppThemeData(
    key: ThemeKey.defaultBeige,
    name: '預設 · 米白金棕',
    sub: 'Default · Beige & Gold',
    family: 'default',
    bgBody: Color(0xFFF6F0E5),
    bgCard: Color(0xC7FFFFFF),
    ink: Color(0xFF2A1F14),
    ink2: Color(0xFF7A6850),
    divider: Color(0xFFE8DCC4),
    primary: Color(0xFF6B4A2B),
    accent: Color(0xFFB8762F),
    tagFood: Color(0xFFC84B31),
    tagSight: Color(0xFF5A8F4D),
    tagTransport: Color(0xFF3E6FA8),
    tagHotel: Color(0xFF8B5A9F),
    tagShop: Color(0xFFD4A14A),
    tagOther: Color(0xFFA89884),
    fontTitleFamily: 'Noto Serif TC',
    fontSansFamily: 'Noto Sans TC',
    radius: 18,
    cardBlur: 12,
    title: '月半家族 · 釜山之旅',
    tagline: '5 天 4 夜 · 慢遊釜山',
    chip: '必訪',
    nav: [
      NavItem('◈', '行程'), NavItem('◐', '資訊'), NavItem('◉', '伴手禮'),
      NavItem('◎', '記帳'), NavItem('◇', '行前'),
    ],
  );

  // ─── 韓風 ────────────────────────────────
  static const koreanHanji = AppThemeData(
    key: ThemeKey.koreanHanji,
    name: '韓紙白米',
    sub: 'Hanji & Rice Paper',
    family: 'korean',
    bgBody: Color(0xFFF6F0E5),
    bgCard: Color(0xC7FFFFFF),
    ink: Color(0xFF2A1F14),
    ink2: Color(0xFF7A6850),
    divider: Color(0xFFE8DCC4),
    primary: Color(0xFF3D2817),
    accent: Color(0xFFC84B31),
    tagFood: Color(0xFFC84B31),
    tagSight: Color(0xFF5A8F4D),
    tagTransport: Color(0xFF3E6FA8),
    tagHotel: Color(0xFF8B5A9F),
    tagShop: Color(0xFFD4A14A),
    tagOther: Color(0xFFA89884),
    fontTitleFamily: 'Nanum Myeongjo',
    fontSansFamily: 'Noto Sans KR',
    radius: 18,
    cardBlur: 12,
    title: '월반 가족 부산 여행',
    tagline: '한지의 결, 천천히 부산',
    chip: '필수',
    nav: [
      NavItem('◈', '일정'), NavItem('◐', '정보'), NavItem('◉', '기념품'),
      NavItem('◎', '가계부'), NavItem('◇', '준비'),
    ],
  );

  static const koreanCeladon = AppThemeData(
    key: ThemeKey.koreanCeladon,
    name: '青瓷月白',
    sub: 'Celadon Moonlight',
    family: 'korean',
    bgBody: Color(0xFFE8EFE8),
    bgCard: Color(0xBFFFFFFF),
    ink: Color(0xFF1A2A23),
    ink2: Color(0xFF5C7068),
    divider: Color(0xFFCFDED2),
    primary: Color(0xFF2C4A3E),
    accent: Color(0xFF7BA591),
    tagFood: Color(0xFFD88B5A),
    tagSight: Color(0xFF5C8C7C),
    tagTransport: Color(0xFF4A7596),
    tagHotel: Color(0xFF9B7BA5),
    tagShop: Color(0xFFC9A85B),
    tagOther: Color(0xFF9CA89F),
    fontTitleFamily: 'Nanum Myeongjo',
    fontSansFamily: 'Noto Sans KR',
    radius: 22,
    cardBlur: 14,
    title: '청자빛 부산',
    tagline: '구름과 학이 머무는 자리',
    chip: '명소',
    nav: [
      NavItem('◈', '일정'), NavItem('◐', '정보'), NavItem('◉', '기념품'),
      NavItem('◎', '가계부'), NavItem('◇', '준비'),
    ],
  );

  static const koreanDancheong = AppThemeData(
    key: ThemeKey.koreanDancheong,
    name: '丹青宮殿',
    sub: 'Palace Dancheong',
    family: 'korean',
    bgBody: Color(0xFFF4ECDD),
    bgCard: Color(0xD1FFFAF0),
    ink: Color(0xFF26120D),
    ink2: Color(0xFF7A4A3C),
    divider: Color(0xFFE2C8A8),
    primary: Color(0xFF7A1F1F),
    accent: Color(0xFF1A5490),
    tagFood: Color(0xFFC73E2E),
    tagSight: Color(0xFF1F7A4D),
    tagTransport: Color(0xFF1A5490),
    tagHotel: Color(0xFF7A2E7A),
    tagShop: Color(0xFFD4A017),
    tagOther: Color(0xFF9B7A5E),
    fontTitleFamily: 'Gowun Batang',
    fontSansFamily: 'Noto Sans KR',
    radius: 14,
    cardBlur: 8,
    title: '단청 궁궐 부산',
    tagline: '오색 단청, 다섯 날의 여정',
    chip: '특별',
    nav: [
      NavItem('❖', '일정'), NavItem('◐', '정보'), NavItem('◉', '기념품'),
      NavItem('◎', '가계부'), NavItem('◇', '준비'),
    ],
  );

  // ─── 日式風 ──────────────────────────────
  static const jpIndigo = AppThemeData(
    key: ThemeKey.jpIndigo,
    name: '藍染靛青',
    sub: 'Aizome Indigo',
    family: 'japanese',
    bgBody: Color(0xFFEFF0F2),
    bgCard: Color(0xCCFCFDFF),
    ink: Color(0xFF0F1A2E),
    ink2: Color(0xFF4A5878),
    divider: Color(0xFFC8D0DC),
    primary: Color(0xFF1B3358),
    accent: Color(0xFF3D5A8A),
    tagFood: Color(0xFFC8553D),
    tagSight: Color(0xFF3D7A5A),
    tagTransport: Color(0xFF1B3358),
    tagHotel: Color(0xFF5A3D8A),
    tagShop: Color(0xFFC89A2E),
    tagOther: Color(0xFF7A8AA8),
    fontTitleFamily: 'Shippori Mincho',
    fontSansFamily: 'Noto Sans JP',
    radius: 12,
    cardBlur: 8,
    title: '藍染・釜山紀行',
    tagline: '青波重なる五日',
    chip: '名所',
    nav: [
      NavItem('◈', '旅程'), NavItem('◐', '案内'), NavItem('◉', '土産'),
      NavItem('◎', '家計'), NavItem('◇', '準備'),
    ],
  );

  static const jpKyotoNight = AppThemeData(
    key: ThemeKey.jpKyotoNight,
    name: '京都夜燈',
    sub: 'Kyoto Lantern Night',
    family: 'japanese',
    bgBody: Color(0xFF1A1410),
    bgCard: Color(0xD9281E16),
    ink: Color(0xFFF0E5D0),
    ink2: Color(0xFFA8957A),
    divider: Color(0xFF3D2F22),
    primary: Color(0xFFE8B557),
    accent: Color(0xFFD86B3D),
    tagFood: Color(0xFFE8804D),
    tagSight: Color(0xFF9DB87A),
    tagTransport: Color(0xFF7AA0D8),
    tagHotel: Color(0xFFC89AE0),
    tagShop: Color(0xFFE8B557),
    tagOther: Color(0xFFA8957A),
    fontTitleFamily: 'Shippori Mincho',
    fontSansFamily: 'Noto Sans JP',
    radius: 18,
    cardBlur: 14,
    dark: true,
    title: '夜灯・釜山宵',
    tagline: '提灯灯る、夜のまち',
    chip: '宵',
    nav: [
      NavItem('◈', '旅程'), NavItem('◐', '案内'), NavItem('◉', '土産'),
      NavItem('◎', '家計'), NavItem('◇', '準備'),
    ],
  );

  // ─── 暗色系 ─────────────────────────────
  static const darkCyber = AppThemeData(
    key: ThemeKey.darkCyber,
    name: '霓虹賽博',
    sub: 'Cyber Neon',
    family: 'dark',
    bgBody: Color(0xFF0D0E1A),
    bgCard: Color(0xC7141628),
    ink: Color(0xFFE8EAFF),
    ink2: Color(0xFF7A82B8),
    divider: Color(0xFF252A4A),
    primary: Color(0xFF00F0FF),
    accent: Color(0xFFFF2E97),
    tagFood: Color(0xFFFF2E97),
    tagSight: Color(0xFF00F0FF),
    tagTransport: Color(0xFF7C5CFC),
    tagHotel: Color(0xFFFF6B9D),
    tagShop: Color(0xFFFFD93D),
    tagOther: Color(0xFF6B7AB8),
    fontTitleFamily: 'Orbitron',
    fontSansFamily: 'JetBrains Mono',
    radius: 8,
    cardBlur: 14,
    dark: true,
    title: '> BUSAN_TRIP.exe',
    tagline: '// neon nights · 5 days online',
    chip: '[!]',
    nav: [
      NavItem('▣', 'ROUTE'), NavItem('▤', 'INFO'), NavItem('▥', 'GIFT'),
      NavItem('▦', 'COIN'), NavItem('▧', 'PREP'),
    ],
  );

  static const darkBurgundy = AppThemeData(
    key: ThemeKey.darkBurgundy,
    name: '酒紅絨夜',
    sub: 'Burgundy Velvet',
    family: 'dark',
    bgBody: Color(0xFF1A0E10),
    bgCard: Color(0xD128161A),
    ink: Color(0xFFF0E5E8),
    ink2: Color(0xFFA8858A),
    divider: Color(0xFF3D2228),
    primary: Color(0xFFE8B0B5),
    accent: Color(0xFFC04A5A),
    tagFood: Color(0xFFE07090),
    tagSight: Color(0xFF80B080),
    tagTransport: Color(0xFF7095C8),
    tagHotel: Color(0xFFB080D0),
    tagShop: Color(0xFFD4A050),
    tagOther: Color(0xFFA8858A),
    fontTitleFamily: 'Playfair Display',
    fontSansFamily: 'Noto Sans TC',
    radius: 18,
    cardBlur: 14,
    dark: true,
    title: 'Voyage à Busan',
    tagline: '絨布之夜 · 五日醇旅',
    chip: '珍藏',
    nav: [
      NavItem('◈', '行程'), NavItem('◐', '資訊'), NavItem('◉', '伴手禮'),
      NavItem('◎', '記帳'), NavItem('◇', '行前'),
    ],
  );

  // ─── 動漫風 ─────────────────────────────
  static const animeDemon = AppThemeData(
    key: ThemeKey.animeDemon,
    name: '鬼滅之刃',
    sub: 'Demon Slayer · 炭治郎',
    family: 'anime',
    bgBody: Color(0xFF0F0A14),
    bgCard: Color(0xCC1C121E),
    ink: Color(0xFFFFF5E8),
    ink2: Color(0xFFA89A9A),
    divider: Color(0xFF3D2D38),
    primary: Color(0xFF1B5E20),
    accent: Color(0xFFE53935),
    tagFood: Color(0xFFE53935),
    tagSight: Color(0xFF1B5E20),
    tagTransport: Color(0xFF1976D2),
    tagHotel: Color(0xFF6A1B9A),
    tagShop: Color(0xFFF9A825),
    tagOther: Color(0xFF8A8A8A),
    fontTitleFamily: 'Shippori Mincho',
    fontSansFamily: 'Noto Sans JP',
    radius: 6,
    cardBlur: 6,
    dark: true,
    motif: '◇',
    title: '柱・釜山討伐録',
    tagline: '全集中 · 水之呼吸 · 五日',
    chip: '必殺',
    nav: [
      NavItem('刀', '討伐錄'), NavItem('柱', '柱稽古'), NavItem('鬼', '戰利品'),
      NavItem('銭', '軍資金'), NavItem('呼', '呼吸法'),
    ],
  );

  static const animeOnepiece = AppThemeData(
    key: ThemeKey.animeOnepiece,
    name: '航海王',
    sub: 'One Piece · 草帽海賊團',
    family: 'anime',
    bgBody: Color(0xFFFFF8E8),
    bgCard: Color(0xD1FFFDF2),
    ink: Color(0xFF1A1408),
    ink2: Color(0xFF7A5A2E),
    divider: Color(0xFFF0D8A0),
    primary: Color(0xFFB71C1C),
    accent: Color(0xFFFFB300),
    tagFood: Color(0xFFD32F2F),
    tagSight: Color(0xFF1565C0),
    tagTransport: Color(0xFF0288D1),
    tagHotel: Color(0xFF6A1B9A),
    tagShop: Color(0xFFF57F17),
    tagOther: Color(0xFF8A6E3D),
    fontTitleFamily: 'Bowlby One',
    fontSansFamily: 'Noto Sans TC',
    radius: 14,
    cardBlur: 8,
    motif: '☠',
    title: '草帽海賊團・釜山航海誌',
    tagline: '目標!偉大航路 · 釜山篇',
    chip: '冒險',
    nav: [
      NavItem('⚓', '航海誌'), NavItem('☠', '懸賞令'), NavItem('⛵', '寶物庫'),
      NavItem('฿', '貝里'), NavItem('☼', '啟航'),
    ],
  );

  static const animeSpy = AppThemeData(
    key: ThemeKey.animeSpy,
    name: '間諜家家酒',
    sub: 'Spy × Family · 阿尼亞',
    family: 'anime',
    bgBody: Color(0xFFFFF0F2),
    bgCard: Color(0xD9FFFAFC),
    ink: Color(0xFF2A0E1A),
    ink2: Color(0xFF8A5A6E),
    divider: Color(0xFFF0C8D0),
    primary: Color(0xFFE91E63),
    accent: Color(0xFF43A047),
    tagFood: Color(0xFFFB8C00),
    tagSight: Color(0xFF43A047),
    tagTransport: Color(0xFF1E88E5),
    tagHotel: Color(0xFFE91E63),
    tagShop: Color(0xFFFDD835),
    tagOther: Color(0xFFA89090),
    fontTitleFamily: 'Fredoka',
    fontSansFamily: 'Noto Sans TC',
    radius: 22,
    cardBlur: 14,
    motif: '★',
    title: '阿尼亞的釜山大作戰 ♥',
    tagline: '威庫威庫!花生與冒險!',
    chip: '威庫',
    nav: [
      NavItem('♥', '任務'), NavItem('◉', '情報'), NavItem('★', '戰利'),
      NavItem('¢', '家計'), NavItem('☘', '偽裝'),
    ],
  );

  // ─── 全部主題清單 (供設定頁渲染) ────────────────
  static const List<AppThemeData> all = [
    defaultBeige,
    // 韓風
    koreanHanji, koreanCeladon, koreanDancheong,
    // 日式
    jpIndigo, jpKyotoNight,
    // 暗色
    darkCyber, darkBurgundy,
    // 動漫
    animeDemon, animeOnepiece, animeSpy,
  ];

  /// 依 key 取得主題,找不到回傳預設
  static AppThemeData byKey(ThemeKey key) {
    return all.firstWhere(
      (t) => t.key == key,
      orElse: () => defaultBeige,
    );
  }

  /// 依 family 分組 (供設定頁分區段)
  static Map<String, List<AppThemeData>> grouped() {
    final m = <String, List<AppThemeData>>{};
    for (final t in all) {
      m.putIfAbsent(t.family, () => []).add(t);
    }
    return m;
  }
}

/// 中文分組標題
const Map<String, String> kFamilyLabels = {
  'default': '預設',
  'korean': '韓風',
  'japanese': '日式',
  'dark': '暗色系',
  'anime': '動漫',
};
