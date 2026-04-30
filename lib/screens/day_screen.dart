import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/itinerary_item.dart';
import '../providers/trip_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/item_card.dart';
import '../widgets/edit_item_sheet.dart';

class DayScreen extends ConsumerWidget {
  final String date;

  const DayScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(dayProvider(date));
    final editMode = ref.watch(editModeProvider);

    if (day == null) {
      return Scaffold(
        appBar: AppBar(title: Text(date)),
        body: const Center(child: Text('找不到行程資料')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _DayAppBar(day: day, editMode: editMode, ref: ref),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            sliver: editMode
                ? _ReorderableList(day: day, date: date, ref: ref)
                : _ItemList(day: day, date: date),
          ),
        ],
      ),
      floatingActionButton: _EditFab(
        editMode: editMode,
        onToggle: () =>
            ref.read(tripProvider.notifier).toggleEditMode(),
        onAddItem: editMode
            ? () => _openAddItem(context, ref)
            : null,
      ),
    );
  }

  void _openAddItem(BuildContext context, WidgetRef ref) {
    final newItem = ref.read(tripProvider.notifier).newItemTemplate(date);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        // First save the empty item, then edit it
        ref.read(tripProvider.notifier).addItem(date, newItem);
        return EditItemSheet(item: newItem, date: date);
      },
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────
class _DayAppBar extends StatelessWidget {
  final ItineraryDay day;
  final bool editMode;
  final WidgetRef ref;

  const _DayAppBar(
      {required this.day, required this.editMode, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: Colors.white,
        onPressed: () {
          if (editMode) {
            ref.read(tripProvider.notifier).setEditMode(false);
          }
          Navigator.pop(context);
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.displayDate} (${day.dayOfWeek})',
            style: const TextStyle(
                color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w400),
          ),
          Text(
            day.loc,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        if (editMode) ...[
          TextButton.icon(
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('新增',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            onPressed: () => _openAddNew(context, ref),
          ),
        ],
        // Edit mode indicator
        if (editMode)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '編輯中',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  void _openAddNew(BuildContext context, WidgetRef ref) {
    final newItem = ref.read(tripProvider.notifier).newItemTemplate(date);
    ref.read(tripProvider.notifier).addItem(date, newItem);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditItemSheet(item: newItem, date: date),
    );
  }

  String get date => day.date;
}

// ── Normal item list ──────────────────────────────────────────────────────────
class _ItemList extends StatelessWidget {
  final ItineraryDay day;
  final String date;

  const _ItemList({required this.day, required this.date});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ItemCard(
          item: day.items[index],
          date: date,
          isEditMode: false,
        ),
        childCount: day.items.length,
      ),
    );
  }
}

// ── Reorderable list (edit mode) ──────────────────────────────────────────────
class _ReorderableList extends StatelessWidget {
  final ItineraryDay day;
  final String date;
  final WidgetRef ref;

  const _ReorderableList(
      {required this.day, required this.date, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: day.items.length,
        onReorder: (oldIndex, newIndex) {
          ref
              .read(tripProvider.notifier)
              .reorderItems(date, oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final item = day.items[index];
          return _ReorderableItem(
            key: ValueKey(item.id),
            item: item,
            date: date,
          );
        },
      ),
    );
  }
}

class _ReorderableItem extends StatelessWidget {
  final ItineraryItem item;
  final String date;

  const _ReorderableItem(
      {super.key, required this.item, required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.drag_handle, color: Colors.grey, size: 20),
        ),
        Expanded(
          child: ItemCard(
            item: item,
            date: date,
            isEditMode: true,
          ),
        ),
      ],
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────
class _EditFab extends StatelessWidget {
  final bool editMode;
  final VoidCallback onToggle;
  final VoidCallback? onAddItem;

  const _EditFab({
    required this.editMode,
    required this.onToggle,
    this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    if (editMode) {
      return FloatingActionButton.extended(
        onPressed: onToggle,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('完成編輯',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      );
    }
    return FloatingActionButton(
      onPressed: onToggle,
      backgroundColor: AppColors.accent,
      child: const Icon(Icons.edit_outlined, color: Colors.white),
    );
  }
}
