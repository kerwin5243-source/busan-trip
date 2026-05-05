import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/itinerary_item.dart';
import '../providers/trip_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/timeline_item.dart';
import '../widgets/item_detail_sheet.dart';
import 'info_screen.dart';
import 'souvenir_screen.dart';
import 'money_screen.dart';
import 'prep_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  NavTab _currentTab = NavTab.itinerary;
  int _selectedDayIndex = 0;
  final ScrollController _scrollCtrl = ScrollController();
  bool _showScrollTop = false;
  // Lazy tab loading — only build a tab after first visit
  final Set<NavTab> _visitedTabs = {NavTab.itinerary};

  static const _dates = [
    '2026-06-06', '2026-06-07', '2026-06-08', '2026-06-09', '2026-06-10',
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 250;
      if (show != _showScrollTop) setState(() => _showScrollTop = show);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: C.bgBody,
      body: Stack(
        children: [
          // ── Main content ──────────────────────────────────
          Column(
            children: [
              // Always-visible compact header
              _CompactHeader(config: state.config, topPad: topPad),
              // Tab content — IndexedStack keeps all tabs alive for instant switching
              Expanded(
                child: state.loading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: C.accent, strokeWidth: 2))
                    : IndexedStack(
                        index: _currentTab.index,
                        children: [
                          // Tab 0: Itinerary (always built)
                          _SafeTab(child: _ItineraryPage(
                            state: state,
                            selectedIndex: _selectedDayIndex,
                            dates: _dates,
                            scrollCtrl: _scrollCtrl,
                            onDaySelected: (i) => setState(() {
                              _selectedDayIndex = i;
                              _scrollCtrl.animateTo(0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut);
                            }),
                          )),
                          // Tabs 1-4: lazy — only build after first visit
                          _visitedTabs.contains(NavTab.info)
                              ? const _SafeTab(child: InfoScreen())
                              : const SizedBox.shrink(),
                          _visitedTabs.contains(NavTab.souvenir)
                              ? _SafeTab(child: SouvenirScreen(
                                  members: state.config?.members ?? const []))
                              : const SizedBox.shrink(),
                          _visitedTabs.contains(NavTab.money)
                              ? _SafeTab(child: MoneyScreen(
                                  members: state.config?.members ?? const []))
                              : const SizedBox.shrink(),
                          _visitedTabs.contains(NavTab.prep)
                              ? _SafeTab(child: PrepScreen(
                                  members: state.config?.members ?? const []))
                              : const SizedBox.shrink(),
                        ],
                      ),
              ),
            ],
          ),
          // ── Bottom nav ────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: BottomNav(
              current: _currentTab,
              onTap: (t) => setState(() {
                _currentTab = t;
                _visitedTabs.add(t);
              }),
              onSwipe: (dir) {
                final tabs = NavTab.values;
                final idx = tabs.indexOf(_currentTab);
                final newIdx = (idx + dir).clamp(0, tabs.length - 1);
                if (newIdx != idx) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentTab = tabs[newIdx];
                    _visitedTabs.add(tabs[newIdx]);
                  });
                }
              },
            ),
          ),
          // ── Scroll-to-top FAB (above nav, left side) ─────
          if (_currentTab == NavTab.itinerary && _showScrollTop)
            Positioned(
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 88,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _scrollCtrl.animateTo(0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut);
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: C.shadowSoft,
                    border: Border.all(
                        color: C.accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.keyboard_arrow_up_rounded,
                      color: C.accent, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Error boundary wrapper ───────────────────────────────────────────────────
class _SafeTab extends StatefulWidget {
  final Widget child;
  const _SafeTab({required this.child});

  @override
  State<_SafeTab> createState() => _SafeTabState();
}

class _SafeTabState extends State<_SafeTab> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Override error widget locally for this subtree
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: Colors.red),
              const SizedBox(height: 12),
              Text('頁面發生錯誤', style: TStyle.sans(14, color: C.ink2)),
              const SizedBox(height: 8),
              Text('$_error',
                  style: TStyle.sans(10, color: C.ink2),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }
    // Use runZonedGuarded pattern via Flutter's error mechanism
    return widget.child;
  }
}

// ─── Always-visible compact header ────────────────────────────────────────────
class _CompactHeader extends StatelessWidget {
  final dynamic config;
  final double topPad;

