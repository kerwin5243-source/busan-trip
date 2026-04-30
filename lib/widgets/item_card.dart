import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/itinerary_item.dart';
import '../providers/trip_provider.dart';
import '../theme/app_theme.dart';
import 'edit_item_sheet.dart';

class ItemCard extends ConsumerStatefulWidget {
  final ItineraryItem item;
  final String date;
  final bool isEditMode;

  const ItemCard({
    super.key,
    required this.item,
    required this.date,
    required this.isEditMode,
  });

  @override
  ConsumerState<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends ConsumerState<ItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = tagColor(item.tag);

    if (item.tag == ItemTag.route) {
      return _RouteCard(item: item);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: item.highlight
            ? Border.all(color: AppColors.accent, width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _CardHeader(
            item: item,
            color: color,
            expanded: _expanded,
            isEditMode: widget.isEditMode,
            onTap: () => setState(() => _expanded = !_expanded),
            onEdit: () => _openEdit(context),
            onDelete: () => _confirmDelete(context),
          ),
          if (_expanded) _CardBody(item: item),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditItemSheet(item: widget.item, date: widget.date),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除行程'),
        content: Text('確定要刪除「${widget.item.title}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(tripProvider.notifier).deleteItem(widget.date, widget.item.id);
    }
  }
}

// ── Card header ───────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final ItineraryItem item;
  final Color color;
  final bool expanded;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardHeader({
    required this.item,
    required this.color,
    required this.expanded,
    required this.isEditMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDetail = item.desc.isNotEmpty ||
        item.detail.isNotEmpty ||
        item.guide.isNotEmpty ||
        item.avoid.isNotEmpty ||
        item.addr.isNotEmpty;

    return InkWell(
      onTap: hasDetail ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tagIcon(item.tag), size: 18, color: color),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.time.isNotEmpty)
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (item.time.isNotEmpty && item.subtag.isNotEmpty)
                        const SizedBox(width: 6),
                      if (item.subtag.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.subtag,
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (item.reserved)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.bookmark,
                              size: 13, color: AppColors.accent),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item.desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.desc,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: expanded ? null : 2,
                      overflow:
                          expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.stay.isNotEmpty || item.price.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.stay.isNotEmpty) _InfoChip(Icons.schedule, item.stay),
                        if (item.stay.isNotEmpty && item.price.isNotEmpty)
                          const SizedBox(width: 6),
                        if (item.price.isNotEmpty)
                          _InfoChip(Icons.attach_money, item.price),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Edit mode buttons
            if (isEditMode) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.primaryLight,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red[400],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onDelete,
              ),
            ] else if (hasDetail)
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Expanded body ─────────────────────────────────────────────────────────────
class _CardBody extends StatelessWidget {
  final ItineraryItem item;

  const _CardBody({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (item.detail.isNotEmpty) ...[
            _BodySection('', item.detail),
            const SizedBox(height: 8),
          ],
          if (item.addr.isNotEmpty)
            _BodyRow(Icons.location_on_outlined, item.addr),
          if (item.hours.isNotEmpty)
            _BodyRow(Icons.access_time_outlined, item.hours),
          if (item.parking.isNotEmpty)
            _BodyRow(Icons.local_parking_outlined, item.parking),
          if (item.mapcode.isNotEmpty)
            _BodyRow(Icons.map_outlined, 'Mapcode: ${item.mapcode}'),
          if (item.guide.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionTitle('導覽'),
            ...item.guide.map((g) => _BulletText(g)),
          ],
          if (item.avoid.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionTitle('注意事項'),
            ...item.avoid.map((a) => _BulletText(a)),
          ],
          if (item.reservations.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionTitle('預訂資訊'),
            ...item.reservations.map((r) => _ReservRow(r)),
          ],
          if (item.links.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: item.links.map((l) => _LinkChip(l)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _BodySection extends StatelessWidget {
  final String title;
  final String content;
  const _BodySection(this.title, this.content);

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class _BodyRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BodyRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}

class _ReservRow extends StatelessWidget {
  final Map<String, String> data;
  const _ReservRow(this.data);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(
            '${data['label']}: ',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444466)),
          ),
          Text(
            data['value'] ?? '',
            style: const TextStyle(fontSize: 12, color: Color(0xFF666688)),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final Map<String, String> link;
  const _LinkChip(this.link);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar:
          Icon(Icons.open_in_new, size: 12, color: AppColors.primaryLight),
      label: Text(link['label'] ?? '連結',
          style: const TextStyle(fontSize: 11)),
      onPressed: () {
        // url_launcher would open link['url']
      },
      backgroundColor: AppColors.primaryLight.withOpacity(0.08),
      side: BorderSide(color: AppColors.primaryLight.withOpacity(0.3)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey[600]),
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// ── Route card ────────────────────────────────────────────────────────────────
class _RouteCard extends StatelessWidget {
  final ItineraryItem item;

  const _RouteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final route = item.route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            route?.mode == 'drive'
                ? Icons.directions_car
                : route?.mode == 'walk'
                    ? Icons.directions_walk
                    : route?.mode == 'plane'
                        ? Icons.flight
                        : Icons.directions,
            size: 15,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 6),
          if (route != null && route.minutes > 0)
            Text(
              '約 ${route.minutes} 分鐘',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            )
          else if (item.stay.isNotEmpty)
            Text(
              item.stay,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }
}
