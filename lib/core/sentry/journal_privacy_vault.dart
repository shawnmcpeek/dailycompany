/// Holds user-authored journal strings that must never appear in Sentry payloads.
abstract final class JournalPrivacyVault {
  static final Set<String> _sensitive = <String>{};

  /// Remember free-text so [redact] can strip it from any outgoing event.
  static void remember(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    // Short tokens are too likely to collide with stack/route noise.
    if (trimmed.length < 4) return;
    _sensitive.add(trimmed);
  }

  static void forget(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    _sensitive.remove(trimmed);
  }

  static void clear() => _sensitive.clear();

  /// Replace every remembered journal string in [input].
  static String redact(String input) {
    if (input.isEmpty || _sensitive.isEmpty) return input;
    var out = input;
    // Longest first so overlapping phrases redact cleanly.
    final ordered = _sensitive.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final s in ordered) {
      if (out.contains(s)) {
        out = out.replaceAll(s, '[redacted]');
      }
    }
    return out;
  }

  static bool containsSensitive(String input) {
    if (input.isEmpty || _sensitive.isEmpty) return false;
    for (final s in _sensitive) {
      if (input.contains(s)) return true;
    }
    return false;
  }
}
