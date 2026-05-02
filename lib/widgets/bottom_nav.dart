import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

enum NavTab { itinerary, info, souvenir, money, prep }

class BottomNav extends StatelessWidget {
  final NavTab current;
  final ValueChanged<NavTab> onTap;
  /// +1 = swipe left (next tab), -1 = swipe right (prev tab)
  final ValueChanged<int>? onSwipe;

  const BottomNav({
    super.key,
    required this.current,
    required this.onTap,
    this.onSwipe,
  });

  static const _items = [
    (NavTab.itinerary, FontAwesomeIcons.mapLocationDot, '行程'),
    (NavTab.info,      FontAwesomeIcons.passport,       '資訊'),
    (NavTab.souvenir,  FontAwesomeIcons.gift,           '伴手禮'),
    (NavTab.money,     FontAwesomeIcons.coins,          '記帳'),
    (NavTab.prep,      FontAwesomeIcons.listCheck,      '行前'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (onSwipe == null) return;
        final v = details.primaryVelocity ?? 0;
        if (v.abs() > 250) onSwipe!(v < 0 ? 1 : -1);
      },
      child: Padding(
      padding: EdgeInsets.only(
        bottom: bottomPad + 6,
        left: 16,
        right: 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              // iOS 26-style liquid glass
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.52),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55), width: 1),
              boxShadow: [
                BoxShadow(
                  color: C.primary.withValues(alpha: 0.10),
                  blurRadius: 32,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _items.map((item) {
                final isActive = item.$1 == current;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(item.$1);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 14 : 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? C.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          item.$2,
                          size: 18,
                          color: isActive
                              ? C.primary
                              : C.ink2.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isActive
                                ? C.primary
                                : C.ink2.withValues(alpha: 0.55),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