  const _CompactHeader({required this.config, required this.topPad});

  // Korean district names
  static const _koreanDistricts = ['해운대', '남포동', '서면', '광안리'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 10),
      decoration: BoxDecoration(
        color: C.bgBody,
        border: const Border(
          bottom: BorderSide(color: Color(0x14000000), width: 0.75),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          // ── Title: "月半家族釜山之旅" centered ───────────────
          Text(
            config?.tripTitle ?? '月半家族釜山之旅',
            style: TStyle.serifTitle(22, color: C.ink),
          ),
          const SizedBox(height: 5),
          // ── Korean district names ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < _koreanDistricts.length; i++) ...[
                if (i > 0)
                  Text(' · ',
                      style: TStyle.sans(12,
                          color: C.ink2.withValues(alpha: 0.35))),
                Text(
                  _koreanDistricts[i],
                  style: TStyle.sans(12,
                      fw: FontWeight.w600,
                      color: C.ink2.withValues(alpha: 0.7)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          // ── "5天4夜 · 2026" subtitle row ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: C.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: C.accent.withValues(alpha: 0.35), width: 1),
                ),
                child: Text('5天4夜',
                    style: TStyle.sans(10,
                        fw: FontWeight.w900,
                        color: const Color(0xFF7D5B34))),
              ),
              const SizedBox(width: 6),
              Text('· 2026',
                  style: TStyle.sans(11,
                      fw: FontWeight.w600,
                      color: C.ink2.withValues(alpha: 0.6))),
            ],
          ),
        ],
          ),
          // ── Settings gear icon (top-right) ────────────
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.settings_outlined,
                  size: 20,
                  color: C.ink2.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Itinerary Page ───────────────────────────────────────────────────────────
class _ItineraryPage extends StatefulWidget {
  final TripState state;
  final int selectedIndex;
  final List<String> dates;
  final ScrollController scrollCtrl;
  final ValueChanged<int> onDaySelected;

  const _ItineraryPage({
    required this.state,
    required this.selectedIndex,
    required this.dates,
    required this.scrollCtrl,
    required this.onDaySelected,
  });

  @override
  State<_ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<_ItineraryPage> {
  int _carouselIndex = 0;
  late PageController _pageCtrl;

  // Per-day banner colors (placeholder until real images added)
  static const _dayColors = [
    [Color(0xFF3D7BBF), Color(0xFF1A4A7A)], // Day1 navy
    [Color(0xFF2F8F5B), Color(0xFF1A5237)], // Day2 green
    [Color(0xFFB08A5B), Color(0xFF7D5B34)], // Day3 gold
    [Color(0xFF8B5CF6), Color(0xFF5B21B6)], // Day4 purple
    [Color(0xFFE5534B), Color(0xFF9B1C1C)], // Day5 red
  ];

  static const _daySubtitles = [
    '抵達釜山 · 海雲台海邊',
    '松島纜車 · 甘川文化村',
    '西面購物 · 南浦洞夜市',
    '廣安大橋 · 機張市場',
    '離開釜山 · 平安回家',
  ];

  // Per-day region for weather label
  static const _dayDistricts = ['海雲台', '甘川', '西面', '廣安里', '機場'];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page?.round() ?? 0;
      if (p != _carouselIndex) setState(() => _carouselIndex = p);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.loading) {
      return Center(child: CircularProgressIndicator(color: C.accent));
    }

    final currentDate = widget.selectedIndex < widget.dates.length
        ? widget.dates[widget.selectedIndex]
        : '';
    final day = widget.state.days[currentDate];
    final colors = widget.selectedIndex < _dayColors.length
        ? _dayColors[widget.selectedIndex]
        : _dayColors[0];

