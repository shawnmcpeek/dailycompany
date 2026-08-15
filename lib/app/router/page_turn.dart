import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Cross-fade + slight horizontal drift — page-turn adjacent, not a curl.
abstract final class PageTurn {
  static const duration = Duration(milliseconds: 480);
  static const curve = Curves.easeOutCubic;

  /// Fraction of width for the drift (~a finger’s width on phone).
  static const drift = 0.035;

  static CustomTransitionPage<T> of<T>({
    required LocalKey key,
    required Widget child,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) {
          return child;
        }

        final curved = CurvedAnimation(parent: animation, curve: curve);
        final outgoing = CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        );

        final incoming = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(drift, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-drift * 0.6, 0),
          ).animate(outgoing),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.85).animate(outgoing),
            child: incoming,
          ),
        );
      },
    );
  }
}
