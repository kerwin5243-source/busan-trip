import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as s;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

// ─── Providers ────────────────────────────────────────────────────────────────
final _flightProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final raw = await s.rootBundle.loadString('assets/data/flights.json');
  return jsonDecode(raw) as Map<String, dynamic>;
});

final _hotelsProvider = FutureProvider<List<dynamic>>((ref) async {
  final raw = await s.rootBundle.loadString('assets/data/hotels.json');
  return jsonDecode(raw) as List<dynamic>;
});

// ─── Screen ───────────────────────────────────────────────────────────────────
class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flights = ref.watch(_flightProvider);
    final hotels = ref.watch(_hotelsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: const PageHeader(title: '資訊'),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20,
              MediaQuery.of(context).padding.bottom + 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Flights ─────────────────────────────────────
              SectionTitle('航班資訊', icon: Icons.flight_rounded),
              flights.when(
                data: (f) => _FlightCard(data: f),
                loading: () => const _Loading(),
                error: (_, __) => _EmptyCard('航班資訊待填入'),
              ),
              const SizedBox(height: 24),
              // ── Hotels ──────────────────────────────────────
              SectionTitle('住宿資訊', icon: Icons.hotel_rounded),
              hotels.when(
                data: (list) => Column(
                  children: list
                      .map((h) => _HotelCard(data: h as Map<String, dynamic>))
                      .toList(),
                ),
                loading: () => const _Loading(),
                error: (_, __) => _EmptyCard('住宿資訊待填入'),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Page header ─────────────────────────────────────────────────────────────
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({required this.title, this.subtitle = '', super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TStyle.serifTitle(28)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TStyle.sans(14, fw: FontWeight.w600, color: C.ink2)),
          ],
        ],
      ),
    );
  }
}

// ─── Flight card ─────────────────────────────────────────────────────────────
class _FlightCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FlightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final carrier = data['carrier'] ?? '';
    final out = data['outbound'] as Map<String, dynamic>? ?? {};
    final inb = data['inbound'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        _FlightLeg(label: '去程', leg: out, carrier: carrier),
        const SizedBox(height: 12),
        _FlightLeg(label: '回程', leg: inb, carrier: carrier),
      ],
    );
  }
}

class _FlightLeg extends StatelessWidget {
  final String label;
  final Map<String, dynamic> leg;
  final String carrier;

  const _FlightLeg(
      {required this.label, required this.leg, required this.carrier});

