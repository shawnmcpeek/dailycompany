import 'dart:typed_data';

import 'package:dailycompany/core/notifications/notification_plugin.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class CycleReminderSpec {
  const CycleReminderSpec({
    required this.portalId,
    required this.channelId,
    required this.channelName,
    required this.channelDesc,
    required this.notifId,
    required this.payload,
    required this.title,
  });

  final String portalId;
  final String channelId;
  final String channelName;
  final String channelDesc;
  final int notifId;
  final String payload;
  final String title;
}

/// One optional daily reminder per constructed house. Off by default.
/// Body is the day's chapter title, never a nudge.
class CycleReminderScheduler {
  CycleReminderScheduler._();
  static final CycleReminderScheduler instance = CycleReminderScheduler._();

  static const specs = <String, CycleReminderSpec>{
    'john-cross': CycleReminderSpec(
      portalId: 'john-cross',
      channelId: 'john_cross_saying',
      channelName: 'The saying',
      channelDesc: 'Hour of the saying',
      notifId: 701,
      payload: 'saying',
      title: 'The saying',
    ),
    'gregory': CycleReminderSpec(
      portalId: 'gregory',
      channelId: 'gregory_pastoral',
      channelName: 'The Rule',
      channelDesc: 'Hour of the Pastoral Rule',
      notifId: 801,
      payload: 'pastoral',
      title: 'The Pastoral Rule',
    ),
    'augustine': CycleReminderSpec(
      portalId: 'augustine',
      channelId: 'augustine_evening',
      channelName: 'Evening reading',
      channelDesc: 'Hour of evening reading',
      notifId: 901,
      payload: 'evening',
      title: 'Evening reading',
    ),
    'teresa-avila': CycleReminderSpec(
      portalId: 'teresa-avila',
      channelId: 'teresa_recollection',
      channelName: 'Recollection',
      channelDesc: 'Hour of recollection',
      notifId: 1001,
      payload: 'recollection',
      title: 'Recollection',
    ),
    'ignatius': CycleReminderSpec(
      portalId: 'ignatius',
      channelId: 'ignatius_examen',
      channelName: 'Examen',
      channelDesc: 'Midday Examen',
      notifId: 1101,
      payload: 'examen',
      title: 'Examen',
    ),
    'ignatius-evening': CycleReminderSpec(
      portalId: 'ignatius-evening',
      channelId: 'ignatius_examen_evening',
      channelName: 'Evening Examen',
      channelDesc: 'Evening Examen',
      notifId: 1102,
      payload: 'examen-evening',
      title: 'Examen',
    ),
    'therese': CycleReminderSpec(
      portalId: 'therese',
      channelId: 'therese_offering',
      channelName: 'Offering',
      channelDesc: 'Hour of offering',
      notifId: 1201,
      payload: 'offering',
      title: 'The offering',
    ),
    'catherine': CycleReminderSpec(
      portalId: 'catherine',
      channelId: 'catherine_requests',
      channelName: 'Four requests',
      channelDesc: 'Hour of the requests',
      notifId: 1301,
      payload: 'requests',
      title: 'Four requests',
    ),
    'montfort': CycleReminderSpec(
      portalId: 'montfort',
      channelId: 'montfort_offering',
      channelName: 'Offering',
      channelDesc: 'Hour of offering',
      notifId: 1401,
      payload: 'offering',
      title: 'To Jesus through Mary',
    ),
    'scupoli': CycleReminderSpec(
      portalId: 'scupoli',
      channelId: 'scupoli_combat',
      channelName: 'The combat',
      channelDesc: 'Hour of the combat',
      notifId: 1501,
      payload: 'combat',
      title: 'The combat',
    ),
    'lawrence': CycleReminderSpec(
      portalId: 'lawrence',
      channelId: 'lawrence_presence',
      channelName: 'The presence',
      channelDesc: 'Hour of presence',
      notifId: 1601,
      payload: 'presence',
      title: 'The presence',
    ),
    'cassian': CycleReminderSpec(
      portalId: 'cassian',
      channelId: 'cassian_elder',
      channelName: 'The elder',
      channelDesc: 'Hour of the conference',
      notifId: 1701,
      payload: 'elder',
      title: 'The elder',
    ),
  };

  FlutterLocalNotificationsPlugin get _plugin => SharedNotifications.plugin;

  Future<void> reschedule(
    AppSettings settings, {
    required String portalId,
    String? body,
  }) async {
    final spec = specs[portalId];
    if (spec == null) return;

    await SharedNotifications.ensureInit();
    await _plugin.cancel(id: spec.notifId);

    if (!settings.reminderEnabledFor(portalId)) return;
    if (notificationSchedulingUnsupportedHere) return;

    final parsed = parseHHmm(settings.reminderTimeFor(portalId));
    if (parsed == null) return;

    final when = _nextInstance(parsed.hour, parsed.minute);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        spec.channelId,
        spec.channelName,
        channelDescription: spec.channelDesc,
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
      id: spec.notifId,
      title: spec.title,
      body: (body == null || body.trim().isEmpty) ? spec.title : body,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: spec.payload,
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
