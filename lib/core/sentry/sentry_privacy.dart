import 'package:benedictdaily/core/sentry/journal_privacy_vault.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Keys that commonly hold user-authored journal / free-text fields.
const _sensitiveKeys = <String>{
  'text',
  'title',
  'tags',
  'tag',
  'entry',
  'body',
  'content',
  'journal',
  'journal_text',
  'journaltext',
  'entry_text',
  'entrytext',
  'note',
  'notes',
  'prayer',
  'draft',
};

/// Redacts user-authored journal content from Sentry events, then sends them.
///
/// Keeps exception type, stack frames, route/transaction, and technical metadata.
SentryEvent? scrubSentryEvent(SentryEvent event, Hint hint) {
  final msg = event.message;
  if (msg != null) {
    event.message = SentryMessage(
      JournalPrivacyVault.redact(msg.formatted),
      template: msg.template == null
          ? null
          : JournalPrivacyVault.redact(msg.template!),
      params: msg.params?.map(_redactDynamic).toList(),
    );
  }

  if (event.culprit != null) {
    event.culprit = JournalPrivacyVault.redact(event.culprit!);
  }

  final extras = event.extra;
  if (extras != null && extras.isNotEmpty) {
    event.extra = _redactMap(Map<String, dynamic>.from(extras));
  }

  final tags = event.tags;
  if (tags != null && tags.isNotEmpty) {
    event.tags = {
      for (final e in tags.entries)
        e.key: _isSensitiveKey(e.key)
            ? '[redacted]'
            : JournalPrivacyVault.redact(e.value),
    };
  }

  final breadcrumbs = event.breadcrumbs;
  if (breadcrumbs != null) {
    event.breadcrumbs = [
      for (final crumb in breadcrumbs) _redactBreadcrumb(crumb),
    ];
  }

  final exceptions = event.exceptions;
  if (exceptions != null) {
    for (final ex in exceptions) {
      // Keep type; scrub free-text from the value (may embed journal copy).
      if (ex.value != null) {
        ex.value = JournalPrivacyVault.redact(ex.value!);
      }
      _redactFrames(ex.stackTrace?.frames);
    }
  }

  final threads = event.threads;
  if (threads != null) {
    for (final thread in threads) {
      _redactFrames(thread.stacktrace?.frames);
    }
  }

  // Structured contexts — scrub nested maps / sensitive keys, keep route names.
  _redactContexts(event.contexts);

  return event;
}

Breadcrumb? scrubSentryBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
  if (breadcrumb == null) return null;
  return _redactBreadcrumb(breadcrumb);
}

Breadcrumb _redactBreadcrumb(Breadcrumb crumb) {
  final data = crumb.data == null
      ? null
      : _redactMap(Map<String, dynamic>.from(crumb.data!));
  return Breadcrumb(
    message: crumb.message == null
        ? null
        : JournalPrivacyVault.redact(crumb.message!),
    category: crumb.category,
    type: crumb.type,
    level: crumb.level,
    timestamp: crumb.timestamp,
    data: data,
  );
}

void _redactFrames(List<SentryStackFrame>? frames) {
  if (frames == null) return;
  for (final frame in frames) {
    // Source context lines can include string literals from the draft.
    if (frame.contextLine != null) {
      frame.contextLine = JournalPrivacyVault.redact(frame.contextLine!);
    }
  }
}

void _redactContexts(Contexts contexts) {
  // Walk known dynamic bags without wiping technical device/app/os context.
  final raw = contexts.toJson();
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key == 'os' ||
        key == 'device' ||
        key == 'app' ||
        key == 'gpu' ||
        key == 'trace' ||
        key == 'culture' ||
        key == 'dart' ||
        key == 'flutter' ||
        key == 'accessibility') {
      continue;
    }
    final value = entry.value;
    if (value is Map) {
      contexts[key] = _redactMap(Map<String, dynamic>.from(value));
    } else if (value is String) {
      contexts[key] = _isSensitiveKey(key)
          ? '[redacted]'
          : JournalPrivacyVault.redact(value);
    }
  }
}

Map<String, dynamic> _redactMap(Map<String, dynamic> input) {
  final out = <String, dynamic>{};
  for (final e in input.entries) {
    if (_isSensitiveKey(e.key)) {
      out[e.key] = '[redacted]';
      continue;
    }
    out[e.key] = _redactDynamic(e.value);
  }
  return out;
}

dynamic _redactDynamic(dynamic value) {
  if (value == null) return null;
  if (value is String) return JournalPrivacyVault.redact(value);
  if (value is Map) {
    return _redactMap(Map<String, dynamic>.from(value));
  }
  if (value is List) {
    return value.map(_redactDynamic).toList();
  }
  return value;
}

bool _isSensitiveKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  for (final s in _sensitiveKeys) {
    final needle = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized == needle || normalized.contains(needle)) {
      return true;
    }
  }
  return false;
}

/// Applies privacy-constrained Sentry options shared by init.
void configureBenedictSentryOptions(
  SentryFlutterOptions options, {
  required String release,
}) {
  const dsn = String.fromEnvironment('SENTRY_DSN');
  options.dsn = dsn;
  options.environment = kReleaseMode ? 'production' : 'development';
  options.release = release;

  options.sendDefaultPii = false;
  options.tracesSampleRate = kReleaseMode ? 0.2 : 0.0;
  // ignore: experimental_member_use
  options.profilesSampleRate = null;

  options.enableAutoNativeBreadcrumbs = false;
  options.enablePrintBreadcrumbs = false;
  options.enableLogs = false;
  options.enableUserInteractionBreadcrumbs = false;
  options.recordHttpBreadcrumbs = false;

  options.attachScreenshot = false;
  // ignore: experimental_member_use
  options.attachViewHierarchy = false;

  options.beforeSend = scrubSentryEvent;
  options.beforeBreadcrumb = scrubSentryBreadcrumb;

  // Never identify users.
  options.debug = kDebugMode && dsn.isNotEmpty;
}