  @override
  Widget build(BuildContext context) {
    final from = leg['from'] as Map<String, dynamic>? ?? {};
    final to = leg['to'] as Map<String, dynamic>? ?? {};
    final baggage = leg['baggage'] as Map<String, dynamic>? ?? {};

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + flight no
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: C.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(label,
                    style: TStyle.sans(11,
                        fw: FontWeight.w900, color: C.accent)),
              ),
              const SizedBox(width: 8),
              Text(
                '${carrier.isNotEmpty ? carrier : ''} ${leg['flight_no'] ?? 'TBD'}',
                style: TStyle.sans(13, fw: FontWeight.w700, color: C.ink2),
              ),
              const Spacer(),
              Text(leg['date'] ?? '',
                  style: TStyle.mono(12, color: C.ink2)),
            ],
          ),
          const SizedBox(height: 16),
          // Route row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Departure
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leg['depart_time'] ?? '--:--',
                        style: TStyle.mono(26, color: C.ink)),
                    Text(
                      '${from['city'] ?? ''} (${from['code'] ?? ''})'
                      '${(from['terminal'] ?? '').isNotEmpty ? ' · ${from['terminal']}' : ''}',
                      style: TStyle.sans(12,
                          fw: FontWeight.w600, color: C.ink2),
                    ),
                  ],
                ),
              ),
              // Plane icon — takeoff for 去程, land for 回程
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Icon(
                      label == '去程'
                          ? Icons.flight_takeoff_rounded
                          : Icons.flight_land_rounded,
                      size: 22,
                      color: C.accent,
                    ),
                    Container(
                      width: 60,
                      height: 1,
                      color: C.divider,
                    ),
                  ],
                ),
              ),
              // Arrival
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(leg['arrive_time'] ?? '--:--',
                        style: TStyle.mono(26, color: C.ink)),
                    Text(
                      '${to['city'] ?? ''} (${to['code'] ?? ''})',
                      style: TStyle.sans(12,
                          fw: FontWeight.w600, color: C.ink2),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (baggage.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0x22000000)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.luggage_rounded,
                    size: 14, color: Color(0xFF8B8175)),
                const SizedBox(width: 6),
                Text(
                  '托運行李：${baggage['checked'] ?? ''} × ${baggage['pieces'] ?? 1} 件',
                  style: TStyle.sans(12,
                      fw: FontWeight.w600, color: C.ink2),
                ),
                if ((leg['aircraft'] ?? '').isNotEmpty) ...[
                  const Spacer(),
                  Text(leg['aircraft'] as String,
                      style: TStyle.sans(11, color: C.ink2)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Hotel card ───────────────────────────────────────────────────────────────
class _HotelCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const _HotelCard({required this.data});

  @override
  State<_HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<_HotelCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.data;
    final stay = h['stay'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        radius: 20,
        child: Column(
          children: [
            // Header
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: C.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.hotel_rounded,
                          size: 22, color: C.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h['name'] ?? '',
                              style: TStyle.serifTitle(15)),
                          const SizedBox(height: 3),
                          Text(
                            '${stay['from'] ?? ''} ～ ${stay['to'] ?? ''}  ·  ${h['nights'] ?? ''}晚',
                            style: TStyle.sans(12,
                                fw: FontWeight.w600, color: C.ink2),
                          ),
                          if ((h['checkin'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'CI ${h['checkin']}  ·  CO ${h['checkout'] ?? ''}',
                              style: TStyle.sans(11, color: C.ink2),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: C.ink2,
                    ),
                  ],
                ),
              ),
            ),
            // Expanded detail
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _HotelDetail(data: h),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelDetail extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HotelDetail({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0x22000000)),
          const SizedBox(height: 12),
          if ((data['desc'] ?? '').isNotEmpty)
            Text(data['desc'] as String,
                style: TStyle.sans(13, fw: FontWeight.w600, color: C.ink2)),
          if ((data['address'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(Icons.location_on_outlined, data['address'] as String,
                copyable: true),
          ],
          if ((data['phone'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(Icons.phone_outlined, data['phone'] as String,
                copyable: true),
          ],
          if ((data['mapcode'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(
                Icons.map_outlined, 'Mapcode: ${data['mapcode']}',
                copyable: true),
          ],
          if ((data['booking_ref'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(Icons.receipt_long_outlined,
                '訂單號：${data['booking_ref']}',
                copyable: true),
          ],
          // Notices
          if ((data['notices'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0x22000000)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: Color(0xFF8B8175)),
                const SizedBox(width: 6),
                Text('注意事項', style: TStyle.serifTitle(13, color: C.primary)),
              ],
            ),
            const SizedBox(height: 8),
            ...(data['notices'] as List).map<Widget>((n) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 6),
                    child: Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                          color: C.ink2, shape: BoxShape.circle),
                    ),
                  ),
                  Expanded(
                    child: Text(n as String,
                        style: TStyle.sans(12, color: C.ink2)),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 14),
          // Map button
          _MapBtn(addr: data['address'] ?? ''),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool copyable;

  const _InfoRow(this.icon, this.text, {this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: C.ink2),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TStyle.sans(13, color: C.ink2)),
        ),
        if (copyable)
          GestureDetector(
            onTap: () {
              s.Clipboard.setData(s.ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('已複製',
                    style: TStyle.sans(13,
                        fw: FontWeight.w700, color: Colors.white)),
                duration: const Duration(seconds: 1),
                backgroundColor: C.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: C.divider),
              ),
              child: Text('複製',
                  style: TStyle.sans(11,
                      fw: FontWeight.w900, color: C.ink2)),
            ),
          ),
      ],
    );
  }
}

class _MapBtn extends StatelessWidget {
  final String addr;

  const _MapBtn({required this.addr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_rounded, size: 16, color: C.primary),
          const SizedBox(width: 6),
          Text('Google Maps 導航',
              style: TStyle.sans(13,
                  fw: FontWeight.w900, color: C.primary)),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(
            strokeWidth: 2),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard(this.text);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Center(
        child: Text(text,
            style: TStyle.sans(14, color: C.ink2)),
      ),
    );
  }
}
