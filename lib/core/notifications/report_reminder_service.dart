import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../features/capture/domain/entities/expected_report_entity.dart';
import '../utils/app_logger.dart';

/// Local, on-device reminders for reports the user still owes before
/// their deadline (see [ExpectedReportEntity]). No server, no push —
/// just [FlutterLocalNotificationsPlugin.zonedSchedule] fired from the
/// device clock. Reminders are rebuilt from scratch every time the
/// expected-reports list is recomputed, so they always match reality.
class ReportReminderService {
  ReportReminderService._();
  static final ReportReminderService instance = ReportReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static const _channelId = 'report_reminders';
  static const _channelName = 'Report reminders';

  /// Our reserved notification id range: [_idBase, _idBase + _idSpan).
  static const _idBase = 42000;
  static const _idSpan = 80;

  /// This is a Federal Ministry of Health (Ethiopia) app — the server
  /// and every period boundary run on Addis time, so pin the local
  /// zone rather than pull in a device-timezone plugin.
  static const _zoneName = 'Africa/Addis_Ababa';

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_zoneName));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin),
      );

      final android_ = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android_?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Reminders to fill in reports before they lock',
          importance: Importance.defaultImportance,
        ),
      );
      await android_?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      log.w('[reminders] init failed, reminders disabled: $e');
    }
  }

  /// Cancel every reminder we own and re-create them for [expected].
  /// Grouped by lock date so a facility owing five reports on the same
  /// day gets ONE notification, not five. Two per day at most: a
  /// heads-up three days out and a "locks today" on the day.
  Future<void> reschedule(List<ExpectedReportEntity> expected) async {
    if (kIsWeb || !_ready) return;
    try {
      for (var i = 0; i < _idSpan; i++) {
        await _plugin.cancel(_idBase + i);
      }

      final now = DateTime.now();
      final byDay = <DateTime, List<ExpectedReportEntity>>{};
      for (final r in expected) {
        final lock = r.lockDate;
        if (lock == null || !lock.isAfter(now)) continue;
        final day = DateTime(lock.year, lock.month, lock.day);
        (byDay[day] ??= []).add(r);
      }
      final days = byDay.keys.toList()..sort();

      var id = _idBase;
      for (final day in days) {
        if (id - _idBase >= _idSpan - 2) break;
        final items = byDay[day]!;
        final heads = _at(day.subtract(const Duration(days: 3)), 8);
        final onDay = _at(day, 8);

        if (heads.isAfter(now)) {
          await _schedule(
            id++,
            'Reports lock soon',
            _headsBody(items),
            heads,
          );
        }
        if (onDay.isAfter(now)) {
          await _schedule(
            id++,
            'Reports lock today',
            _todayBody(items),
            onDay,
          );
        }
      }
      log.i('[reminders] scheduled ${id - _idBase} reminder(s)');
    } catch (e) {
      log.w('[reminders] reschedule failed: $e');
    }
  }

  // ── internals ──────────────────────────────────────────────────

  tz.TZDateTime _at(DateTime day, int hour) =>
      tz.TZDateTime(tz.local, day.year, day.month, day.day, hour);

  Future<void> _schedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
  ) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders to fill in reports before they lock',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact: a reminder a few minutes late is fine, and this keeps
      // us off the SCHEDULE_EXACT_ALARM permission entirely.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'expected_reports',
    );
  }

  static String _headsBody(List<ExpectedReportEntity> items) {
    final facilities = {for (final r in items) r.orgUnitName};
    final where = facilities.length == 1 ? ' at ${facilities.first}' : '';
    return items.length == 1
        ? '${items.first.dataSetName} for ${items.first.periodLabel}$where '
            'locks in 3 days.'
        : '${items.length} reports$where lock in 3 days.';
  }

  static String _todayBody(List<ExpectedReportEntity> items) {
    final facilities = {for (final r in items) r.orgUnitName};
    final where = facilities.length == 1 ? ' at ${facilities.first}' : '';
    return items.length == 1
        ? '${items.first.dataSetName} for ${items.first.periodLabel}$where '
            'locks today.'
        : '${items.length} reports$where lock today — fill them now.';
  }
}
