import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/itinerary_item.dart';
import '../theme/app_theme.dart';

class TimelineItem extends StatefulWidget {
  final ItineraryItem item;
  final VoidCallback onTap;
  final bool isEditMode;

  const TimelineItem({
    super.key,
    required this.item,
    required this.onTap,
    this.isEditMode = false,
  });

  @override
  State<TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<TimelineItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    // Route item — special compact style
    if (item.tag == ItemTag.route) {
      return _RouteStrip(item: item);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time column ──────────────────────────────────────
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Text(
                item.time,
                textAlign: TextAlign.right,
                style: TStyle.mono(15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Card ─────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: widget.onTap,
              child: AnimatedScale(
                scale: _pressed ? 0.985 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: _ItemCard(item: item, isEditMode: widget.isEditMode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main card ────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final ItineraryItem item;
  final bool isEditMode;

  const _ItemCard({required this.item, required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    final color = tagColor(item.tag);
    final isHighlight = item.highlight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isHighlight
                ? const Color(0xB8FFFFFF)
                : const Color(0xC7FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHighlight
                  ? C.accent.withValues(alpha: 0.70)
                  : C.divider.withValues(alpha: 0.85),
              width: 1,
            ),
            boxShadow: isHighlight
                ? [
                    ...C.shadowCard,
                    BoxShadow(
                      color: C.accent.withValues(alpha: 0.40),
                      blurRadius: 28,
                      spreadRadius: 0,
                    ),
                  ]
                : C.shadowCard,
            gradient: isHighlight
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      C.accent.withValues(alpha: 0.14),
                      C.accent.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.55],
                  )
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag row
                  Row(
                    children: [
                      _TagDot(color: color, label: tagLabel(item.tag)),
                      if (item.subtag.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.subtag,
                          style: TStyle.sans(11,
                              fw: FontWeight.w600,
                              color: C.ink2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    item.title,
                    style: TStyle.serifTitle(17, color: C.ink),
                  ),
                  // Desc
                  if (item.desc.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.desc,
                      style: TStyle.sans(14,
                          fw: FontWeight.w400, color: C.ink2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Meta chips
                  if (item.stay.isNotEmpty || item.price.isNotEmpty || item.hours.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.hours.isNotEmpty) _MetaChip(Icons.access_time_rounded, item.hours),
                        if (item.price.isNotEmpty) _MetaChip(Icons.confirmation_number_outlined, item.price),
                        if (item.stay.isNotEmpty) _MetaChip(Icons.hourglass_bottom_rounded, item.stay),
                      ],
                    ),
                  ],
                ],
              ),
              // Highlight star badge
              if (isHighlight)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: C.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: C.accent.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('★', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ),
              // Reserved badge
              if (item.reserved && !isHighlight)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Transform.rotate(
                    angle: -0.14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFB42318).withValues(alpha: 0.72),
                          width: 1.6,
                        ),
                      ),
                      child: Text(
                        '預約中',
                        style: TStyle.sans(10,
                            fw: FontWeight.w900,
                            color: const Color(0xFFB42318)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tag dot ──────────────────────────────────────────────────────────────────
class _TagDot extends StatelessWidget {
  final Color color;
  final String label;

  const _TagDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TStyle.sans(10,
              fw: FontWeight.w900,
              color: const Color(0xFFA5A39F)),
        ),
      ],
    );
  }
}

// ─── Meta chip ────────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF8E8E93)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TStyle.sans(12,
                fw: FontWeight.w800,
                color: const Color(0xFF555555)),
          ),
        ],
      ),
    );
  }
}

// ─── Route strip ─────────────────────────────────────────────────────────────
class _RouteStrip extends StatelessWidget {
  final ItineraryItem item;

  const _RouteStrip({required this.item});

  @override
  Widget build(BuildContext context) {
    final route = item.route;
    final mins = route?.minutes ?? 0;
    final minsText = mins > 0 ? '$mins min' : item.stay;
    final modeIcon = _modeIcon(route?.mode ?? 'drive');

    return Padding(
      padding: const EdgeInsets.only(left: 76, bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(modeIcon, size: 16, color: C.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.title.isNotEmpty)
                    Text(
                      item.title,
                      style: TStyle.sans(14, fw: FontWeight.w900, color: C.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (route != null && route.from.isNotEmpty)
                    Text(
                      '${route.from} → ${route.to}',
                      style: TStyle.sans(13, fw: FontWeight.w700, color: C.ink2),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (minsText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  minsText,
                  style: TStyle.mono(11, color: const Color(0xFF444444)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'walk':    return Icons.directions_walk;
      case 'transit': return Icons.directions_transit;
      case 'plane':   return Icons.flight;
      case 'ferry':   return Icons.directions_boat;
      default:        return Icons.directions_car;
    }
  }
}
