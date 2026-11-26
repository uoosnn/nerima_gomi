import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nerima_gomi/core/l10n/app_strings.dart';
import 'package:nerima_gomi/data/models/schedule_models.dart';
import 'package:nerima_gomi/data/models/waste_category.dart';
import 'package:nerima_gomi/data/repositories/app_repository.dart';
import 'package:nerima_gomi/data/services/notification_service.dart';

class AppState {
  final bool isLoading;
  final List<AreaSchedule> areaPresets;
  final AreaSchedule currentSchedule;
  final HolidayConfig holidays;
  final List<WasteItem> wasteItems;
  final List<AlarmRule> alarmRules;
  final List<String> nerimaruImages;
  final AppLanguage language;
  final ThemeMode themeMode;

  const AppState({
    required this.isLoading,
    required this.areaPresets,
    required this.currentSchedule,
    required this.holidays,
    required this.wasteItems,
    required this.alarmRules,
    required this.nerimaruImages,
    required this.language,
    required this.themeMode,
  });

  factory AppState.initial() => AppState(
        isLoading: true,
        areaPresets: const [],
        currentSchedule: const AreaSchedule(
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
            WasteCategory.bottleCanPet:
                CollectionRule.weekly([DateTime.friday]),
          },
        ),
        holidays: const HolidayConfig(),
        wasteItems: const [],
        alarmRules: AlarmRule.defaultRules(),
        nerimaruImages: const [],
        language: AppLanguage.ko,
        themeMode: ThemeMode.system,
      );

  AppStrings get strings => AppStrings(language);

  AppState copyWith({
    bool? isLoading,
    List<AreaSchedule>? areaPresets,
    AreaSchedule? currentSchedule,
    HolidayConfig? holidays,
    List<WasteItem>? wasteItems,
    List<AlarmRule>? alarmRules,
    List<String>? nerimaruImages,
    AppLanguage? language,
    ThemeMode? themeMode,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      areaPresets: areaPresets ?? this.areaPresets,
      currentSchedule: currentSchedule ?? this.currentSchedule,
      holidays: holidays ?? this.holidays,
      wasteItems: wasteItems ?? this.wasteItems,
      alarmRules: alarmRules ?? this.alarmRules,
      nerimaruImages: nerimaruImages ?? this.nerimaruImages,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppController extends StateNotifier<AppState> {
  final AppRepository _repo;

  AppController(this._repo) : super(AppState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final results = await Future.wait([
      _repo.loadAreaPresets(),
      _repo.loadWasteItems(),
      _repo.loadHolidays(),
      _repo.loadSavedSchedule(),
      _repo.loadAlarmRules(),
      _repo.loadLanguage(),
      _repo.loadThemeMode(),
      _repo.loadNerimaruImages(),
    ]);

    final presets = results[0] as List<AreaSchedule>;
    final items = results[1] as List<WasteItem>;
    final holidays = results[2] as HolidayConfig;
    final savedSchedule = results[3] as AreaSchedule?;
    final alarms = results[4] as List<AlarmRule>;
    final language = results[5] as AppLanguage;
    final themeMode = results[6] as ThemeMode;
    final nerimaruImages = results[7] as List<String>;

    final activeSchedule =
        savedSchedule ?? (presets.isNotEmpty ? presets.first : state.currentSchedule);

    state = state.copyWith(
      isLoading: false,
      areaPresets: presets,
      currentSchedule: activeSchedule,
      holidays: holidays,
      wasteItems: items,
      alarmRules: alarms,
      language: language,
      themeMode: themeMode,
      nerimaruImages: nerimaruImages,
    );

    await _syncNotifications();
  }

  Future<void> selectAreaPreset(AreaSchedule preset) async {
    state = state.copyWith(currentSchedule: preset.copyWith(isCustom: false));
    await _repo.saveSchedule(state.currentSchedule);
    await _syncNotifications();
  }

  Future<void> updateCustomRule(
    WasteCategory category,
    CollectionRule rule,
  ) async {
    final updatedRules =
        Map<WasteCategory, CollectionRule>.from(state.currentSchedule.rules);
    updatedRules[category] = rule;
    final updated = state.currentSchedule.copyWith(
      rules: updatedRules,
      isCustom: true,
    );
    state = state.copyWith(currentSchedule: updated);
    await _repo.saveSchedule(updated);
    await _syncNotifications();
  }

  Future<void> upsertAlarmRule(AlarmRule rule) async {
    final existing = state.alarmRules.indexWhere((r) => r.id == rule.id);
    final updated = [...state.alarmRules];
    if (existing >= 0) {
      updated[existing] = rule;
    } else {
      updated.add(rule);
    }
    state = state.copyWith(alarmRules: updated);
    await _repo.saveAlarmRules(updated);
    await NotificationService.instance.requestPermissions();
    await _syncNotifications();
  }

  Future<void> toggleAlarmRule(String id, bool enabled) async {
    final updated = state.alarmRules
        .map((r) => r.id == id ? r.copyWith(enabled: enabled) : r)
        .toList();
    state = state.copyWith(alarmRules: updated);
    await _repo.saveAlarmRules(updated);
    if (enabled) {
      await NotificationService.instance.requestPermissions();
    }
    await _syncNotifications();
  }

  Future<void> deleteAlarmRule(String id) async {
    final updated = state.alarmRules.where((r) => r.id != id).toList();
    state = state.copyWith(alarmRules: updated);
    await _repo.saveAlarmRules(updated);
    await _syncNotifications();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = state.copyWith(language: lang);
    await _repo.saveLanguage(lang);
    await _syncNotifications();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repo.saveThemeMode(mode);
  }

  Future<void> _syncNotifications() async {
    await NotificationService.instance.rescheduleAll(
      schedule: state.currentSchedule,
      holidays: state.holidays,
      rules: state.alarmRules,
      language: state.language,
    );
  }
}

final appRepositoryProvider = Provider<AppRepository>((ref) => AppRepository());

final appControllerProvider =
    StateNotifierProvider<AppController, AppState>((ref) {
  return AppController(ref.watch(appRepositoryProvider));
});
