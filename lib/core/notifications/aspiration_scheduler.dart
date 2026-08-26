import 'dart:math';
import 'dart:typed_data';

import 'package:dailycompany/core/notifications/notification_plugin.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules de Sales' aspirations — spec §8.3: "brief returns to God
/// scattered through an ordinary working day," three or four a day,
/// jittered ±10 minutes so they don't read as an alarm. Payload is the
/// literal string `aspiration`; see [SharedNotifications] for the shared
/// plugin/dispatcher this and [BellScheduler] both route through.
///
/// Unlike the six office bells (one exact recurring time each, via
/// `matchDateTimeComponents`), a jittered time can't be expressed as a
/// single repeating schedule — each day's instance needs its own jitter.
/// So this pre-schedules a rolling [_windowDays] window of one-shot
/// notifications instead, and [reschedule] (called whenever settings
/// change, and on every app open via [desalesAspirationSyncProvider])
/// keeps that window topped up.
class AspirationScheduler {
  AspirationScheduler._();
  static final AspirationScheduler instance = AspirationScheduler._();

  FlutterLocalNotificationsPlugin get _plugin => SharedNotifications.plugin;

  static const _channelId = 'desales_aspirations';
  static const _channelName = 'Aspirations';
  static const _channelDesc = 'Brief returns to God through the day';

  static const slotIds = ['a1', 'a2', 'a3'];
  static const defaultTimes = {'a1': '10:00', 'a2': '14:00', 'a3': '17:00'};

  static const _windowDays = 14;
  static const _jitterMinutes = 10;

  // 300..300 + windowDays*slots, distinct from BellScheduler's 101-106.
  static const _baseNotifId = 300;
  static int _notifId(int dayOffset, int slotIndex) =>
      _baseNotifId + (dayOffset * slotIds.length) + slotIndex;

  final _rng = Random();

  Future<void> reschedule(AppSettings settings) async {
    await SharedNotifications.ensureInit();

    for (var d = 0; d < _windowDays; d++) {
      for (var s = 0; s < slotIds.length; s++) {
        await _plugin.cancel(id: _notifId(d, s));
      }
    }

    if (!settings.desalesAspirationsEnabled) return;

    // Exact one-shot scheduling is mobile/macOS-focused, same as bells.
    if (notificationSchedulingUnsupportedHere) return;

    final now = tz.TZDateTime.now(tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 60]),
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

    for (var d = 0; d < _windowDays; d++) {
      for (var s = 0; s < slotIds.length; s++) {
        final base = settings.aspirationTimes[slotIds[s]] ??
            defaultTimes[slotIds[s]]!;
        final parsed = parseHHmm(base);
        if (parsed == null) continue;

        final jitter = _rng.nextInt(_jitterMinutes * 2 + 1) - _jitterMinutes;
        final when = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          parsed.hour,
          parsed.minute,
        ).add(Duration(days: d, minutes: jitter));

        if (!when.isAfter(now)) continue;

        await _plugin.zonedSchedule(
          id: _notifId(d, s),
          title: null,
          body: 'A brief return to God.',
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'aspiration',
        );
      }
    }
  }
}
