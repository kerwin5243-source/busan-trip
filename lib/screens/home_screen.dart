import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trip_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/day_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripProvider);

    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final config = state.config;
    final days = state.sortedDays;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _TripAppBar(config: config),
          if (config != null) _MembersBar(members: config.members),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => DayCard(
                  day: days[index],
                  dayNumber: index + 1,
                ),
                childCount: days.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripAppBar extends StatelessWidget {
  final dynamic config;

  const _TripAppBar({required this.config});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D2137),
                Color(0xFF1A3A5C),
                Color(0xFF2E6DA4),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flag + country
                  Row(
                    children: [
                      Text(
                        '🇰🇷',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BUSAN, KOREA',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config?.tripTitle ?? '釜山之旅',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (config != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 13, color: Colors.white60),
                        const SizedBox(width: 5),
                        Text(
                          '${config.startDate} ~ ${config.endDate}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.nights_stay,
                            size: 13, color: Colors.white60),
                        const SizedBox(width: 5),
                        Text(
                          '${config.nights}晚${config.days}天',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        title: Text(
          config?.tripTitle ?? '釜山之旅',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700),
        ),
        titlePadding:
            const EdgeInsets.only(left: 20, bottom: 14),
      ),
    );
  }
}

class _MembersBar extends StatelessWidget {
  final List<String> members;

  const _MembersBar({required this.members});

  @override
  Widget build(BuildContext context) {
    final avatarColors = [
      AppColors.accent,
      AppColors.primaryLight,
      const Color(0xFF3CAB7A),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFE86C3A),
    ];

    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.group_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            ...members.asMap().entries.map((e) {
              final color = avatarColors[e.key % avatarColors.length];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Tooltip(
                  message: e.value,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      e.value.isNotEmpty ? e.value[0] : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Text(
              '共 ${members.length} 人',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
