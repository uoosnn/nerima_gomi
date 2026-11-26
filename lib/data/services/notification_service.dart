import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:nerima_gomi/core/l10n/app_strings.dart';
import 'package:nerima_gomi/data/models/schedule_models.dart';
import 'package:nerima_gomi/data/services/schedule_engine.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'nerima_gomi_alarms';
  static const _channelName = '분리배출 수거 알람';
  static const _channelDesc = '네리마구 쓰레기 수거 일정 로컬 알람';

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    try {
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init skipped: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  /// Cancels existing app notifications and schedules all upcoming calendar alarms.
  Future<int> rescheduleAll({
    required AreaSchedule schedule,
    required HolidayConfig holidays,
    required List<AlarmRule> rules,
    required AppLanguage language,
  }) async {
    if (kIsWeb) return 0;
    if (!_initialized) await init();
    if (!_initialized) return 0;

    try {
      await _plugin.cancelAll();
    } catch (_) {
      return 0;
    }

    final s = AppStrings(language);
    final events = ScheduleEngine.buildUpcomingAlarms(
      now: DateTime.now(),
      schedule: schedule,
      holidays: holidays,
      rules: rules,
      horizonDays: 35,
    );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    var scheduledCount = 0;
    final location = tz.getLocation('Asia/Tokyo');

    // Keep within platform pending notification limits (iOS max 64)
    for (final event in events.take(55)) {
      final tzTime = tz.TZDateTime(
        location,
        event.triggerTime.year,
        event.triggerTime.month,
        event.triggerTime.day,
        event.triggerTime.hour,
        event.triggerTime.minute,
      );

      final catNames =
          event.categories.map((c) => c.name(language)).join(' · ');
      final dateLabel = s.formatMonthDay(event.collectionDate);
      final title = event.rule.daysBefore == 0
          ? (s.isKo ? '오늘의 분리배출 ($dateLabel)' : '今日のごみ出し ($dateLabel)')
          : (s.isKo
              ? '${s.daysBeforeLabel(event.rule.daysBefore)} 알림 ($dateLabel)'
              : '${s.daysBeforeLabel(event.rule.daysBefore)}のお知らせ ($dateLabel)');

      final has9amOnly = event.categories.length == 1 &&
          event.categories.first.cutoffTime == '09:00';
      final cutoffHint = has9amOnly
          ? (s.isKo ? '아침 9시까지 배출' : '朝9時までに出してください')
          : (s.isKo ? '아침 8시까지 배출 (병·캔·페트병은 9시)' : '朝8時まで（びん・缶・ペットは9時）');

      try {
        await _plugin.zonedSchedule(
          event.notificationId,
          title,
          '$catNames — $cutoffHint',
          tzTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        scheduledCount++;
      } catch (e) {
        debugPrint('Failed to schedule alarm ${event.notificationId}: $e');
      }
    }
    return scheduledCount;
  }

  Future<void> showTestNotification(AppLanguage language) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!_initialized) return;
    await requestPermissions();

    final isKo = language == AppLanguage.ko;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      999999,
      isKo ? '네리마 분리배출 테스트 알림' : '練馬ごみナビ テスト通知',
      isKo
          ? '로컬 알람이 정상적으로 작동합니다!'
          : 'ローカルアラームは正常に動作しています！',
      details,
    );
  }
}
