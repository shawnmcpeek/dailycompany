import 'package:dailycompany/app/router/app_router.dart';
import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// An `"HH:mm"` string parsed to its parts, or null if malformed.
typedef ParsedTime = ({int hour, int minute});

/// Parses the `"HH:mm"` strings every scheduler stores in [AppSettings],
/// returning null rather than throwing on anything malformed.
ParsedTime? parseHHmm(String value) {
  final parts = value.split(':');
  if (parts.isEmpty) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '0');
  if (hour == null || minute == null) return null;
  return (hour: hour, minute: minute);
}

/// True on desktop targets where exact/zoned local notifications aren't
/// reliably supported — every scheduler skips scheduling here and only
/// plays in-app haptics instead.
bool get notificationSchedulingUnsupportedHere =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows);

/// One native notification plugin/channel for the whole app.
///
/// flutter_local_notifications talks to a single platform channel no
/// matter how many `FlutterLocalNotificationsPlugin()` objects exist — a
/// second `initialize()` call replaces the first's tap-response callback
/// rather than adding to it. So every scheduler (bells, aspirations)
/// shares this one instance and routes through one dispatcher, keyed by
/// a payload prefix, instead of each owning its own plugin + init.
abstract final class SharedNotifications {
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> ensureInit() async {
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
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const initSettings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );

    await plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: false, sound: true);

    _ready = true;
  }

  /// Payload shape: `office:<id>` for a Benedict bell, `aspiration` for
  /// a de Sales aspiration.
  static void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final portalId = ProviderScope.containerOf(
      ctx,
      listen: false,
    ).read(currentPortalIdProvider);

    if (payload.startsWith('office:')) {
      final officeId = payload.substring('office:'.length);
      GoRouter.of(ctx).go(PortalRoutes.office(portalId, officeId));
    } else if (payload == 'aspiration') {
      GoRouter.of(ctx).go(PortalRoutes.today(portalId));
    }
  }
}