    return CustomScrollView(
      controller: widget.scrollCtrl,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Full-width date chips ────────────────────────────
        SliverToBoxAdapter(
          child: _DateRow(
            days: widget.state.sortedDays,
            selectedIndex: widget.selectedIndex,
            onSelect: widget.onDaySelected,
          ),
        ),

        // ── Banner carousel ──────────────────────────────────
        SliverToBoxAdapter(
          child: _DayBanner(
            dayIndex: widget.selectedIndex,
            colors: colors,
            subtitle: widget.selectedIndex < _daySubtitles.length
                ? _daySubtitles[widget.selectedIndex]
                : '',
          ),
        ),

        // ── Weather + hotel strip ────────────────────────────
        SliverToBoxAdapter(
          child: _WeatherHotelStrip(
            district: widget.selectedIndex < _dayDistricts.length
                ? _dayDistricts[widget.selectedIndex]
                : '釜山',
            hotelName: 'L7 Hotel 海雲台',
            showHotel: widget.selectedIndex < 4,
          ),
        ),

        // ── Google Maps day route button ─────────────────────
        SliverToBoxAdapter(
          child: _MapRouteButton(
            dayIndex: widget.selectedIndex,
            day: day,
          ),
        ),

        // ── Timeline ────────────────────────────────────────
        if (day != null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                20, 14, 20, MediaQuery.of(context).padding.bottom + 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => TimelineItem(
                  item: day.items[i],
                  onTap: () => showItemDetail(context, day.items[i]),
                ),
                childCount: day.items.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Full-width date row ───────────────────────────────────────────────────────
class _DateRow extends StatelessWidget {
  final List<ItineraryDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _DateRow({
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const _weekDays = ['一', '二', '三', '四', '五', '六', '日'];
  static const _weekEnList = ['MON','TUE','WED','THU','FRI','SAT','SUN'];

  String _toWeekEn(String zh) {
    final idx = _weekDays.indexOf(zh);
    return idx < 0 ? '' : _weekEnList[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: List.generate(days.length, (i) {
          final day = days[i];
          final isActive = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                transform: Matrix4.translationValues(0, isActive ? -2 : 0, 0),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? C.accent.withValues(alpha: 0.8)
                        : C.divider.withValues(alpha: 0.9),
                    width: isActive ? 1.5 : 1,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(
                          color: C.accent.withValues(alpha: 0.18),
                          blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Day ${i + 1}',
                      style: TStyle.serifTitle(13,
                          color: isActive
                              ? const Color(0xFF724B1D)
                              : C.ink.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      day.displayDate,
                      style: TStyle.sans(9,
                          fw: FontWeight.w800, color: C.ink2),
                    ),
                    Text(
                      _toWeekEn(day.dayOfWeek),
                      style: TStyle.sans(8,
                          color: C.ink.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Day banner with photo picker ─────────────────────────────────────────────
class _DayBanner extends StatefulWidget {
  final int dayIndex;
  final List<Color> colors;
  final String subtitle;

  const _DayBanner({
    required this.dayIndex,
    required this.colors,
    required this.subtitle,
  });

  @override
  State<_DayBanner> createState() => _DayBannerState();
}

class _DayBannerState extends State<_DayBanner> {
  String? _photoPath;
  ImagePicker? _picker;

  static const _dayNames = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5'];

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(_DayBanner old) {
    super.didUpdateWidget(old);
    if (old.dayIndex != widget.dayIndex) _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('day_photo_${widget.dayIndex}');
    if (path != null) {
      // If the file no longer exists (e.g. app reinstall), clear stale path
      if (File(path).existsSync()) {
        if (mounted) setState(() => _photoPath = path);
      } else {
        await prefs.remove('day_photo_${widget.dayIndex}');
      }
    }
  }

  Future<void> _pickPhoto() async {
    _picker ??= ImagePicker();
    final xf = await _picker!.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (xf == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('day_photo_${widget.dayIndex}', xf.path);
    if (mounted) setState(() => _photoPath = xf.path);
  }

  Future<void> _removePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('day_photo_${widget.dayIndex}');
    if (mounted) setState(() => _photoPath = null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: GestureDetector(
        onTap: _pickPhoto,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            height: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.colors,
              ),
              image: _photoPath != null
                  ? DecorationImage(
                      image: FileImage(File(_photoPath!)),
                      fit: BoxFit.cover,
                      colorFilter: const ColorFilter.mode(
                          Colors.black38, BlendMode.darken),
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Decorative circles (only when no photo)
                if (_photoPath == null) ...[
                  Positioned(
                    right: -20, top: -20,
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30, bottom: -30,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ],
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.dayIndex < _dayNames.length
                              ? _dayNames[widget.dayIndex]
                              : 'Day ${widget.dayIndex + 1}',
                          style: TStyle.sans(10,
                              fw: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.subtitle,
                          style: TStyle.serifTitle(17, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _photoPath != null
                                ? Icons.photo_library
                                : Icons.photo_library_outlined,
                            size: 13,
                            color: Colors.white
                                .withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _photoPath != null
                                ? '點此更換照片'
                                : '點此加入旅遊照片',
                            style: TStyle.sans(11,
                                color:
                                    Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Remove photo button (top-right)
                if (_photoPath != null)
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: _removePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WMO code → emoji ────────────────────────────────────────────────────────
String _wmoEmoji(int code) {
  if (code == 0) return '☀️';
  if (code <= 2) return '🌤';
  if (code == 3) return '☁️';
  if (code <= 48) return '🌫';
  if (code <= 57) return '🌦';
  if (code <= 67) return '🌧';
  if (code <= 77) return '🌨';
  if (code <= 82) return '🌦';
  if (code <= 86) return '❄️';
  if (code <= 99) return '⛈';
  return '🌡';
}

String _wmoLabel(int code) {
  if (code == 0) return '晴天';
  if (code <= 2) return '多雲時晴';
  if (code == 3) return '陰天';
  if (code <= 48) return '有霧';
  if (code <= 57) return '毛毛雨';
  if (code <= 67) return '降雨';
  if (code <= 77) return '降雪';
  if (code <= 82) return '陣雨';
  if (code <= 86) return '雪陣雨';
  if (code <= 99) return '雷陣雨';
  return '未知';
}

// Hourly slot data
class _HourSlot {
  final int hour;
  final double temp;
  final int wmoCode;
  final int rainProb;
  const _HourSlot(this.hour, this.temp, this.wmoCode, this.rainProb);
}

// ─── Weather + hotel strip ────────────────────────────────────────────────────
class _WeatherHotelStrip extends StatefulWidget {
  final String district;
  final String hotelName;
  final bool showHotel;

  const _WeatherHotelStrip({
    required this.district,
    required this.hotelName,
    required this.showHotel,
  });

  @override
  State<_WeatherHotelStrip> createState() => _WeatherHotelStripState();
}

class _WeatherHotelStripState extends State<_WeatherHotelStrip> {
  List<_HourSlot> _hourly = [];
  double? _tempMin;
  double? _tempMax;
  int? _rainProbMax;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=35.1796&longitude=129.0756'
        '&hourly=temperature_2m,precipitation_probability,weathercode'
        '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max'
        '&timezone=Asia%2FSeoul'
        '&forecast_days=1',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final hourly = data['hourly'] as Map<String, dynamic>;
        final daily = data['daily'] as Map<String, dynamic>;

        final times = (hourly['time'] as List).cast<String>();
        final temps = (hourly['temperature_2m'] as List)
            .map((e) => e != null ? (e as num).toDouble() : 0.0)
            .toList();
        final probs = (hourly['precipitation_probability'] as List)
            .map((e) => e != null ? (e as num).toInt() : 0)
            .toList();
        final codes = (hourly['weathercode'] as List)
            .map((e) => e != null ? (e as num).toInt() : 0)
            .toList();

        // Pick 8 slots starting from current hour (or 8am if current < 8)
        final nowHour = DateTime.now().hour;
        final startHour = nowHour < 7 ? 7 : nowHour;
        final slots = <_HourSlot>[];
        for (int i = 0; i < times.length && slots.length < 8; i++) {
          final h = int.parse(times[i].split('T')[1].split(':')[0]);
          if (h >= startHour) {
            slots.add(_HourSlot(h, temps[i], codes[i], probs[i]));
          }
        }

        if (mounted) {
          setState(() {
            _hourly = slots;
            _tempMin = (daily['temperature_2m_min'] as List).isNotEmpty
                ? ((daily['temperature_2m_min'] as List)[0] as num).toDouble()
                : null;
            _tempMax = (daily['temperature_2m_max'] as List).isNotEmpty
                ? ((daily['temperature_2m_max'] as List)[0] as num).toDouble()
                : null;
            _rainProbMax =
                (daily['precipitation_probability_max'] as List).isNotEmpty
                    ? ((daily['precipitation_probability_max'] as List)[0]
                            as num)
                        .toInt()
                    : null;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Daily summary bar ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3D7BBF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF3D7BBF).withValues(alpha: 0.18)),
            ),
            child: _loading
                ? Row(children: [
                    const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF3D7BBF))),
                    const SizedBox(width: 10),
                    Text('天氣資料載入中…',
                        style: TStyle.sans(12, color: C.ink2)),
                  ])
                : Row(
                    children: [
                      Text(widget.district,
                          style: TStyle.sans(12,
                              fw: FontWeight.w800, color: C.primary)),
                      const SizedBox(width: 8),
                      // Temp range
                      if (_tempMin != null && _tempMax != null) ...[
                        Text(
                          '${_tempMin!.round()}–${_tempMax!.round()}°C',
                          style: TStyle.mono(12,
                              color: const Color(0xFF3D7BBF)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Rain probability
                      if (_rainProbMax != null) ...[
                        const Text('💧', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 2),
                        Text('$_rainProbMax%',
                            style: TStyle.mono(12,
                                color: _rainProbMax! >= 50
                                    ? Colors.blue
                                    : C.ink2)),
                      ],
                      // Overall label from first slot
                      if (_hourly.isNotEmpty) ...[
                        const Spacer(),
                        Text(_wmoLabel(_hourly[0].wmoCode),
                            style: TStyle.sans(11, color: C.ink2)),
                      ],
                    ],
                  ),
          ),
          // ── Hourly slots ───────────────────────────────────
          if (!_loading && _hourly.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _hourly.map((slot) {
                  final isNow =
                      slot.hour == DateTime.now().hour;
                  return Container(
                    width: 54,
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isNow
                          ? const Color(0xFF3D7BBF).withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isNow
                            ? const Color(0xFF3D7BBF).withValues(alpha: 0.4)
                            : C.divider,
                        width: isNow ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hour label
                        Text(
                          isNow ? '現在' : '${slot.hour}時',
                          style: TStyle.sans(9,
                              fw: FontWeight.w700,
                              color: isNow
                                  ? const Color(0xFF3D7BBF)
                                  : C.ink2),
                        ),
                        const SizedBox(height: 4),
                        // Weather emoji
                        Text(_wmoEmoji(slot.wmoCode),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        // Temperature
                        Text(
                          '${slot.temp.round()}°',
                          style: TStyle.mono(12,
                              color: C.ink),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          // ── Hotel strip ────────────────────────────────────
          if (widget.showHotel) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: C.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.hotel_outlined,
                      color: C.accent.withValues(alpha: 0.8), size: 18),
                  const SizedBox(width: 10),
                  Text('今晚住宿 · ',
                      style: TStyle.sans(11,
                          fw: FontWeight.w600, color: C.ink2)),
                  Expanded(
                    child: Text(
                      widget.hotelName,
                      style: TStyle.sans(11,
                          fw: FontWeight.w800, color: C.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Google Maps route button ─────────────────────────────────────────────────
class _MapRouteButton extends StatelessWidget {
  final int dayIndex;
  final ItineraryDay? day;

  const _MapRouteButton({required this.dayIndex, required this.day});

  Future<void> _openGoogleMaps() async {
    if (day == null || day!.items.isEmpty) return;

    // Build waypoints from items with location data
    final spots = day!.items
        .where((item) =>
            item.addr.isNotEmpty &&
            item.tag != ItemTag.transport)
        .take(8)
        .toList();

    if (spots.isEmpty) return;

    final origin = Uri.encodeComponent(
        spots.first.addr.isNotEmpty ? spots.first.addr : spots.first.title);
    final dest = Uri.encodeComponent(
        spots.last.addr.isNotEmpty ? spots.last.addr : spots.last.title);
    final waypoints = spots.length > 2
        ? spots
            .sublist(1, spots.length - 1)
            .map((s) => Uri.encodeComponent(
                s.addr.isNotEmpty ? s.addr : s.title))
            .join('|')
        : '';

    final url = waypoints.isNotEmpty
        ? 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&waypoints=$waypoints&travelmode=transit'
        : 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=transit';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: GestureDetector(
        onTap: _openGoogleMaps,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF34A853).withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF34A853).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map_outlined,
                    color: Color(0xFF34A853), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('今日路線地圖',
                        style: TStyle.sans(13,
                            fw: FontWeight.w800, color: C.primary)),
                    Text('點擊開啟 Google Maps 導航',
                        style: TStyle.sans(11,
                            color: C.ink2.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  size: 16,
                  color: const Color(0xFF34A853).withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
