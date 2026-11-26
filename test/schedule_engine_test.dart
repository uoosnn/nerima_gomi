import 'package:flutter_test/flutter_test.dart';
import 'package:nerima_gomi/data/models/schedule_models.dart';
import 'package:nerima_gomi/data/models/waste_category.dart';
import 'package:nerima_gomi/data/services/schedule_engine.dart';

void main() {
  const sampleSchedule = AreaSchedule(
    id: 'nerima_1',
    nameKo: '네리마 1초메',
    nameJa: '練馬 1丁目',
    reading: 'ねりま1ちょうめ',
    rules: {
      WasteCategory.burnable:
          CollectionRule.weekly([DateTime.monday, DateTime.thursday]),
      WasteCategory.nonBurnable: CollectionRule.nthWeekday(
        weekday: DateTime.wednesday,
        weeks: [1, 3],
      ),
      WasteCategory.plastic: CollectionRule.weekly([DateTime.tuesday]),
      WasteCategory.paper: CollectionRule.weekly([DateTime.friday]),
      WasteCategory.bottleCanPet: CollectionRule.weekly([DateTime.friday]),
    },
  );

  const holidays = HolidayConfig(
    recurringMonthDays: ['12-31', '01-01', '01-02', '01-03'],
  );

  group('ScheduleEngine', () {
    test('calculates weekly and nth-weekday collections accurately', () {
      // 2026-11-04 is 1st Wednesday of Nov 2026
      final firstWed = DateTime(2026, 11, 4);
      expect(ScheduleEngine.nthWeekdayOfMonth(firstWed), 1);
      expect(
        ScheduleEngine.getCategoriesForDate(firstWed, sampleSchedule, holidays),
        [WasteCategory.nonBurnable],
      );

      // 2026-11-11 is 2nd Wednesday (not in [1, 3])
      final secondWed = DateTime(2026, 11, 11);
      expect(ScheduleEngine.nthWeekdayOfMonth(secondWed), 2);
      expect(
        ScheduleEngine.getCategoriesForDate(secondWed, sampleSchedule, holidays),
        isEmpty,
      );

      // 2026-11-06 is Friday -> paper + bottleCanPet
      final friday = DateTime(2026, 11, 6);
      expect(
        ScheduleEngine.getCategoriesForDate(friday, sampleSchedule, holidays),
        [WasteCategory.paper, WasteCategory.bottleCanPet],
      );
    });

    test('skips year-end holiday dates', () {
      final newYear = DateTime(2027, 1, 1); // Friday
      expect(
        ScheduleEngine.getCategoriesForDate(newYear, sampleSchedule, holidays),
        isEmpty,
      );
    });

    test('builds upcoming custom alarm events (e.g. 1 day before at 22:00)', () {
      final now = DateTime(2026, 11, 1, 10, 0); // Sunday 10:00
      final rules = [
        const AlarmRule(
          id: 'eve_2200',
          daysBefore: 1,
          hour: 22,
          minute: 0,
          categories: [],
          enabled: true,
        ),
      ];

      final events = ScheduleEngine.buildUpcomingAlarms(
        now: now,
        schedule: sampleSchedule,
        holidays: holidays,
        rules: rules,
        horizonDays: 5,
      );

      expect(events, isNotEmpty);
      // Monday 2026-11-02 burnable -> alarm triggers Sunday 2026-11-01 at 22:00
      expect(events.first.collectionDate, DateTime(2026, 11, 2));
      expect(events.first.triggerTime, DateTime(2026, 11, 1, 22, 0));
      expect(events.first.categories, [WasteCategory.burnable]);
    });

    test('supports flexible partial bilingual search (KO / JA / Katakana-Hiragana)', () {
      const items = [
        WasteItem(
          id: 'frying_pan',
          nameKo: '프라이팬 · 냄비',
          nameJa: 'フライパン・なべ',
          reading: 'ふらいぱんなべ',
          keywords: ['후라이팬', '냄비'],
          category: WasteCategory.nonBurnable,
          noteKo: '30cm 이하 불연쓰레기',
          noteJa: '30cm以下は不燃ごみ',
        ),
        WasteItem(
          id: 'umbrella',
          nameKo: '우산 · 양산',
          nameJa: '傘（かさ）',
          reading: 'かさ',
          keywords: ['비닐우산'],
          category: WasteCategory.nonBurnable,
          noteKo: '불연쓰레기',
          noteJa: '不燃ごみ',
        ),
      ];

      // Korean partial / colloquial
      expect(ScheduleEngine.searchItems(items, query: '후라이').length, 1);
      expect(ScheduleEngine.searchItems(items, query: '우산').length, 1);

      // Japanese Katakana <-> Hiragana cross-matching
      expect(ScheduleEngine.searchItems(items, query: 'ふらいぱん').length, 1);
      expect(ScheduleEngine.searchItems(items, query: 'フライ').length, 1);
      expect(ScheduleEngine.searchItems(items, query: 'カサ').length, 1);
      expect(ScheduleEngine.searchItems(items, query: '傘').length, 1);
    });
  });
}
