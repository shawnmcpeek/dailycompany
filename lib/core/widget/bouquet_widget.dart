import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Pins the kept Bouquet line to the home/lock widget.
///
/// No-ops on platforms without a widget host. Android gets a home-screen
/// widget; iOS gets the lock-screen accessory.
abstract final class BouquetWidget {
  static const androidName = 'BouquetWidgetProvider';
  static const iOSName = 'BouquetWidget';
  static const appGroup = 'group.pro.daddoodev.dailycompany';

  static Future<void> sync({required String text}) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroup);
      await HomeWidget.saveWidgetData<String>('bouquet_text', text);
      await HomeWidget.saveWidgetData<bool>('bouquet_empty', text.trim().isEmpty);
      await HomeWidget.updateWidget(
        name: androidName,
        androidName: androidName,
        iOSName: iOSName,
        qualifiedAndroidName:
            'pro.daddoodev.dailycompany.BouquetWidgetProvider',
      );
    } catch (_) {
      // Widget host is optional; never block keeping a line.
    }
  }
}
