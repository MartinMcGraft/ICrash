import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../services/code_scanner_service.dart';
import '../icons/ic_icons.dart';
import '../theme/tokens.dart';

/// Figma "Câmara": navy rounded viewport, dashed 300 px frame, caption.
/// Shows the live camera, or — on desktop — a field a USB reader types into.
class ScannerViewport extends StatefulWidget {
  const ScannerViewport({super.key, required this.scanner, required this.caption});

  final CodeScannerService scanner;
  final String caption;

  @override
  State<ScannerViewport> createState() => _ScannerViewportState();
}

class _ScannerViewportState extends State<ScannerViewport> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = widget.scanner;
    return ClipRRect(
      borderRadius: BorderRadius.circular(IcRadius.xl),
      child: ColoredBox(
        color: IcColors.bgSidebar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (scanner is CameraCodeScannerService) MobileScanner(controller: scanner.controller),
            LayoutBuilder(
              builder: (context, constraints) {
                final frame = min(300.0, min(constraints.maxWidth, constraints.maxHeight) - 80).clamp(120.0, 300.0);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: frame,
                      child: CustomPaint(
                        painter: const _DashedFramePainter(),
                        child: scanner is KeyboardCodeScannerService ? _keyboardInput(context, scanner) : null,
                      ),
                    ),
                    const SizedBox(height: IcSpace.s16),
                    Text(widget.caption, style: IcText.labelM.copyWith(color: IcColors.textOnDark), textAlign: TextAlign.center),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _keyboardInput(BuildContext context, KeyboardCodeScannerService scanner) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(IcSpace.s16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const IcIconView(IcIcon.teclado, size: 32, color: IcColors.textOnDarkMuted),
          const SizedBox(height: IcSpace.s12),
          TextField(
            controller: _input,
            focusNode: _focus,
            autofocus: true,
            style: IcText.bodyM,
            decoration: InputDecoration(hintText: l10n.scannerUsbHint),
            onSubmitted: (value) {
              scanner.feedLine(value);
              _input.clear();
              _focus.requestFocus();
            },
          ),
        ],
      ),
    );
  }
}

class _DashedFramePainter extends CustomPainter {
  const _DashedFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)));
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, min(d + 24, metric.length)), paint);
        d += 38;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedFramePainter oldDelegate) => false;
}
