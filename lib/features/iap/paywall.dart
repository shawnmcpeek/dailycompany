import 'package:dailycompany/app/router/portal_routes.dart';
import 'package:dailycompany/data/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens the active portal's unlock screen — Oblate for Benedict, Companion
/// for de Sales. The route itself branches by portalId (see app_router.dart)
/// so callers never need to know which portal they're on.
Future<void> openPaywall(BuildContext context) {
  final portalId = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(currentPortalIdProvider);
  return context.push(PortalRoutes.paywall(portalId));
}
