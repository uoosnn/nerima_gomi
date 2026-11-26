import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nerima_gomi/core/l10n/app_strings.dart';
import 'package:nerima_gomi/data/models/schedule_models.dart';

class AppRepository {
  static const _kScheduleKey = 'user_area_schedule_v1';
  static const _kAlarmsKey = 'user_alarm_rules_v1';
  static const _kLangKey = 'user_language_v1';
  static const _kThemeKey = 'user_theme_mode_v1';

  Future<List<AreaSchedule>> loadAreaPresets() async {
    final raw = await rootBundle.loadString('assets/data/areas.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AreaSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WasteItem>> loadWasteItems() async {
    final raw = await rootBundle.loadString('assets/data/items.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WasteItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HolidayConfig> loadHolidays() async {
    final raw = await rootBundle.loadString('assets/data/holidays.json');
    return HolidayConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Automatically discovers all user-dropped Nerimaru images in assets/images/nerimaru/.
  Future<List<String>> loadNerimaruImages() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      final images = assets.where((path) {
        if (!path.startsWith('assets/images/nerimaru/')) return false;
        final lower = path.toLowerCase();
        return lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.webp');
      }).toList()
        ..sort();
      return images;
    } catch (_) {
      return const [];
    }
  }

  Future<AreaSchedule?> loadSavedSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kScheduleKey);
    if (raw == null) return null;
    try {
      return AreaSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSchedule(AreaSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kScheduleKey, jsonEncode(schedule.toJson()));
  }

  Future<List<AlarmRule>> loadAlarmRules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlarmsKey);
    if (raw == null) return AlarmRule.defaultRules();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AlarmRule.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return AlarmRule.defaultRules();
    }
  }

  Future<void> saveAlarmRules(List<AlarmRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAlarmsKey,
      jsonEncode(rules.map((e) => e.toJson()).toList()),
    );
  }

  Future<AppLanguage> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey);
    return code == 'ja' ? AppLanguage.ja : AppLanguage.ko;
  }

  Future<void> saveLanguage(AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, lang == AppLanguage.ja ? 'ja' : 'ko');
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kThemeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_kThemeKey, value);
  }
}
