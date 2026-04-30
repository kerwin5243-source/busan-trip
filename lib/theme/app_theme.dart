import 'package:flutter/material.dart';

class AppColors {
  // Busan palette — deep navy sea + sunset coral
  static const primary = Color(0xFF1A3A5C); // deep navy
  static const primaryLight = Color(0xFF2E6DA4); // mid blue
  static const accent = Color(0xFFE05C3A); // sunset coral
  static const accentLight = Color(0xFFF4A580); // light coral

  // Tag colors
  static const tagTransport = Color(0xFF4A90D9);
  static const tagFood = Color(0xFFE86C3A);
  static const tagSight = Color(0xFF3CAB7A);
  static const tagHotel = Color(0xFF8B5CF6);
  static const tagShop = Color(0xFFF59E0B);
  static const tagRoute = Color(0xFF6B7280);
  static const tagOther = Color(0xFF9CA3AF);

  // Surface
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const cardShadow = Color(0x14000000);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A2E),
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C2C4E),
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: Color(0xFF444466),
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0xFF888899),
        ),
      ),
    );
  }
}

// ── Tag color helper ──────────────────────────────────────────────────────────
import 'package:busan_trip/models/itinerary_item.dart';

Color tagColor(ItemTag tag) {
  switch (tag) {
    case ItemTag.transport:
      return AppColors.tagTransport;
    case ItemTag.food:
      return AppColors.tagFood;
    case ItemTag.sight:
      return AppColors.tagSight;
    case ItemTag.hotel:
      return AppColors.tagHotel;
    case ItemTag.shop:
      return AppColors.tagShop;
    case ItemTag.route:
      return AppColors.tagRoute;
    case ItemTag.other:
      return AppColors.tagOther;
  }
}

IconData tagIcon(ItemTag tag) {
  switch (tag) {
    case ItemTag.transport:
      return Icons.directions_car_outlined;
    case ItemTag.food:
      return Icons.restaurant_outlined;
    case ItemTag.sight:
      return Icons.photo_camera_outlined;
    case ItemTag.hotel:
      return Icons.hotel_outlined;
    case ItemTag.shop:
      return Icons.shopping_bag_outlined;
    case ItemTag.route:
      return Icons.route_outlined;
    case ItemTag.other:
      return Icons.circle_outlined;
  }
}
