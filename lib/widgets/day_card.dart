import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/itinerary_item.dart';
import '../theme/app_theme.dart';

class DayCard extends ConsumerWidget {
  final ItineraryDay day;
  final int dayNumber;

  const DayCard({super.key, required this.day, required this.dayNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlights = day.items
        .where((i) => i.highlight || i.tag == ItemTag.sight || i.tag == ItemTag.food)
        .take(3)
        .toList();

    return GestureDetector(
      onTap: () => context.push('/day/${day.date}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _Header(day: day, dayNumber: dayNumber),
            if (highlights.isNotEmpty) _Highlights(items: highlights),
            _Footer(itemCount: day.items.length),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ItineraryDay day;
  final int dayNumber;

  const _Header({required this.day, required this.dayNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Day badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'DAY',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$dayNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.displayDate} (${day.dayOfWeek})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.loc,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54, size: 22),
        ],
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  final List<ItineraryItem> items;

  const _Highlights({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: items.map((item) {
          final color = tagColor(item.tag);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(tagIcon(item.tag), size: 15, color: color),
                ),
                const SizedBox(width: 10),
                if (item.time.isNotEmpty) ...[
                  Text(
                    item.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C2C4E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final int itemCount;

  const _Footer({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.list_alt_outlined, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            '共 $itemCount 個行程',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            '查看詳情',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primaryLight),
        ],
      ),
    );
  }
}
