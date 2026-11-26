import 'package:nerima_gomi/data/models/schedule_models.dart';
import 'package:nerima_gomi/data/models/waste_category.dart';

class NextCollectionInfo {
  final DateTime date;
  final List<WasteCategory> categories;
  final int daysFromBase;

  const NextCollectionInfo({
    required this.date,
    required this.categories,
    required this.daysFromBase,
  });
}

class ScheduledAlarmEvent {
  final int notificationId;
  final DateTime triggerTime;
  final DateTime collectionDate;
  final List<WasteCategory> categories;
  final AlarmRule rule;

  const ScheduledAlarmEvent({
    required this.notificationId,
    required this.triggerTime,
    required this.collectionDate,
    required this.categories,
    required this.rule,
  });
}

class ScheduleEngine {
  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static bool isHoliday(DateTime date, HolidayConfig holidays) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final mmdd = '$mm-$dd';
    if (holidays.recurringMonthDays.contains(mmdd)) {
      return true;
    }
    final ymd = '${date.year}-$mm-$dd';
    return holidays.specificDates.contains(ymd);
  }

  /// Returns 1..5 indicating which occurrence of this weekday it is in the month.
  static int nthWeekdayOfMonth(DateTime date) => ((date.day - 1) ~/ 7) + 1;

  static bool matchesRule(DateTime date, CollectionRule rule) {
    switch (rule.type) {
      case RuleType.none:
        return false;
      case RuleType.weekly:
        return rule.weekdays.contains(date.weekday);
      case RuleType.nthWeekday:
        if (date.weekday != rule.weekday) return false;
        return rule.weeks.contains(nthWeekdayOfMonth(date));
    }
  }

  static List<WasteCategory> getCategoriesForDate(
    DateTime date,
    AreaSchedule schedule,
    HolidayConfig holidays,
  ) {
    final normalized = dateOnly(date);
    if (isHoliday(normalized, holidays)) {
      return const [];
    }
    final result = <WasteCategory>[];
    for (final category in WasteCategory.scheduledCategories) {
      final rule = schedule.rules[category];
      if (rule != null && matchesRule(normalized, rule)) {
        result.add(category);
      }
    }
    return result;
  }

  /// Finds the next collection date on or after [fromDate] (optionally filtered by [category]).
  static NextCollectionInfo? findNextCollection(
    DateTime fromDate,
    AreaSchedule schedule,
    HolidayConfig holidays, {
    WasteCategory? category,
    bool includeFromDate = true,
    int maxLookaheadDays = 60,
  }) {
    final base = dateOnly(fromDate);
    final startOffset = includeFromDate ? 0 : 1;

    for (var i = startOffset; i <= maxLookaheadDays; i++) {
      final candidate = base.add(Duration(days: i));
      final categories = getCategoriesForDate(candidate, schedule, holidays);
      if (categories.isEmpty) continue;
      if (category != null) {
        if (categories.contains(category)) {
          return NextCollectionInfo(
            date: candidate,
            categories: [category],
            daysFromBase: i,
          );
        }
      } else {
        return NextCollectionInfo(
          date: candidate,
          categories: categories,
          daysFromBase: i,
        );
      }
    }
    return null;
  }

  /// Generates all upcoming local alarm trigger events for the next [horizonDays].
  static List<ScheduledAlarmEvent> buildUpcomingAlarms({
    required DateTime now,
    required AreaSchedule schedule,
    required HolidayConfig holidays,
    required List<AlarmRule> rules,
    int horizonDays = 35,
  }) {
    final enabledRules = rules.where((r) => r.enabled).toList();
    if (enabledRules.isEmpty) return const [];

    final today = dateOnly(now);
    final events = <ScheduledAlarmEvent>[];

    for (var dayOffset = 0; dayOffset <= horizonDays; dayOffset++) {
      final collectionDate = today.add(Duration(days: dayOffset));
      final dayCategories =
          getCategoriesForDate(collectionDate, schedule, holidays);
      if (dayCategories.isEmpty) continue;

      for (var ruleIndex = 0; ruleIndex < enabledRules.length; ruleIndex++) {
        final rule = enabledRules[ruleIndex];
        final matchingCategories = rule.categories.isEmpty
            ? dayCategories
            : dayCategories.where(rule.categories.contains).toList();
        if (matchingCategories.isEmpty) continue;

        final triggerDay =
            collectionDate.subtract(Duration(days: rule.daysBefore));
        final triggerTime = DateTime(
          triggerDay.year,
          triggerDay.month,
          triggerDay.day,
          rule.hour,
          rule.minute,
        );

        if (!triggerTime.isAfter(now)) continue;

        // Stable deterministic notification ID
        final dateCode =
            collectionDate.month * 100 + collectionDate.day; // e.g. 1126
        final id = (ruleIndex + 1) * 10000 + dateCode;

        events.add(
          ScheduledAlarmEvent(
            notificationId: id,
            triggerTime: triggerTime,
            collectionDate: collectionDate,
            categories: matchingCategories,
            rule: rule,
          ),
        );
      }
    }

    events.sort((a, b) => a.triggerTime.compareTo(b.triggerTime));
    return events;
  }

  /// Flexible bilingual search normalization:
  /// - Lowercases ASCII
  /// - Strips whitespace & middle dots
  /// - Converts Japanese Katakana to Hiragana so both scripts match seamlessly
  static String normalizeQuery(String input) {
    final buffer = StringBuffer();
    final trimmed = input.toLowerCase();
    for (final rune in trimmed.runes) {
      // Ignore whitespace and common separators
      if (rune == 0x20 ||
          rune == 0x3000 ||
          rune == 0x00B7 ||
          rune == 0x30FB ||
          rune == 0x2D) {
        continue;
      }
      // Convert Katakana (ァ..ヶ: 0x30A1..0x30F6) to Hiragana (ぁ..ゖ: 0x3041..0x3096)
      if (rune >= 0x30A1 && rune <= 0x30F6) {
        buffer.writeCharCode(rune - 0x60);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static List<WasteItem> searchItems(
    List<WasteItem> items, {
    required String query,
    WasteCategory? categoryFilter,
  }) {
    final normalizedQuery = normalizeQuery(query);
    return items.where((item) {
      if (categoryFilter != null && item.category != categoryFilter) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        item.nameKo,
        item.nameJa,
        item.reading,
        item.noteKo,
        item.noteJa,
        ...item.keywords,
      ].map(normalizeQuery);

      return haystack.any((text) => text.contains(normalizedQuery));
    }).toList();
  }
}
