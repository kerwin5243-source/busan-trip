class TripConfig {
  final String tripTitle;
  final String startDate;
  final String endDate;
  final int nights;
  final int days;
  final String mode;
  final List<String> members;
  final List<String> districts;
  final String defaultCurrency;
  final String language;

  const TripConfig({
    required this.tripTitle,
    required this.startDate,
    required this.endDate,
    required this.nights,
    required this.days,
    required this.mode,
    required this.members,
    this.districts = const [],
    required this.defaultCurrency,
    required this.language,
  });

  factory TripConfig.fromJson(Map<String, dynamic> json) {
    final dateRange = json['date_range'] as Map<String, dynamic>? ?? {};
    return TripConfig(
      tripTitle: json['trip_title'] ?? '',
      startDate: dateRange['start'] ?? '',
      endDate: dateRange['end'] ?? '',
      nights: json['nights'] ?? 0,
      days: json['days'] ?? 0,
      mode: json['mode'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      districts: List<String>.from(json['districts'] ?? []),
      defaultCurrency: json['default_currency'] ?? 'KRW',
      language: json['language'] ?? 'zh-TW',
    );
  }

  Map<String, dynamic> toJson() => {
        'trip_title': tripTitle,
        'date_range': {'start': startDate, 'end': endDate},
        'nights': nights,
        'days': days,
        'mode': mode,
        'members': members,
        'default_currency': defaultCurrency,
        'language': language,
        'data_version': 'v1.0',
      };
}
