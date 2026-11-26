import 'package:nerima_gomi/core/l10n/app_strings.dart';
import 'package:nerima_gomi/data/models/waste_category.dart';

enum RuleType { none, weekly, nthWeekday }

class CollectionRule {
  final RuleType type;

  /// Used when [type] is [RuleType.weekly]. Values: 1 (Mon) .. 7 (Sun).
  final List<int> weekdays;

  /// Used when [type] is [RuleType.nthWeekday]. Value: 1 (Mon) .. 7 (Sun).
  final int weekday;

  /// Used when [type] is [RuleType.nthWeekday]. Values: 1..5 (e.g. [1, 3]).
  final List<int> weeks;

  const CollectionRule({
    required this.type,
    this.weekdays = const [],
    this.weekday = DateTime.monday,
    this.weeks = const [],
  });

  const CollectionRule.none()
      : type = RuleType.none,
        weekdays = const [],
        weekday = DateTime.monday,
        weeks = const [];

  const CollectionRule.weekly(this.weekdays)
      : type = RuleType.weekly,
        weekday = DateTime.monday,
        weeks = const [];

  const CollectionRule.nthWeekday({
    required this.weekday,
    required this.weeks,
  })  : type = RuleType.nthWeekday,
        weekdays = const [];

  factory CollectionRule.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'none';
    switch (typeStr) {
      case 'weekly':
        return CollectionRule.weekly(
          (json['weekdays'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toInt())
              .toList(),
        );
      case 'nth_weekday':
        return CollectionRule.nthWeekday(
          weekday: (json['weekday'] as num?)?.toInt() ?? DateTime.monday,
          weeks: (json['weeks'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toInt())
              .toList(),
        );
      default:
        return const CollectionRule.none();
    }
  }

  Map<String, dynamic> toJson() {
    switch (type) {
      case RuleType.weekly:
        return {'type': 'weekly', 'weekdays': weekdays};
      case RuleType.nthWeekday:
        return {'type': 'nth_weekday', 'weekday': weekday, 'weeks': weeks};
      case RuleType.none:
        return {'type': 'none'};
    }
  }

  String describe(AppStrings s) {
    switch (type) {
      case RuleType.none:
        return s.ruleTypeNone;
      case RuleType.weekly:
        if (weekdays.isEmpty) return s.ruleTypeNone;
        final sorted = [...weekdays]..sort();
        final days = sorted.map(s.weekdayName).join('·');
        return '${s.ruleTypeWeekly} $days';
      case RuleType.nthWeekday:
        if (weeks.isEmpty) return s.ruleTypeNone;
        final sortedWeeks = [...weeks]..sort();
        final wText = sortedWeeks.map(s.nthWeekLabel).join('·');
        return '$wText ${s.weekdayName(weekday)}';
    }
  }
}

class AreaSchedule {
  final String id;
  final String nameKo;
  final String nameJa;
  final String reading;
  final Map<WasteCategory, CollectionRule> rules;
  final bool isCustom;

  const AreaSchedule({
    required this.id,
    required this.nameKo,
    required this.nameJa,
    required this.reading,
    required this.rules,
    this.isCustom = false,
  });

  String displayName(AppLanguage lang) =>
      lang == AppLanguage.ko ? nameKo : nameJa;

