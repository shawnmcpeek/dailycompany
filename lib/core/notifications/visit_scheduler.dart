import 'dart:typed_data';

import 'package:dailycompany/core/notifications/notification_plugin.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// One daily Visit hour. Off by default. Payload `visit`.
/// Body is the Visit title for the day the notification will fire.
class VisitScheduler {
  VisitScheduler._();
  static final VisitScheduler instance = VisitScheduler._();

  FlutterLocalNotificationsPlugin get _plugin => SharedNotifications.plugin;

  static const _channelId = 'liguori_visit';
  static const _channelName = 'The Visit';
  static const _channelDesc = 'Hour of the Visit';
  static const _notifId = 501;

  static const titles = <String>[
    'First Visit',
    'Second Visit',
    'Third Visit',
    'Fourth Visit',
    'Fifth Visit',
    'Sixth Visit',
    'Seventh Visit',
    'Eighth Visit',
    'Ninth Visit',
    'Tenth Visit',
    'Eleventh Visit',
    'Twelfth Visit',
    'Thirteenth Visit',
    'Fourteenth Visit',
    'Fifteenth Visit',
    'Sixteenth Visit',
    'Seventeenth Visit',
    'Eighteenth Visit',
    'Nineteenth Visit',
    'Twentieth Visit',
    'Twenty-first Visit',
    'Twenty-second Visit',
    'Twenty-third Visit',
    'Twenty-fourth Visit',
    'Twenty-fifth Visit',
    'Twenty-sixth Visit',
    'Twenty-seventh Visit',
    'Twenty-eighth Visit',
    'Twenty-ninth Visit',
    'Thirtieth Visit',
    'Thirty-first Visit',
  ];

  Future<void> reschedule(AppSettings settings) async {
    await SharedNotifications.ensureInit();
    await _plugin.cancel(id: _notifId);

    if (!settings.liguoriVisitEnabled) return;
    if (notificationSchedulingUnsupportedHere) return;

    final parsed = parseHHmm(settings.liguoriVisitTime);
    if (parsed == null) return;

    final when = _nextInstance(parsed.hour, parsed.minute);
    final visit = titles[(when.day - 1).clamp(0, titles.length - 1)];
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
      title: 'The Visit',
      body: visit,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'visit',
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
