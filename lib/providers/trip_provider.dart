import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_config.dart';
import '../models/itinerary_item.dart';

// ─── Date list ───────────────────────────────────────────────────────────────
const _tripDates = [
  '2026-06-06',
  '2026-06-07',
  '2026-06-08',
  '2026-06-09',
  '2026-06-10',
];

// ─── State ───────────────────────────────────────────────────────────────────
class TripState {
  final TripConfig? config;
  final Map<String, ItineraryDay> days; // key: YYYY-MM-DD
  final bool editMode;
  final bool loading;

  const TripState({
    this.config,
    required this.days,
    this.editMode = false,
    this.loading = true,
  });

  TripState copyWith({
    TripConfig? config,
    Map<String, ItineraryDay>? days,
    bool? editMode,
    bool? loading,
  }) =>
      TripState(
        config: config ?? this.config,
        days: days ?? this.days,
        editMode: editMode ?? this.editMode,
        loading: loading ?? this.loading,
      );

  List<ItineraryDay> get sortedDays {
    final sorted = days.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class TripNotifier extends StateNotifier<TripState> {
  TripNotifier() : super(const TripState(days: {})) {
    _loadAll();
  }

  static const _prefsPrefix = 'itinerary_';

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Config
    TripConfig? config;
    try {
      final raw = await rootBundle.loadString('assets/data/config.json');
      config = TripConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}

    // Days
    final Map<String, ItineraryDay> days = {};
    for (final date in _tripDates) {
      // 1. Check SharedPreferences for edited version
      final saved = prefs.getString('$_prefsPrefix$date');
      if (saved != null) {
        try {
          final json = jsonDecode(saved) as Map<String, dynamic>;
          days[date] = ItineraryDay.fromJson(json, date);
          continue;
        } catch (_) {}
      }

      // 2. Fall back to asset
      try {
        final raw =
            await rootBundle.loadString('assets/data/itinerary/$date.json');
        final list = jsonDecode(raw) as List<dynamic>;
        if (list.isNotEmpty) {
          days[date] =
              ItineraryDay.fromJson(list[0] as Map<String, dynamic>, date);
        }
      } catch (_) {}
    }

    state = state.copyWith(config: config, days: days, loading: false);
  }

  // ── Edit mode ─────────────────────────────────────────────────────────────
  void toggleEditMode() {
    state = state.copyWith(editMode: !state.editMode);
  }

  void setEditMode(bool value) {
    state = state.copyWith(editMode: value);
  }

  // ── Item CRUD ─────────────────────────────────────────────────────────────
  Future<void> updateItem(String date, ItineraryItem updated) async {
    final day = state.days[date];
    if (day == null) return;

    final newItems =
        day.items.map((i) => i.id == updated.id ? updated : i).toList();
    await _saveDay(date, day.copyWith(items: newItems));
  }

  Future<void> addItem(String date, ItineraryItem item) async {
    final day = state.days[date];
    if (day == null) return;

    final newItems = [...day.items, item];
    await _saveDay(date, day.copyWith(items: newItems));
  }

  Future<void> deleteItem(String date, String itemId) async {
    final day = state.days[date];
    if (day == null) return;

    final newItems = day.items.where((i) => i.id != itemId).toList();
    await _saveDay(date, day.copyWith(items: newItems));
  }

  Future<void> reorderItems(
      String date, int oldIndex, int newIndex) async {
    final day = state.days[date];
    if (day == null) return;

    final items = [...day.items];
    final item = items.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    items.insert(insertAt, item);
    await _saveDay(date, day.copyWith(items: items));
  }

  // ── Persist ───────────────────────────────────────────────────────────────
  Future<void> _saveDay(String date, ItineraryDay day) async {
    final newDays = Map<String, ItineraryDay>.from(state.days);
    newDays[date] = day;
    state = state.copyWith(days: newDays);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_prefsPrefix$date', jsonEncode(day.toJson()));
  }

  Future<void> resetDayToAsset(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsPrefix$date');
    await _loadAll();
  }

  // ── New item template ─────────────────────────────────────────────────────
  ItineraryItem newItemTemplate(String date) {
    return ItineraryItem(
      id: '${date}_${DateTime.now().microsecondsSinceEpoch}',
      time: '',
      title: '',
      tag: ItemTag.sight,
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────
final tripProvider =
    StateNotifierProvider<TripNotifier, TripState>((ref) => TripNotifier());

final editModeProvider = Provider<bool>((ref) {
  return ref.watch(tripProvider).editMode;
});

final dayProvider = Provider.family<ItineraryDay?, String>((ref, date) {
  return ref.watch(tripProvider).days[date];
});