  AreaSchedule copyWith({
    String? id,
    String? nameKo,
    String? nameJa,
    String? reading,
    Map<WasteCategory, CollectionRule>? rules,
    bool? isCustom,
  }) {
    return AreaSchedule(
      id: id ?? this.id,
      nameKo: nameKo ?? this.nameKo,
      nameJa: nameJa ?? this.nameJa,
      reading: reading ?? this.reading,
      rules: rules ?? this.rules,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  factory AreaSchedule.fromJson(Map<String, dynamic> json) {
    final rawRules = json['rules'] as Map<String, dynamic>? ?? {};
    final parsedRules = <WasteCategory, CollectionRule>{};
    for (final entry in rawRules.entries) {
      parsedRules[WasteCategory.fromKey(entry.key)] =
          CollectionRule.fromJson(entry.value as Map<String, dynamic>);
    }
    return AreaSchedule(
      id: json['id'] as String? ?? 'custom',
      nameKo: json['nameKo'] as String? ?? '',
      nameJa: json['nameJa'] as String? ?? '',
      reading: json['reading'] as String? ?? '',
      rules: parsedRules,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKo': nameKo,
      'nameJa': nameJa,
      'reading': reading,
      'isCustom': isCustom,
      'rules': {
        for (final entry in rules.entries) entry.key.key: entry.value.toJson(),
      },
    };
  }
}

class HolidayConfig {
  /// Format: 'MM-DD', e.g. '12-31', '01-01'.
  final List<String> recurringMonthDays;

  /// Format: 'YYYY-MM-DD'.
  final List<String> specificDates;

  const HolidayConfig({
    this.recurringMonthDays = const ['12-31', '01-01', '01-02', '01-03'],
    this.specificDates = const [],
  });

  factory HolidayConfig.fromJson(Map<String, dynamic> json) {
    return HolidayConfig(
      recurringMonthDays:
          (json['recurringMonthDays'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      specificDates: (json['specificDates'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class WasteItem {
  final String id;
  final String nameKo;
  final String nameJa;
  final String reading;
  final List<String> keywords;
  final WasteCategory category;
  final String noteKo;
  final String noteJa;

  const WasteItem({
    required this.id,
    required this.nameKo,
    required this.nameJa,
    required this.reading,
    required this.keywords,
    required this.category,
    required this.noteKo,
    required this.noteJa,
  });

  String primaryName(AppLanguage lang) =>
      lang == AppLanguage.ko ? nameKo : nameJa;

  String secondaryName(AppLanguage lang) =>
      lang == AppLanguage.ko ? nameJa : nameKo;

  String note(AppLanguage lang) => lang == AppLanguage.ko ? noteKo : noteJa;

  factory WasteItem.fromJson(Map<String, dynamic> json) {
    return WasteItem(
      id: json['id'] as String,
      nameKo: json['nameKo'] as String,
      nameJa: json['nameJa'] as String,
      reading: json['reading'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      category: WasteCategory.fromKey(json['category'] as String),
      noteKo: json['noteKo'] as String? ?? '',
      noteJa: json['noteJa'] as String? ?? '',
    );
  }
}

/// Alarm-clock style local notification rule.
class AlarmRule {
  final String id;
  final int daysBefore; // 0 = same day, 1 = 1 day before, 2 = 2 days before
  final int hour; // 0..23
  final int minute; // 0..59
  /// Empty means all scheduled categories.
  final List<WasteCategory> categories;
  final bool enabled;

  const AlarmRule({
    required this.id,
    required this.daysBefore,
    required this.hour,
    required this.minute,
    this.categories = const [],
    this.enabled = true,
  });

  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  AlarmRule copyWith({
    String? id,
    int? daysBefore,
    int? hour,
    int? minute,
    List<WasteCategory>? categories,
    bool? enabled,
  }) {
    return AlarmRule(
      id: id ?? this.id,
      daysBefore: daysBefore ?? this.daysBefore,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      categories: categories ?? this.categories,
      enabled: enabled ?? this.enabled,
    );
  }

  factory AlarmRule.fromJson(Map<String, dynamic> json) {
    return AlarmRule(
      id: json['id'] as String,
      daysBefore: (json['daysBefore'] as num).toInt(),
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => WasteCategory.fromKey(e.toString()))
          .toList(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'daysBefore': daysBefore,
      'hour': hour,
      'minute': minute,
      'categories': categories.map((e) => e.key).toList(),
      'enabled': enabled,
    };
  }

  static List<AlarmRule> defaultRules() => const [
        AlarmRule(
          id: 'default_eve_2200',
          daysBefore: 1,
          hour: 22,
          minute: 0,
          categories: [],
          enabled: true,
        ),
        AlarmRule(
          id: 'default_morning_0715',
          daysBefore: 0,
          hour: 7,
          minute: 15,
          categories: [],
          enabled: true,
        ),
      ];
}
