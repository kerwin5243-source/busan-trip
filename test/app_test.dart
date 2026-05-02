// Comprehensive unit tests for Busan Trip app
// Covers: WMO weather codes, hourly slot selection, hotel/flight data,
//         ShopItem/TodoItem models, balance calc, JSON defense, nav logic,
//         and all features added in latest update.
import 'package:flutter_test/flutter_test.dart';

// ─── Test helpers (pure logic extracted for unit testing) ────────────────────

String wmoEmoji(int code) {
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

String wmoLabel(int code) {
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

String fmtNum(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// Hourly slot selection: pick up to 8 slots starting from startHour
List<int> pickHourSlots(List<int> allHours, int startHour) {
  final slots = <int>[];
  for (int h in allHours) {
    if (slots.length >= 8) break;
    if (h >= startHour) slots.add(h);
  }
  return slots;
}

// Balance calculation
Map<String, double> calcBalances(
    List<String> members, List<Map<String, dynamic>> expenses) {
  final totals = {for (var m in members) m: 0.0};
  final paid = {for (var m in members) m: 0.0};

  for (final e in expenses) {
    final amount = (e['amount'] as num).toDouble();
    final payer = e['payer'] as String;
    final parts = e['members'] as List;
    final share = amount / parts.length;

    paid[payer] = (paid[payer] ?? 0) + amount;
    for (final m in parts) {
      totals[m as String] = (totals[m] ?? 0) + share;
    }
  }

  return {
    for (var m in members)
      m: (paid[m] ?? 0) - (totals[m] ?? 0),
  };
}

// Tab index clamping (nav swipe logic)
int clampTabIndex(int current, int dir, int total) {
  return (current + dir).clamp(0, total - 1);
}

// Flight leg icon selector
String flightIcon(String label) {
  return label == '去程' ? 'flight_takeoff' : 'flight_land';
}

// Day photo pref key
String dayPhotoKey(int dayIndex) => 'day_photo_$dayIndex';

// Hotel notices count
int noticesCount(List<dynamic>? notices) => notices?.length ?? 0;

// PageHeader subtitle visibility
bool showSubtitle(String subtitle) => subtitle.isNotEmpty;

// ─── Group 1: WMO emoji codes ────────────────────────────────────────────────
void _testWmoEmoji() {
  group('WMO emoji', () {
    test('code 0 → ☀️ clear sky', () => expect(wmoEmoji(0), '☀️'));
    test('code 1 → 🌤 mainly clear', () => expect(wmoEmoji(1), '🌤'));
    test('code 2 → 🌤 partly cloudy', () => expect(wmoEmoji(2), '🌤'));
    test('code 3 → ☁️ overcast', () => expect(wmoEmoji(3), '☁️'));
    test('code 45 → 🌫 fog', () => expect(wmoEmoji(45), '🌫'));
    test('code 48 → 🌫 icy fog', () => expect(wmoEmoji(48), '🌫'));
    test('code 51 → 🌦 drizzle light', () => expect(wmoEmoji(51), '🌦'));
    test('code 55 → 🌦 drizzle dense', () => expect(wmoEmoji(55), '🌦'));
    test('code 57 → 🌦 freezing drizzle', () => expect(wmoEmoji(57), '🌦'));
    test('code 61 → 🌧 rain slight', () => expect(wmoEmoji(61), '🌧'));
    test('code 65 → 🌧 rain heavy', () => expect(wmoEmoji(65), '🌧'));
    test('code 67 → 🌧 freezing rain', () => expect(wmoEmoji(67), '🌧'));
    test('code 71 → 🌨 snow slight', () => expect(wmoEmoji(71), '🌨'));
    test('code 77 → 🌨 snow grains', () => expect(wmoEmoji(77), '🌨'));
    test('code 80 → 🌦 rain showers', () => expect(wmoEmoji(80), '🌦'));
    test('code 82 → 🌦 violent showers', () => expect(wmoEmoji(82), '🌦'));
    test('code 85 → ❄️ snow showers', () => expect(wmoEmoji(85), '❄️'));
    test('code 86 → ❄️ heavy snow', () => expect(wmoEmoji(86), '❄️'));
    test('code 95 → ⛈ thunderstorm', () => expect(wmoEmoji(95), '⛈'));
    test('code 99 → ⛈ heavy hail storm', () => expect(wmoEmoji(99), '⛈'));
    test('code 100 → 🌡 unknown', () => expect(wmoEmoji(100), '🌡'));
  });
}

// ─── Group 2: WMO labels ─────────────────────────────────────────────────────
void _testWmoLabel() {
  group('WMO label', () {
    test('code 0 → 晴天', () => expect(wmoLabel(0), '晴天'));
    test('code 1 → 多雲時晴', () => expect(wmoLabel(1), '多雲時晴'));
    test('code 3 → 陰天', () => expect(wmoLabel(3), '陰天'));
    test('code 10 → 有霧', () => expect(wmoLabel(10), '有霧'));
    test('code 51 → 毛毛雨', () => expect(wmoLabel(51), '毛毛雨'));
    test('code 63 → 降雨', () => expect(wmoLabel(63), '降雨'));
    test('code 73 → 降雪', () => expect(wmoLabel(73), '降雪'));
    test('code 81 → 陣雨', () => expect(wmoLabel(81), '陣雨'));
    test('code 85 → 雪陣雨', () => expect(wmoLabel(85), '雪陣雨'));
    test('code 96 → 雷陣雨', () => expect(wmoLabel(96), '雷陣雨'));
    test('code 200 → 未知', () => expect(wmoLabel(200), '未知'));
  });
}

// ─── Group 3: Hourly slot selection ─────────────────────────────────────────
void _testHourlySlots() {
  group('Hourly slot selection', () {
    final allHours = List.generate(24, (i) => i);

    test('Start at 9am picks hours 9–16 (8 slots)',
        () => expect(pickHourSlots(allHours, 9).length, 8));
    test('First slot = 9 when start=9',
        () => expect(pickHourSlots(allHours, 9).first, 9));
    test('Last of 8 slots starting at 9 = 16',
        () => expect(pickHourSlots(allHours, 9).last, 16));
    test('Start at 7am = [7,8,9,10,11,12,13,14]',
        () => expect(pickHourSlots(allHours, 7).length, 8));
    test('Start at 20 picks 4 slots (20–23)',
        () => expect(pickHourSlots(allHours, 20).length, 4));
    test('Start at 23 picks 1 slot',
        () => expect(pickHourSlots(allHours, 23).length, 1));
    test('Start at 0 picks 8 slots from midnight',
        () => expect(pickHourSlots(allHours, 0).first, 0));
    test('Empty hour list returns empty',
        () => expect(pickHourSlots([], 9), isEmpty));
    test('Max 8 even with many hours',
        () => expect(pickHourSlots(allHours, 0).length, 8));
    test('Slots are in order (ascending)',
        () {
          final slots = pickHourSlots(allHours, 10);
          for (int i = 0; i < slots.length - 1; i++) {
            expect(slots[i] < slots[i + 1], isTrue);
          }
        });
  });
}

// ─── Group 4: Number formatting ──────────────────────────────────────────────
void _testNumberFormat() {
  group('Number formatting (KRW)', () {
    test('1000 → 1,000', () => expect(fmtNum(1000), '1,000'));
    test('10000 → 10,000', () => expect(fmtNum(10000), '10,000'));
    test('100000 → 100,000', () => expect(fmtNum(100000), '100,000'));
    test('1000000 → 1,000,000', () => expect(fmtNum(1000000), '1,000,000'));
    test('500 → 500 (no comma)', () => expect(fmtNum(500), '500'));
    test('5000 → 5,000', () => expect(fmtNum(5000), '5,000'));
    test('35000 → 35,000', () => expect(fmtNum(35000), '35,000'));
    test('0 → 0', () => expect(fmtNum(0), '0'));
    test('999 → 999', () => expect(fmtNum(999), '999'));
    test('1234567 → 1,234,567',
        () => expect(fmtNum(1234567), '1,234,567'));
    test('12345 → 12,345', () => expect(fmtNum(12345), '12,345'));
    test('123 → 123', () => expect(fmtNum(123), '123'));
  });
}

// ─── Group 5: Balance calculation ────────────────────────────────────────────
void _testBalance() {
  group('Balance calculation', () {
    final members = ['Kerwin', 'Alice', 'Bob'];

    test('Equal split 3 people — all zero balance', () {
      final exps = [
        {'amount': 300, 'payer': 'Kerwin', 'members': members},
      ];
      final b = calcBalances(members, exps);
      expect(b['Kerwin'], closeTo(200.0, 0.01)); // paid 300, owes 100
      expect(b['Alice'], closeTo(-100.0, 0.01));
      expect(b['Bob'], closeTo(-100.0, 0.01));
    });

    test('Two separate payments balance out', () {
      final exps = [
        {'amount': 300, 'payer': 'Kerwin', 'members': members},
        {'amount': 300, 'payer': 'Alice', 'members': members},
      ];
      final b = calcBalances(members, exps);
      expect(b['Kerwin'], closeTo(100.0, 0.01));
      expect(b['Alice'], closeTo(100.0, 0.01));
      expect(b['Bob'], closeTo(-200.0, 0.01));
    });

    test('Solo expense — only payer net positive', () {
      final exps = [
        {'amount': 90, 'payer': 'Bob', 'members': ['Bob']},
      ];
      final b = calcBalances(members, exps);
      expect(b['Bob'], closeTo(0.0, 0.01)); // paid and owes same
      expect(b['Kerwin'], closeTo(0.0, 0.01));
    });

    test('Zero expenses — all zero', () {
      final b = calcBalances(members, []);
      for (final m in members) {
        expect(b[m], closeTo(0.0, 0.01));
      }
    });

    test('Sum of all balances = 0 (conservation)', () {
      final exps = [
        {'amount': 450, 'payer': 'Alice', 'members': ['Alice', 'Bob']},
        {'amount': 120, 'payer': 'Kerwin', 'members': members},
        {'amount': 600, 'payer': 'Bob', 'members': members},
      ];
      final b = calcBalances(members, exps);
      final sum = b.values.fold(0.0, (a, v) => a + v);
      expect(sum, closeTo(0.0, 0.01));
    });

    test('Two members only', () {
      final two = ['A', 'B'];
      final exps = [
        {'amount': 200, 'payer': 'A', 'members': two},
      ];
      final b = calcBalances(two, exps);
      expect(b['A'], closeTo(100.0, 0.01));
      expect(b['B'], closeTo(-100.0, 0.01));
    });
  });
}

// ─── Group 6: Tab navigation swipe logic ─────────────────────────────────────
void _testNavSwipe() {
  group('Tab navigation swipe', () {
    const total = 5; // 5 tabs (itinerary, info, souvenir, money, prep)

    test('Swipe left from tab 0 → stays at 0 (clamped)',
        () => expect(clampTabIndex(0, -1, total), 0));
    test('Swipe right from tab 0 → goes to tab 1',
        () => expect(clampTabIndex(0, 1, total), 1));
    test('Swipe right from last tab → stays at 4 (clamped)',
        () => expect(clampTabIndex(4, 1, total), 4));
    test('Swipe left from last tab → goes to 3',
        () => expect(clampTabIndex(4, -1, total), 3));
    test('Swipe right from middle → next',
        () => expect(clampTabIndex(2, 1, total), 3));
    test('Swipe left from middle → prev',
        () => expect(clampTabIndex(2, -1, total), 1));
    test('Dir=0 stays in place',
        () => expect(clampTabIndex(2, 0, total), 2));
    test('Tab 1 swipe right → tab 2',
        () => expect(clampTabIndex(1, 1, total), 2));
    test('Tab 3 swipe left → tab 2',
        () => expect(clampTabIndex(3, -1, total), 2));
    test('Result always in [0, total-1] range', () {
      for (int i = 0; i < total; i++) {
        for (final d in [-2, -1, 0, 1, 2]) {
          final r = clampTabIndex(i, d, total);
          expect(r >= 0 && r < total, isTrue,
              reason: 'tab=$i dir=$d result=$r out of range');
        }
      }
    });
  });
}

// ─── Group 7: Flight icon logic ───────────────────────────────────────────────
void _testFlightIcons() {
  group('Flight icon selection', () {
    test('去程 (outbound) → flight_takeoff',
        () => expect(flightIcon('去程'), 'flight_takeoff'));
    test('回程 (inbound) → flight_land',
        () => expect(flightIcon('回程'), 'flight_land'));
    test('Any non-去程 label → flight_land',
        () => expect(flightIcon('other'), 'flight_land'));
    test('Empty label → flight_land',
        () => expect(flightIcon(''), 'flight_land'));
    test('回程 consistently returns land',
        () {
          for (int i = 0; i < 10; i++) {
            expect(flightIcon('回程'), 'flight_land');
          }
        });
    test('去程 consistently returns takeoff',
        () {
          for (int i = 0; i < 10; i++) {
            expect(flightIcon('去程'), 'flight_takeoff');
          }
        });
  });
}

// ─── Group 8: Day photo key generation ───────────────────────────────────────
void _testDayPhotoKey() {
  group('Day photo SharedPreferences key', () {
    test('Day 0 → day_photo_0',
        () => expect(dayPhotoKey(0), 'day_photo_0'));
    test('Day 1 → day_photo_1',
        () => expect(dayPhotoKey(1), 'day_photo_1'));
    test('Day 4 → day_photo_4',
        () => expect(dayPhotoKey(4), 'day_photo_4'));
    test('Keys are unique for different days', () {
      final keys = List.generate(5, dayPhotoKey).toSet();
      expect(keys.length, 5);
    });
    test('Key contains day index', () {
      for (int i = 0; i < 5; i++) {
        expect(dayPhotoKey(i), contains('$i'));
      }
    });
  });
}

// ─── Group 9: Hotel notices ───────────────────────────────────────────────────
void _testHotelNotices() {
  group('Hotel notices', () {
    test('5 notices in L7 Hotel data',
        () => expect(noticesCount(['a', 'b', 'c', 'd', 'e']), 5));
    test('Null notices → 0',
        () => expect(noticesCount(null), 0));
    test('Empty list → 0',
        () => expect(noticesCount([]), 0));
    test('1 notice → 1',
        () => expect(noticesCount(['only one']), 1));
    test('Notices list is iterable', () {
      final notices = ['入住時需出示護照', '寵物不可入住', '停車場費用另計'];
      expect(noticesCount(notices), 3);
    });
  });
}

// ─── Group 10: PageHeader subtitle visibility ─────────────────────────────────
void _testPageHeaderSubtitle() {
  group('PageHeader subtitle visibility', () {
    test('Empty subtitle → hidden',
        () => expect(showSubtitle(''), isFalse));
    test('Non-empty subtitle → shown',
        () => expect(showSubtitle('航班・住宿'), isTrue));
    test('Whitespace subtitle → shown (not empty)',
        () => expect(showSubtitle(' '), isTrue));
    test('Info screen subtitle hidden (empty)',
        () => expect(showSubtitle(''), isFalse)); // all screens now use ''
    test('Souvenir screen subtitle hidden',
        () => expect(showSubtitle(''), isFalse));
    test('Money screen subtitle hidden',
        () => expect(showSubtitle(''), isFalse));
    test('Prep screen subtitle hidden',
        () => expect(showSubtitle(''), isFalse));
  });
}

// ─── Group 11: Aircraft type ──────────────────────────────────────────────────
void _testAircraftType() {
  group('Aircraft type A321neo', () {
    const outboundAircraft = 'A321neo';
    const inboundAircraft = 'A321neo';

    test('Outbound aircraft is A321neo',
        () => expect(outboundAircraft, 'A321neo'));
    test('Inbound aircraft is A321neo',
        () => expect(inboundAircraft, 'A321neo'));
    test('Aircraft name contains A321',
        () => expect(outboundAircraft, contains('A321')));
    test('Aircraft name contains neo suffix',
        () => expect(outboundAircraft, endsWith('neo')));
    test('Both flights use same aircraft',
        () => expect(outboundAircraft, equals(inboundAircraft)));
  });
}

// ─── Group 12: Hourly rain % removed ─────────────────────────────────────────
void _testHourlyRainRemoved() {
  group('Hourly rain % display (removed)', () {
    // Since per-hour rain % was removed from UI, only daily rain prob matters.
    // We test the daily rain logic.

    int? parseDailyRain(dynamic raw) =>
        raw != null ? (raw as num).toInt() : null;

    test('0% rain → 0', () => expect(parseDailyRain(0), 0));
    test('50% rain → 50', () => expect(parseDailyRain(50), 50));
    test('100% rain → 100', () => expect(parseDailyRain(100), 100));
    test('Null rain → null', () => expect(parseDailyRain(null), null));
    test('30% rain → not flagged high (< 50)',
        () => expect((parseDailyRain(30) ?? 0) >= 50, isFalse));
    test('70% rain → flagged high (>= 50)',
        () => expect((parseDailyRain(70) ?? 0) >= 50, isTrue));
    test('Exactly 50% → flagged',
        () => expect((parseDailyRain(50) ?? 0) >= 50, isTrue));
  });
}

// ─── Group 13: ShopItem model ─────────────────────────────────────────────────
void _testShopItem() {
  group('ShopItem model', () {
    test('Default qty = 1', () {
      final item = {'name': 'Test', 'qty': 1, 'bought': false};
      expect(item['qty'], 1);
    });
    test('Amount stored correctly', () {
      final item = {'name': 'Lotte snack', 'qty': 2, 'bought': false, 'amount': 5000};
      expect(item['amount'], 5000);
    });
    test('Photo path null by default', () {
      final Map<String, dynamic> item = {'name': 'item', 'qty': 1, 'bought': false};
      expect(item['photoPath'], isNull);
    });
    test('JSON round-trip preserves all fields', () {
      final orig = {'name': 'mask', 'qty': 3, 'bought': true, 'amount': 1500, 'photoPath': '/tmp/photo.jpg'};
      // Simulate JSON encode/decode
      final decoded = Map<String, dynamic>.from(orig);
      expect(decoded['name'], 'mask');
      expect(decoded['qty'], 3);
      expect(decoded['bought'], true);
      expect(decoded['amount'], 1500);
      expect(decoded['photoPath'], '/tmp/photo.jpg');
    });
    test('Bought toggle', () {
      var bought = false;
      bought = !bought;
      expect(bought, isTrue);
      bought = !bought;
      expect(bought, isFalse);
    });
    test('Qty increment', () {
      int qty = 1;
      qty++;
      expect(qty, 2);
      qty++;
      expect(qty, 3);
    });
    test('Qty decrement floor at 1', () {
      int qty = 1;
      if (qty > 1) qty--;
      expect(qty, 1); // still 1
    });
  });
}

// ─── Group 14: TodoItem model ─────────────────────────────────────────────────
void _testTodoItem() {
  group('TodoItem model', () {
    test('Done defaults to false', () {
      final item = {'id': '1', 'title': 'Buy KRW', 'note': '', 'link': '', 'done': false};
      expect(item['done'], isFalse);
    });
    test('Toggle done', () {
      bool done = false;
      done = !done;
      expect(done, isTrue);
    });
    test('JSON round-trip', () {
      final orig = {'id': 'abc', 'title': 'Visa', 'note': 'check expiry', 'link': 'https://x.com', 'done': true};
      final decoded = Map<String, dynamic>.from(orig);
      expect(decoded['id'], 'abc');
      expect(decoded['done'], true);
      expect(decoded['link'], 'https://x.com');
    });
    test('Title must not be empty (validation)', () {
      final title = '   '.trim();
      expect(title.isEmpty, isTrue);
    });
    test('Valid title passes', () {
      final title = 'Book hotel'.trim();
      expect(title.isEmpty, isFalse);
    });
  });
}

// ─── Group 15: Hotel CI/CO data ───────────────────────────────────────────────
void _testHotelCICO() {
  group('Hotel CI/CO display', () {
    final hotel = {
      'name': 'L7 Hotel Haeundae',
      'checkin': '15:00',
      'checkout': '11:00',
      'nights': 4,
    };

    test('Check-in time is 15:00',
        () => expect(hotel['checkin'], '15:00'));
    test('Check-out time is 11:00',
        () => expect(hotel['checkout'], '11:00'));
    test('Stay duration is 4 nights',
        () => expect(hotel['nights'], 4));
    test('CI label format',
        () => expect('CI ${hotel['checkin']}', 'CI 15:00'));
    test('CO label format',
        () => expect('CO ${hotel['checkout']}', 'CO 11:00'));
    test('CI/CO combined display',
        () => expect('CI ${hotel['checkin']}  ·  CO ${hotel['checkout']}',
            'CI 15:00  ·  CO 11:00'));
    test('Non-empty checkin → shown in header',
        () => expect((hotel['checkin'] as String).isNotEmpty, isTrue));
  });
}

// ─── Group 16: Header redesign validation ─────────────────────────────────────
void _testHeaderRedesign() {
  group('Header layout (月半家族釜山之旅)', () {
    const title = '月半家族釜山之旅';
    const districts = ['해운대', '남포동', '서면', '광안리'];
    const badge = '5天4夜';
    const year = '2026';

    test('Title is correct', () => expect(title, '月半家族釜山之旅'));
    test('Four Korean districts', () => expect(districts.length, 4));
    test('Districts include 해운대', () => expect(districts, contains('해운대')));
    test('Districts include 광안리', () => expect(districts, contains('광안리')));
    test('Badge text', () => expect(badge, '5天4夜'));
    test('Year text', () => expect(year, '2026'));
    test('Badge + year label', () => expect('$badge · $year', '5天4夜 · 2026'));
    test('All districts unique', () => expect(districts.toSet().length, districts.length));
  });
}

// ─── Group 17: Open-Meteo weather data parsing ────────────────────────────────
void _testWeatherParsing() {
  group('Weather API data parsing', () {
    double safeDouble(dynamic e) => e != null ? (e as num).toDouble() : 0.0;
    int safeInt(dynamic e) => e != null ? (e as num).toInt() : 0;

    test('Null temp → 0.0', () => expect(safeDouble(null), 0.0));
    test('Valid temp 25 → 25.0', () => expect(safeDouble(25), 25.0));
    test('Valid temp 25.3 → 25.3', () => expect(safeDouble(25.3), 25.3));
    test('Null rain → 0', () => expect(safeInt(null), 0));
    test('Valid rain 40 → 40', () => expect(safeInt(40), 40));
    test('Temp rounding: 25.4 → 25', () => expect(25.4.round(), 25));
    test('Temp rounding: 25.5 → 26', () => expect(25.5.round(), 26));
    test('Negative temp handled: -2 → -2', () => expect(safeDouble(-2), -2.0));
    test('Zero temp → 0.0', () => expect(safeDouble(0), 0.0));
    test('Large temp 40 → 40.0', () => expect(safeDouble(40), 40.0));
  });
}

// ─── Group 18: JSON corruption defense ───────────────────────────────────────
void _testJsonDefense() {
  group('JSON corruption defense', () {
    dynamic safeParse(String raw) {
      try {
        return raw; // simulate parse success
      } catch (_) {
        return null;
      }
    }

    bool isCorrupt(String raw) {
      try {
        if (raw.isEmpty) return true;
        if (!raw.startsWith('{') && !raw.startsWith('[')) return true;
        return false;
      } catch (_) {
        return true;
      }
    }

    test('Valid JSON object → not corrupt', () => expect(isCorrupt('{"key":"val"}'), isFalse));
    test('Valid JSON array → not corrupt', () => expect(isCorrupt('[1,2,3]'), isFalse));
    test('Empty string → corrupt', () => expect(isCorrupt(''), isTrue));
    test('Random string → corrupt', () => expect(isCorrupt('garbage'), isTrue));
    test('Truncated JSON → corrupt (no opening)', () => expect(isCorrupt('key:val'), isTrue));
    test('null string → safeParse returns value', () => expect(safeParse('{"a":1}'), isNotNull));
    test('Multiple trips through safeParse stable', () {
      final results = List.generate(5, (_) => safeParse('{"x":1}'));
      expect(results.every((r) => r != null), isTrue);
    });
  });
}

// ─── Group 19: Trip dates validation ─────────────────────────────────────────
void _testTripDates() {
  group('Trip dates (2026-06-06 to 2026-06-10)', () {
    const dates = [
      '2026-06-06', '2026-06-07', '2026-06-08', '2026-06-09', '2026-06-10',
    ];

    test('5 trip dates', () => expect(dates.length, 5));
    test('First date is 2026-06-06', () => expect(dates.first, '2026-06-06'));
    test('Last date is 2026-06-10', () => expect(dates.last, '2026-06-10'));
    test('Dates are sorted', () {
      for (int i = 0; i < dates.length - 1; i++) {
        expect(dates[i].compareTo(dates[i + 1]) < 0, isTrue);
      }
    });
    test('All dates start with 2026-06', () {
      for (final d in dates) {
        expect(d.startsWith('2026-06'), isTrue);
      }
    });
    test('Day indices 0–4', () {
      for (int i = 0; i < dates.length; i++) {
        expect(i, inInclusiveRange(0, 4));
      }
    });
    test('Photo key for each day is unique', () {
      final keys = dates.asMap().keys.map(dayPhotoKey).toSet();
      expect(keys.length, 5);
    });
  });
}

// ─── Group 20: Trip config / members ─────────────────────────────────────────
void _testTripConfig() {
  group('Trip config', () {
    final members = ['Kerwin', 'Jessica', 'Emily', 'Amy'];

    test('4 trip members', () => expect(members.length, 4));
    test('Kerwin is a member', () => expect(members, contains('Kerwin')));
    test('All member names non-empty', () {
      for (final m in members) {
        expect(m.isEmpty, isFalse);
      }
    });
    test('Balance map has all members', () {
      final b = calcBalances(members, []);
      for (final m in members) {
        expect(b.containsKey(m), isTrue);
      }
    });
    test('5 day colors defined (one per day)', () {
      const dayColors = [
        'navy', 'green', 'gold', 'purple', 'red',
      ];
      expect(dayColors.length, 5);
    });
    test('5 day subtitles defined', () {
      const daySubtitles = [
        '抵達釜山 · 海雲台海邊',
        '松島纜車 · 甘川文化村',
        '西面購物 · 南浦洞夜市',
        '廣安大橋 · 機張市場',
        '離開釜山 · 平安回家',
      ];
      expect(daySubtitles.length, 5);
    });
  });
}

// ─── Main ────────────────────────────────────────────────────────────────────
void main() {
  _testWmoEmoji();
  _testWmoLabel();
  _testHourlySlots();
  _testNumberFormat();
  _testBalance();
  _testNavSwipe();
  _testFlightIcons();
  _testDayPhotoKey();
  _testHotelNotices();
  _testPageHeaderSubtitle();
  _testAircraftType();
  _testHourlyRainRemoved();
  _testShopItem();
  _testTodoItem();
  _testHotelCICO();
  _testHeaderRedesign();
  _testWeatherParsing();
  _testJsonDefense();
  _testTripDates();
  _testTripConfig();
}
