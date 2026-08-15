import 'dart:io';

import 'package:benedictdaily/core/diagnostics/diagnostics_log.dart';
import 'package:benedictdaily/core/sentry/journal_privacy_vault.dart';
import 'package:benedictdaily/data/isar/app_isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Reports journal/lectio operational failures without user content.
abstract final class JournalFailureReporter {
  static Future<void> report({
    required String key,
    required int characterCount,
    int? readingId,
    int retryCount = 0,
    Object? error,
    StackTrace? stackTrace,
    bool asException = false,
  }) async {
    final freeBytes = await freeDiskBytes();
    final meta = <String, Object?>{
      'character_count': characterCount,
      'reading_id': ?readingId,
      'isar_open': AppIsar.isOpen,
      'free_disk_bytes': ?freeBytes,
      'retry_count': retryCount,
      if (error != null) 'error_type': error.runtimeType.toString(),
    };

    await DiagnosticsLog.instance.record(
      operation: key,
      errorCode: error?.runtimeType.toString() ?? key,
      metadata: meta,
    );

    final contexts = <String, Object>{
      for (final e in meta.entries)
        if (e.value != null) e.key: e.value!,
    };

    if (asException && error != null) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.level = SentryLevel.error;
          scope.fingerprint = [key];
          scope.setContexts('journal_ops', contexts);
        },
      );
    }

    await Sentry.captureMessage(
      key,
      level: SentryLevel.warning,
      withScope: (scope) {
        scope.fingerprint = [key];
        scope.setContexts('journal_ops', contexts);
      },
    );
  }

  static Future<int?> freeDiskBytes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (Platform.isLinux || Platform.isAndroid || Platform.isMacOS) {
        final result = await Process.run('df', ['-Bk', dir.path]);
        if (result.exitCode != 0) return null;
        final lines = (result.stdout as String).trim().split('\n');
        if (lines.length < 2) return null;
        final parts = lines.last.split(RegExp(r'\s+'));
        if (parts.length < 4) return null;
        final avail = parts[3].replaceAll('K', '');
        final kb = int.tryParse(avail);
        return kb == null ? null : kb * 1024;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Registers draft text for redaction before any capture.
  static void rememberDraft(String? text) => JournalPrivacyVault.remember(text);
}
