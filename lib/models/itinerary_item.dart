import 'dart:convert';

enum ItemTag { transport, food, sight, hotel, shop, route, other }

extension ItemTagExt on ItemTag {
  String get label {
    switch (this) {
      case ItemTag.transport:
        return '交通';
      case ItemTag.food:
        return '餐飲';
      case ItemTag.sight:
        return '景點';
      case ItemTag.hotel:
        return '住宿';
      case ItemTag.shop:
        return '購物';
      case ItemTag.route:
        return '路線';
      case ItemTag.other:
        return '其他';
    }
  }

  static ItemTag fromString(String s) {
    switch (s.toLowerCase()) {
      case 'transport':
        return ItemTag.transport;
      case 'food':
        return ItemTag.food;
      case 'sight':
        return ItemTag.sight;
      case 'hotel':
        return ItemTag.hotel;
      case 'shop':
        return ItemTag.shop;
      case 'route':
        return ItemTag.route;
      default:
        return ItemTag.other;
    }
  }
}

class RouteInfo {
  final String mode; // drive, walk, transit, plane, ferry
  final String from;
  final String to;
  final int minutes;

  const RouteInfo({
    required this.mode,
    required this.from,
    required this.to,
    required this.minutes,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      mode: json['mode'] ?? 'drive',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      minutes: json['minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'from': from,
        'to': to,
        'minutes': minutes,
      };

  RouteInfo copyWith({
    String? mode,
    String? from,
    String? to,
    int? minutes,
  }) =>
      RouteInfo(
        mode: mode ?? this.mode,
        from: from ?? this.from,
        to: to ?? this.to,
        minutes: minutes ?? this.minutes,
      );
}

class ItineraryItem {
  final String id;
  final String time;
  final String title;
  final ItemTag tag;
  final String subtag;
  final String desc;
  final String detail;
  final String addr;
  final String mapcode;
  final String parking;
  final String hours;
  final String price;
  final String stay;
  final List<String> guide;
  final List<String> avoid;
  final List<Map<String, String>> links;
  final List<Map<String, dynamic>> menu;
  final List<Map<String, String>> reservations;
  final RouteInfo? route;
  final bool highlight;
  final bool reserved;

  const ItineraryItem({
    required this.id,
    required this.time,
    required this.title,
    required this.tag,
    this.subtag = '',
    this.desc = '',
    this.detail = '',
    this.addr = '',
    this.mapcode = '',
    this.parking = '',
    this.hours = '',
    this.price = '',
    this.stay = '',
    this.guide = const [],
    this.avoid = const [],
    this.links = const [],
    this.menu = const [],
    this.reservations = const [],
    this.route,
    this.highlight = false,
    this.reserved = false,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] ?? UniqueKey().toString(),
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      tag: ItemTagExt.fromString(json['tag'] ?? 'other'),
      subtag: json['subtag'] ?? '',
      desc: json['desc'] ?? '',
      detail: json['detail'] ?? '',
      addr: json['addr'] ?? '',
      mapcode: json['mapcode'] ?? '',
      parking: json['parking'] ?? '',
      hours: json['hours'] ?? '',
      price: json['price'] ?? '',
      stay: json['stay'] ?? '',
      guide: List<String>.from(json['guide'] ?? []),
      avoid: List<String>.from(json['avoid'] ?? []),
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      menu: (json['menu'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      reservations: (json['reservations'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      route: json['route'] != null ? RouteInfo.fromJson(json['route']) : null,
      highlight: json['highlight'] ?? false,
      reserved: json['reserved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'title': title,
        'tag': tag.name,
        'subtag': subtag,
        'desc': desc,
        'detail': detail,
        'addr': addr,
        'mapcode': mapcode,
        'parking': parking,
        'hours': hours,
        'price': price,
        'stay': stay,
        'guide': guide,
        'avoid': avoid,
        'links': links,
        'menu': menu,
        'reservations': reservations,
        if (route != null) 'route': route!.toJson(),
        'highlight': highlight,
        'reserved': reserved,
      };

  ItineraryItem copyWith({
    String? id,
    String? time,
    String? title,
    ItemTag? tag,
    String? subtag,
    String? desc,
    String? detail,
    String? addr,
    String? mapcode,
    String? parking,
    String? hours,
    String? price,
    String? stay,
    List<String>? guide,
    List<String>? avoid,
    List<Map<String, String>>? links,
    List<Map<String, dynamic>>? menu,
    List<Map<String, String>>? reservations,
    RouteInfo? route,
    bool? highlight,
    bool? reserved,
  }) =>
      ItineraryItem(
        id: id ?? this.id,
        time: time ?? this.time,
        title: title ?? this.title,
        tag: tag ?? this.tag,
        subtag: subtag ?? this.subtag,
        desc: desc ?? this.desc,
        detail: detail ?? this.detail,
        addr: addr ?? this.addr,
        mapcode: mapcode ?? this.mapcode,
        parking: parking ?? this.parking,
        hours: hours ?? this.hours,
        price: price ?? this.price,
        stay: stay ?? this.stay,
        guide: guide ?? this.guide,
        avoid: avoid ?? this.avoid,
        links: links ?? this.links,
        menu: menu ?? this.menu,
        reservations: reservations ?? this.reservations,
        route: route ?? this.route,
        highlight: highlight ?? this.highlight,
        reserved: reserved ?? this.reserved,
      );
}

class ItineraryDay {
  final String date; // YYYY-MM-DD
  final String displayDate; // MM/DD
  final String dayOfWeek; // 一～日
  final String loc;
  final String hotelId;
  final List<ItineraryItem> items;

  const ItineraryDay({
    required this.date,
    required this.displayDate,
    required this.dayOfWeek,
    required this.loc,
    required this.hotelId,
    required this.items,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json, String date) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return ItineraryDay(
      date: date,
      displayDate: json['date'] ?? '',
      dayOfWeek: json['day'] ?? '',
      loc: json['loc'] ?? '',
      hotelId: json['hotel_id'] ?? '',
      items: itemsJson
          .asMap()
          .entries
          .map((e) {
            final itemJson = Map<String, dynamic>.from(e.value as Map);
            if (!itemJson.containsKey('id') || (itemJson['id'] as String).isEmpty) {
              itemJson['id'] = '${date}_${e.key}';
            }
            return ItineraryItem.fromJson(itemJson);
          })
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': displayDate,
        'day': dayOfWeek,
        'loc': loc,
        'hotel_id': hotelId,
        'items': items.map((i) => i.toJson()).toList(),
      };

  ItineraryDay copyWith({
    String? date,
    String? displayDate,
    String? dayOfWeek,
    String? loc,
    String? hotelId,
    List<ItineraryItem>? items,
  }) =>
      ItineraryDay(
        date: date ?? this.date,
        displayDate: displayDate ?? this.displayDate,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        loc: loc ?? this.loc,
        hotelId: hotelId ?? this.hotelId,
        items: items ?? this.items,
      );
}

// Needed for UniqueKey in factory — but in Dart we use uuid or timestamp
class UniqueKey {
  @override
  String toString() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}
