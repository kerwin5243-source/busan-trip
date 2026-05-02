import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/itinerary_item.dart';
import '../theme/app_theme.dart';

/// 從 onTap 呼叫：showItemDetail(context, item)
void showItemDetail(BuildContext context, ItineraryItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => ItemDetailSheet(
      item: item,
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}

class ItemDetailSheet extends StatelessWidget {
  final ItineraryItem item;
  final VoidCallback onClose;

  const ItemDetailSheet({
    super.key,
    required this.item,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final color = tagColor(item.tag);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenH * 0.78,
          minHeight: 200,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF7F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 50,
                offset: Offset(0, -10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // ── Drag handle ─────────────────────────────────────
          _DragHandle(onClose: onClose),
          // ── Sticky header ───────────────────────────────────
          _StickyHeader(item: item, color: color),
          // ── Scrollable body ─────────────────────────────────
          Flexible(
            child: SelectionArea(
              child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 0, 18, bottomPad + 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta box (addr, hours, parking, mapcode)
                  if (_hasMeta(item)) ...[
                    const SizedBox(height: 8),
                    _MetaBox(item: item),
                  ],
                  // Detail text
                  if (item.detail.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      item.detail,
                      style: TStyle.sans(15,
                          fw: FontWeight.w400,
                          color: const Color(0xFF3A352E)).copyWith(height: 1.7),
                    ),
                  ],
                  // Guide block
                  if (item.guide.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Block(
                      icon: Icons.lightbulb_outline_rounded,
                      title: '導覽',
                      children: item.guide.map((g) => _BulletText(g)).toList(),
                    ),
                  ],
                  // Avoid block
                  if (item.avoid.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Block(
                      icon: Icons.warning_amber_rounded,
                      title: '注意事項',
                      children: item.avoid.map((a) => _BulletText(a)).toList(),
                    ),
                  ],
                  // Menu block
                  if (item.menu.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _MenuBox(menu: item.menu),
                  ],
                  // Reservations
                  if (item.reservations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Block(
                      icon: Icons.receipt_long_outlined,
                      title: '預約資訊',
                      children: item.reservations.map((r) => _ReservRow(r)).toList(),
                    ),
                  ],
                  // Links
                  if (item.links.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: item.links.map((l) => _LinkChip(l)).toList(),
                    ),
                  ],
                  // Google Maps button
                  if (item.addr.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _MapButton(addr: item.addr),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ), // SelectionArea
          ),
        ],
          ),
        ),
      ),
    );
  }

  bool _hasMeta(ItineraryItem item) =>
      item.addr.isNotEmpty ||
      item.hours.isNotEmpty ||
      item.parking.isNotEmpty ||
      item.mapcode.isNotEmpty;
}

// ─── Drag handle ──────────────────────────────────────────────────────────────
class _DragHandle extends StatelessWidget {
  final VoidCallback onClose;
  const _DragHandle({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 48),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 44, height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD8CFC4),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(right: 14, top: 8, bottom: 8, left: 4),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBE3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: Color(0xFF888070)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sticky header ────────────────────────────────────────────────────────────
class _StickyHeader extends StatelessWidget {
  final ItineraryItem item;
  final Color color;

  const _StickyHeader({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9E1D6), width: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tagLabel(item.tag),
                          style: TStyle.sans(10,
                              fw: FontWeight.w900,
                              color: color),
                        ),
                      ),
                      if (item.time.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.access_time_rounded,
                            size: 12, color: C.ink2),
                        const SizedBox(width: 4),
                        Text(item.time,
                            style: TStyle.mono(12, color: C.ink2)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    item.title,
                    style: TStyle.serifTitle(20, color: C.ink),
                  ),
                  // Pills: hours / price / stay
                  if (item.hours.isNotEmpty ||
                      item.price.isNotEmpty ||
                      item.stay.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.hours.isNotEmpty)
                          _Pill(Icons.access_time_rounded, item.hours),
                        if (item.price.isNotEmpty)
                          _Pill(Icons.confirmation_number_outlined, item.price),
                        if (item.stay.isNotEmpty)
                          _Pill(Icons.hourglass_bottom_rounded, item.stay),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: C.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF8B8175)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TStyle.sans(12,
                fw: FontWeight.w900,
                color: const Color(0xFF5F5A52)),
          ),
        ],
      ),
    );
  }
}

// ─── Meta box ─────────────────────────────────────────────────────────────────
class _MetaBox extends StatelessWidget {
  final ItineraryItem item;

