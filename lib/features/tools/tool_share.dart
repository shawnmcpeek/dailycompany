import 'dart:io';
import 'dart:ui' as ui;

import 'package:dailycompany/data/content_catalog.dart';
import 'package:dailycompany/features/tools/tool_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract final class ToolShare {
  static Future<void> showAndShare(
    BuildContext context, {
    required ToolOfGoodWorks tool,
    required int total,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return _ToolShareSheet(tool: tool, total: total);
      },
    );
  }
}

class _ToolShareSheet extends StatefulWidget {
  const _ToolShareSheet({required this.tool, required this.total});

  final ToolOfGoodWorks tool;
  final int total;

  @override
  State<_ToolShareSheet> createState() => _ToolShareSheetState();
}

class _ToolShareSheetState extends State<_ToolShareSheet> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/benedict_tool_${widget.tool.number}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'image/png',
              name: 'benedict_tool_${widget.tool.number}.png',
            ),
          ],
          text:
              'Tool ${widget.tool.number} of Good Works — Daily Company',
          sharePositionOrigin: origin,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Share instrument',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'A quiet card for Messages, mail, or social.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1080 / 1350,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: ToolShareCard(
                          tool: widget.tool,
                          total: widget.total,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _share,
                child: Text(_busy ? 'Preparing…' : 'Share image'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
