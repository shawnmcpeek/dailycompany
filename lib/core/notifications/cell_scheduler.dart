import 'dart:typed_data';

import 'package:dailycompany/core/notifications/notification_plugin.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// One daily Cell hour — spec §9.2. Off by default. Payload `cell`.
class CellScheduler {
  CellScheduler._();
  static final CellScheduler instance = CellScheduler._();

  FlutterLocalNotificationsPlugin get _plugin => SharedNotifications.plugin;

  static const _channelId = 'kempis_cell';
  static const _channelName = 'The Cell';
  static const _channelDesc = 'Hour of withdrawal';
  static const _notifId = 401;

  Future<void> reschedule(AppSettings settings) async {
    await SharedNotifications.ensureInit();
    await _plugin.cancel(id: _notifId);

    if (!settings.kempisCellEnabled) return;
    if (notificationSchedulingUnsupportedHere) return;

    final parsed = parseHHmm(settings.kempisCellTime);
    if (parsed == null) return;

    final when = _nextInstance(parsed.hour, parsed.minute);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 40]),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      ),
    );

    await _plugin.zonedSchedule(
      id: _notifId,
      title: 'The Cell',
      body: 'Withdraw into the inner cell.',
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'cell',
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
