import 'dart:typed_data';

import 'package:dailycompany/core/notifications/notification_plugin.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules the six office bells and Serra's Angelus. Payload `office:<id>`
/// or `angelus` — one plugin, one dispatcher. Do not add a second scheduler.
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

  static const angelusIds = [
    'angelus-dawn',
    'angelus-noon',
    'angelus-evening',
  ];

  static const labels = {
    'lauds': 'Lauds',
    'terce': 'Terce',
    'sext': 'Sext',
    'none': 'None',
    'vespers': 'Vespers',
    'compline': 'Compline',
    'angelus-dawn': 'Angelus',
    'angelus-noon': 'Angelus',
    'angelus-evening': 'Angelus',
  };

  static const _notifIds = {
    'lauds': 101,
    'terce': 102,
    'sext': 103,
    'none': 104,
    'vespers': 105,
    'compline': 106,
    'angelus-dawn': 107,
    'angelus-noon': 108,
    'angelus-evening': 109,
  };

  static const defaultTimes = {
    'lauds': '07:00',
    'terce': '09:00',
    'sext': '12:00',
    'none': '15:00',
    'vespers': '18:00',
    'compline': '21:00',
    'angelus-dawn': '06:00',
    'angelus-noon': '12:00',
    'angelus-evening': '18:00',
  };

  Future<void> init() => SharedNotifications.ensureInit();

  Future<void> reschedule(
    AppSettings settings, {
    bool hasOblate = true,
  }) async {
    await SharedNotifications.ensureInit();

    for (final id in [...officeIds, ...angelusIds]) {
      await _plugin.cancel(id: _notifIds[id]!);
    }

    if (notificationSchedulingUnsupportedHere) return;

    if (settings.bellsEnabled) {
      var ids = settings.oraEtLabora
          ? const ['terce', 'sext', 'none']
          : officeIds;
      if (!hasOblate) {
        ids = const ['compline'];
      }
      for (final id in ids) {
        await _schedule(
          id: id,
          settings: settings,
          title: labels[id] ?? id,
          body: 'The signal for the Work of God.',
          payload: 'office:$id',
        );
      }
    }

    if (settings.serraAngelusEnabled) {
      for (final id in angelusIds) {
        await _schedule(
          id: id,
          settings: settings,
          title: 'The Angelus',
          body: 'The Angel of the Lord declared unto Mary.',
          payload: 'angelus',
          angelusHaptic: true,
        );
      }
    }
  }

  Future<void> _schedule({
    required String id,
    required AppSettings settings,
    required String title,
    required String body,
    required String payload,
    bool angelusHaptic = false,
  }) async {
    final parsed = parseHHmm(settings.timeForOffice(id));
    if (parsed == null) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        enableVibration: true,
        vibrationPattern: angelusHaptic
            ? Int64List.fromList(const [0, 80, 200, 80, 200, 80])
            : null,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
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
      title: title,
      body: body,
      scheduledDate: _nextInstance(parsed.hour, parsed.minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
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
