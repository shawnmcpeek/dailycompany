import 'package:dailycompany/core/notifications/notification_plugin.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules the six office bells. Payload is `office:<id>` (e.g.
/// `office:compline`) — see [SharedNotifications] for the single shared
/// plugin/dispatcher this and [AspirationScheduler] both route through.
class BellScheduler {
  BellScheduler._();
  static final BellScheduler instance = BellScheduler._();

  FlutterLocalNotificationsPlugin get _plugin => SharedNotifications.plugin;

  static const _channelId = 'benedict_bells';
  static const _channelName = 'Office bells';
  static const _channelDesc = 'Signals for the Work of God';

  static const officeIds = [
    'lauds',
    'terce',
    'sext',
    'none',
    'vespers',
    'compline',
  ];

  static const labels = {
    'lauds': 'Lauds',
    'terce': 'Terce',
    'sext': 'Sext',
    'none': 'None',
    'vespers': 'Vespers',
    'compline': 'Compline',
  };

  static const _notifIds = {
    'lauds': 101,
    'terce': 102,
    'sext': 103,
    'none': 104,
    'vespers': 105,
    'compline': 106,
  };

  static const defaultTimes = {
    'lauds': '07:00',
    'terce': '09:00',
    'sext': '12:00',
    'none': '15:00',
    'vespers': '18:00',
    'compline': '21:00',
  };

  Future<void> init() => SharedNotifications.ensureInit();

  Future<void> reschedule(
    AppSettings settings, {
    bool hasOblate = true,
  }) async {
    await SharedNotifications.ensureInit();

    for (final id in officeIds) {
      await _plugin.cancel(id: _notifIds[id]!);
    }

    if (!settings.bellsEnabled) return;

    // Exact recurring schedule is mobile/macOS-focused.
    if (notificationSchedulingUnsupportedHere) return;

    var ids = settings.oraEtLabora
        ? const ['terce', 'sext', 'none']
        : officeIds;
    // Free tier: Compline only.
    if (!hasOblate) {
      ids = const ['compline'];
    }

    for (final id in ids) {
      final parsed = parseHHmm(settings.timeForOffice(id));
      if (parsed == null) continue;

      final label = labels[id] ?? id;
      final when = _nextInstance(parsed.hour, parsed.minute);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(
            'The signal for $label. Open the office when ready.',
            contentTitle: label,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

      await _plugin.zonedSchedule(
        id: _notifIds[id]!,
        title: label,
        body: 'The signal for the Work of God.',
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'office:$id',
      );
    }
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
