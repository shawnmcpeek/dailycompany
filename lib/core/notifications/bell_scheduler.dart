import 'package:benedictdaily/app/router/app_router.dart';
import 'package:benedictdaily/data/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the six office bells. Payload is the office id (e.g. `compline`).
class BellScheduler {
  BellScheduler._();
  static final BellScheduler instance = BellScheduler._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

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

  Future<void> init() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    const linux = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );
    const initSettings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: false, sound: true);

    _ready = true;
  }

  void _onResponse(NotificationResponse response) {
    final officeId = response.payload;
    if (officeId == null || officeId.isEmpty) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    GoRouter.of(ctx).go('/hours/$officeId');
  }

  Future<void> reschedule(
    AppSettings settings, {
    bool hasOblate = true,
  }) async {
    if (!_ready) await init();

    for (final id in officeIds) {
      await _plugin.cancel(id: _notifIds[id]!);
    }

    if (!settings.bellsEnabled) return;

    // Exact recurring schedule is mobile/macOS-focused.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows)) {
      return;
    }

    var ids = settings.oraEtLabora
        ? const ['terce', 'sext', 'none']
        : officeIds;
    // Free tier: Compline only.
    if (!hasOblate) {
      ids = const ['compline'];
    }

    for (final id in ids) {
      final time = settings.timeForOffice(id);
      final parts = time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final label = labels[id] ?? id;
      final when = _nextInstance(hour, minute);

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
        payload: id,
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
