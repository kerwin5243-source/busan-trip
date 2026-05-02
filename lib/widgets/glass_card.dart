import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ─── iOS 26 Liquid Glass Card ─────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? tint;
  final double blur;
  final List<BoxShadow>? shadows;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.tint,
    this.blur = 20,
    this.shadows,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: tint ?? const Color(0xBEFFFFFF),
            borderRadius: BorderRadius.circular(radius),
            border: border ??
                Border.all(color: const Color(0x33FFFFFF), width: 1),
            boxShadow: shadows ?? C.shadowSoft,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── iOS 26 Segmented Control ─────────────────────────────────────────────────
class IosSegment<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;

  const IosSegment({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.divider.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items.map((item) {
          final isActive = item.$1 == value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isActive) {
                  HapticFeedback.selectionClick();
                  onChanged(item.$1);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [
                          const BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: TStyle.sans(
                    14,
                    fw: FontWeight.w800,
                    color: isActive ? C.primary : C.ink2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── iOS 26 User Tab Row ─────────────────────────────────────────────────────
class UserTabRow extends StatelessWidget {
  final List<String> users;
  final String selected;
  final ValueChanged<String> onSelect;

  const UserTabRow({
    super.key,
    required this.users,
    required this.selected,
    required this.onSelect,
  });

  static const _colors = [
    Color(0xFFE05C3A),
    Color(0xFF2E6DA4),
    Color(0xFF3CAB7A),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFE86C3A),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: users.asMap().entries.map((e) {
          final color = _colors[e.key % _colors.length];
          final isActive = e.value == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(e.value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? color.withValues(alpha: 0.55)
                      : C.divider.withValues(alpha: 0.8),
                  width: isActive ? 1.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isActive ? 0.18 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        e.value.isNotEmpty ? e.value[0] : '?',
                        style: TStyle.sans(11,
                            fw: FontWeight.w900, color: color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    e.value,
                    style: TStyle.sans(13,
                        fw: FontWeight.w800,
                        color: isActive ? C.primary : C.ink2),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;

  const SectionTitle(this.title, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF8B8175)),
            const SizedBox(width: 8),
          ],
          Text(title,
              style: TStyle.serifTitle(16,
                  color: C.primary)),
        ],
      ),
    );
  }
}

// ─── Swipeable list item — left=delete, right=edit (iOS 26 style) ────────────
class SwipeToDelete extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final String confirmLabel;

  const SwipeToDelete({
    super.key,
    required this.child,
    required this.onDelete,
    this.onEdit,
    this.confirmLabel = '刪除',
  });

  @override
  Widget build(BuildContext context) {
    final direction = onEdit != null
        ? DismissDirection.horizontal
        : DismissDirection.endToStart;

    return Dismissible(
      key: UniqueKey(),
      direction: direction,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd && onEdit != null) {
          // Right swipe = edit (no confirm needed)
          HapticFeedback.selectionClick();
          onEdit!();
          return false; // don't dismiss, just trigger edit
        }
        // Left swipe = delete with confirm
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFFFAF7F2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('確認刪除', style: TStyle.serifTitle(17)),
            content:
                Text('此操作無法復原。', style: TStyle.sans(14, color: C.ink2)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('取消',
                    style: TStyle.sans(15,
                        fw: FontWeight.w700, color: C.ink2)),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(ctx, true);
                },
                child: Text(confirmLabel,
                    style: TStyle.sans(15,
                        fw: FontWeight.w700, color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      // Right swipe background (edit — blue)
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
      ),
      // Left swipe background (delete — red)
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
      child: child,
    );
  }
}
