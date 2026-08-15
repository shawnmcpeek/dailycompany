import 'package:benedictdaily/core/sentry/journal_privacy_vault.dart';
import 'package:benedictdaily/core/sentry/sentry_privacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  tearDown(JournalPrivacyVault.clear);

  test('redacts vault journal text but keeps technical fields', () {
    const secret = 'PRIVATE_PRAYER_NEVER_LEAVE_DEVICE';
    JournalPrivacyVault.remember(secret);

    final event = SentryEvent(
      transaction: '/lectio',
      message: SentryMessage('journal_save_failed'),
      exceptions: [
        SentryException(
          type: 'StateError',
          value: 'Forced journal save failure: $secret',
          stackTrace: SentryStackTrace(
            frames: [
              SentryStackFrame(
                fileName: 'providers.dart',
                function: 'JournalController.add',
                contextLine: "text: '$secret'",
              ),
            ],
          ),
        ),
      ],
      contexts: Contexts(
        // Custom bag exercised by redaction.
      )..['journal_ops'] = {
          'character_count': secret.length,
          'text': secret,
          'reading_id': 42,
        },
      breadcrumbs: [
        Breadcrumb(message: 'Draft: $secret', category: 'ui'),
      ],
    );

    final out = scrubSentryEvent(event, Hint());
    expect(out, isNotNull);
    expect(out!.transaction, '/lectio');
    expect(out.message?.formatted, 'journal_save_failed');
    expect(out.exceptions!.first.type, 'StateError');
    expect(out.exceptions!.first.value, isNot(contains(secret)));
    expect(out.exceptions!.first.value, contains('[redacted]'));
    expect(
      out.exceptions!.first.stackTrace!.frames.first.function,
      'JournalController.add',
    );
    expect(
      out.exceptions!.first.stackTrace!.frames.first.contextLine,
      isNot(contains(secret)),
    );
    final ops = out.contexts['journal_ops'] as Map;
    expect(ops['character_count'], secret.length);
    expect(ops['reading_id'], 42);
    expect(ops['text'], '[redacted]');
    expect(out.breadcrumbs!.first.message, isNot(contains(secret)));
  });

  test('allows unrelated errors through unchanged when no vault text', () {
    final event = SentryEvent(
      transaction: '/hub',
      exceptions: [
        SentryException(
          type: 'StateError',
          value: 'Benedict Daily Sentry verification crash',
          stackTrace: SentryStackTrace(
            frames: [
              SentryStackFrame(
                fileName: 'more_screen.dart',
                function: 'MoreScreen.build',
              ),
            ],
          ),
        ),
      ],
    );

    final out = scrubSentryEvent(event, Hint());
    expect(out, same(event));
    expect(
      out!.exceptions!.first.value,
      'Benedict Daily Sentry verification crash',
    );
  });

  test('redacts sensitive breadcrumb data keys', () {
    final crumb = scrubSentryBreadcrumb(
      Breadcrumb(
        message: 'ok',
        category: 'ui',
        data: {'entry_text': 'hidden prayer', 'retry_count': 1},
      ),
      Hint(),
    );
    expect(crumb!.data!['entry_text'], '[redacted]');
    expect(crumb.data!['retry_count'], 1);
  });
}