  const _MetaBox({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: C.divider, width: 0.75),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          if (item.addr.isNotEmpty)
            _MetaRow(Icons.location_on_outlined, item.addr, copyable: true),
          if (item.hours.isNotEmpty)
            _MetaRow(Icons.access_time_outlined, item.hours),
          if (item.parking.isNotEmpty)
            _MetaRow(Icons.local_parking_outlined, item.parking),
          if (item.mapcode.isNotEmpty)
            _MetaRow(Icons.map_outlined, 'Mapcode: ${item.mapcode}',
                copyable: true, copyValue: item.mapcode),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool copyable;
  final String? copyValue;

  const _MetaRow(this.icon, this.text,
      {this.copyable = false, this.copyValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: C.ink2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TStyle.sans(14,
                  fw: FontWeight.w400, color: const Color(0xFF6F6A62)),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: copyValue ?? text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已複製',
                        style: TStyle.sans(13, fw: FontWeight.w700,
                            color: Colors.white)),
                    duration: const Duration(seconds: 1),
                    backgroundColor: C.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.divider),
                ),
                child: Text('複製',
                    style: TStyle.sans(12,
                        fw: FontWeight.w900,
                        color: const Color(0xFF5F5A52))),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Content block ────────────────────────────────────────────────────────────
class _Block extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Block(
      {required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.divider.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF8B8175)),
              const SizedBox(width: 7),
              Text(title,
                  style:
                      TStyle.serifTitle(15, color: C.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: C.ink2, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TStyle.sans(14,
                  fw: FontWeight.w400,
                  color: const Color(0xFF444444)).copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu box ─────────────────────────────────────────────────────────────────
class _MenuBox extends StatelessWidget {
  final List<Map<String, dynamic>> menu;

  const _MenuBox({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0x8CFFF2D2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0x8CD2B878)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded,
                  size: 15, color: Color(0xFF5B4A2F)),
              const SizedBox(width: 7),
              Text('菜單',
                  style: TStyle.sans(14,
                      fw: FontWeight.w900,
                      color: const Color(0xFF5B4A2F))),
            ],
          ),
          const SizedBox(height: 10),
          ...menu.asMap().entries.map((e) {
            final m = e.value;
            final isLast = e.key == menu.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                            color: Color(0x14000000))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((m['jp'] ?? '').isNotEmpty)
                          Text(m['jp'] as String,
                              style: TStyle.sans(14,
                                  fw: FontWeight.w900,
                                  color: const Color(0xFF4B2E2A))),
                        if ((m['zh'] ?? '').isNotEmpty)
                          Text(m['zh'] as String,
                              style: TStyle.sans(13,
                                  fw: FontWeight.w400,
                                  color: const Color(0xFF6B7280))),
                        if ((m['note'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(m['note'] as String,
                                style: TStyle.sans(12,
                                    fw: FontWeight.w400,
                                    color: C.ink2)),
                          ),
                      ],
                    ),
                  ),
                  if (m['rec'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: C.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('推薦',
                          style: TStyle.sans(11,
                              fw: FontWeight.w900,
                              color: C.accent)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Reservation row ──────────────────────────────────────────────────────────
class _ReservRow extends StatelessWidget {
  final Map<String, String> data;

  const _ReservRow(this.data);

  @override
  Widget build(BuildContext context) {
    final label = data['label'] ?? '';
    final value = data['value'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label：',
              style: TStyle.sans(13,
                  fw: FontWeight.w900, color: C.ink)),
          Expanded(
            child: Text(value,
                style: TStyle.sans(13, fw: FontWeight.w400, color: C.ink2)),
          ),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: value)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: C.divider),
              ),
              child: Text('複製',
                  style: TStyle.sans(11,
                      fw: FontWeight.w900,
                      color: const Color(0xFF5F5A52))),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Link chip ────────────────────────────────────────────────────────────────
class _LinkChip extends StatelessWidget {
  final Map<String, String> link;

  const _LinkChip(this.link);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: C.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.open_in_new_rounded,
              size: 12, color: C.accent),
          const SizedBox(width: 5),
          Text(
            link['label'] ?? '連結',
            style: TStyle.sans(13, fw: FontWeight.w900, color: C.primary),
          ),
        ],
      ),
    );
  }
}

// ─── Map button ───────────────────────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  final String addr;

  const _MapButton({required this.addr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_rounded, size: 18, color: C.primary),
          const SizedBox(width: 8),
          Text('Google Maps 導航',
              style: TStyle.sans(15, fw: FontWeight.w900, color: C.primary)),
        ],
      ),
    );
  }
}
