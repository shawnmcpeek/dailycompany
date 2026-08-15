import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Local-only rolling diagnostic log. Never includes journal body text.
class DiagnosticsLog {
  DiagnosticsLog._();
  static final DiagnosticsLog instance = DiagnosticsLog._();

  static const _maxEvents = 200;
  static const _fileName = 'benedict_diagnostics.jsonl';

  final List<DiagnosticsEvent> _events = <DiagnosticsEvent>[];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          _events.add(
            DiagnosticsEvent.fromJson(
              jsonDecode(line) as Map<String, dynamic>,
            ),
          );
        } catch (_) {
          // Skip corrupt lines.
        }
      }
      _trim();
    } catch (_) {
      // Diagnostics must never break the app.
    }
  }

  Future<void> record({
    required String operation,
    String? errorCode,
    Map<String, Object?> metadata = const {},
  }) async {
    await ensureLoaded();
    final event = DiagnosticsEvent(
      at: DateTime.now().toUtc(),
      operation: operation,
      errorCode: errorCode,
      metadata: {
        for (final e in metadata.entries)
          if (e.value != null) e.key: e.value!,
      },
    );
    _events.add(event);
    _trim();
    await _persist();
  }

  List<DiagnosticsEvent> get events => List.unmodifiable(_events);

  String exportText() {
    final buf = StringBuffer()
      ..writeln('Benedict Daily — diagnostics')
      ..writeln('Exported ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}')
      ..writeln('Events: ${_events.length} (max $_maxEvents)')
      ..writeln('No journal or prayer text is included.')
      ..writeln()
      ..writeln('---')
      ..writeln();
    for (final e in _events) {
      buf
        ..writeln(e.at.toIso8601String())
        ..writeln(e.operation)
        ..writeln(e.errorCode ?? '(no error code)');
      if (e.metadata.isNotEmpty) {
        for (final m in e.metadata.entries) {
          buf.writeln('  ${m.key}: ${m.value}');
        }
      }
      buf
        ..writeln()
        ..writeln('---')
        ..writeln();
    }
    return buf.toString();
  }

  Future<void> share({Rect? sharePositionOrigin}) async {
    await ensureLoaded();
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/benedict_diagnostics_$stamp.txt');
    await file.writeAsString(exportText());
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'text/plain',
            name: 'benedict_diagnostics_$stamp.txt',
          ),
        ],
        text: 'Benedict Daily · diagnostics',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  void _trim() {
    while (_events.length > _maxEvents) {
      _events.removeAt(0);
    }
  }

  Future<void> _persist() async {
    try {
      final file = await _file();
      final sink = file.openWrite();
      for (final e in _events) {
        sink.writeln(jsonEncode(e.toJson()));
      }
      await sink.flush();
      await sink.close();
    } catch (_) {
      // Ignore persistence failures.
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }
}

@immutable
class DiagnosticsEvent {
  const DiagnosticsEvent({
    required this.at,
    required this.operation,
    this.errorCode,
    this.metadata = const {},
  });

  final DateTime at;
  final String operation;
  final String? errorCode;
  final Map<String, Object> metadata;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'operation': operation,
        if (errorCode != null) 'errorCode': errorCode,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory DiagnosticsEvent.fromJson(Map<String, dynamic> json) {
    final metaRaw = json['metadata'];
    final meta = <String, Object>{};
    if (metaRaw is Map) {
      for (final e in metaRaw.entries) {
        meta['${e.key}'] = e.value as Object;
      }
    }
    return DiagnosticsEvent(
      at: DateTime.parse(json['at'] as String),
      operation: json['operation'] as String,
      errorCode: json['errorCode'] as String?,
      metadata: meta,
    );
  }
}
