// widgets/brightness_control.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:alpha/common/custom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

//
// Riverpod Brightness Provider
//
final brightnessProvider = StateProvider<double>((ref) => 1.0);

///
/// BrightnessControl
/// - Purple gradient slider
/// - Hollow outlined thumb
/// - Large smooth UI
/// - Value number to the right
/// - Uses elevated PowerShell WMI
///
class BrightnessControl extends ConsumerStatefulWidget {
  const BrightnessControl({super.key});

  @override
  ConsumerState<BrightnessControl> createState() => _BrightnessControlState();
}

class _BrightnessControlState extends ConsumerState<BrightnessControl> {
  bool initialized = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initBrightness();
  }

  // -------------------------------------------------------------------
  // GET CURRENT BRIGHTNESS FROM WINDOWS (0–100)
  // -------------------------------------------------------------------
  Future<int> _getSystemBrightness() async {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness).CurrentBrightness',
    ]);

    if (result.stdout is String) {
      return int.tryParse(result.stdout.trim()) ?? 50;
    }
    return 50;
  }

  // -------------------------------------------------------------------
  // SET BRIGHTNESS USING WMI (0–100)
  // -------------------------------------------------------------------
  Future<void> _setSystemBrightness(int value) async {
    final ps =
        '''
      (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, $value)
    ''';

    await Process.start('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      ps,
    ]);
  }

  // -------------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------------
  Future<void> _initBrightness() async {
    try {
      // initial fetch
      final b = await _getSystemBrightness();
      ref.read(brightnessProvider.notifier).state = (b / 100).clamp(0, 1);

      // periodic syncing from system
      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final sysVal = await _getSystemBrightness();
        final sysNorm = (sysVal / 100).clamp(0, 1).toDouble();

        final current = ref.read(brightnessProvider);

        // if slider wasn't manually moved, update it
        if ((sysNorm - current).abs() > 0.01) {
          ref.read(brightnessProvider.notifier).state = sysNorm;
        }
      });
    } catch (e) {
      debugPrint("Brightness init error: $e");
    }

    if (mounted) setState(() => initialized = true);
  }

  // -------------------------------------------------------------------
  // DEBOUNCED BRIGHTNESS APPLY
  // -------------------------------------------------------------------
  void _applyBrightness(double v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () async {
      await _setSystemBrightness((v * 100).round());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final brightness = ref.watch(brightnessProvider);

    return CustomContainer(
      height: 100,
      width: 450,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: [
            Icon(Icons.brightness_7_outlined, color: Colors.white54, size: 20),
            const SizedBox(width: 20),
            Expanded(
              child: _PurpleGradientSlider(
                value: brightness,
                onChanged: (v) {
                  ref.read(brightnessProvider.notifier).state = v;
                  _applyBrightness(v);
                },
              ),
            ),
            const SizedBox(width: 20),
            _ValueNumber(value: brightness),
          ],
        ),
      ),
    );
  }
}

class _ValueNumber extends StatelessWidget {
  final double value;
  const _ValueNumber({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      "${(value * 100).round()}",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.none,
      ),
    );
  }
}

//
// ───────────────────────────────────────────────────────────
// SLIDER (purple/violet gradient + hollow thumb)
// ───────────────────────────────────────────────────────────
//

class _PurpleGradientSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _PurpleGradientSlider({
    required this.value,
    required this.onChanged,
    // super.key,
  });

  @override
  State<_PurpleGradientSlider> createState() => _PurpleGradientSliderState();
}

class _PurpleGradientSliderState extends State<_PurpleGradientSlider> {
  double _local = 0.0;
  bool _drag = false;

  @override
  void initState() {
    super.initState();
    _local = widget.value;
  }

  @override
  void didUpdateWidget(covariant _PurpleGradientSlider old) {
    super.didUpdateWidget(old);
    if (!_drag) _local = widget.value;
  }

  void _update(Offset global, RenderBox box) {
    final local = box.globalToLocal(global);
    final width = math.max(1.0, box.size.width);
    double v = (local.dx / width).clamp(0, 1);
    setState(() => _local = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: LayoutBuilder(
        builder: (_, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (d) {
              _drag = true;
              final box = context.findRenderObject() as RenderBox;
              _update(d.globalPosition, box);
            },
            onPanUpdate: (d) {
              final box = context.findRenderObject() as RenderBox;
              _update(d.globalPosition, box);
            },
            onPanEnd: (_) => _drag = false,
            onTapDown: (d) {
              final box = context.findRenderObject() as RenderBox;
              _update(d.globalPosition, box);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, 36),
              painter: _PurpleSliderPainter(value: _local),
            ),
          );
        },
      ),
    );
  }
}

class _PurpleSliderPainter extends CustomPainter {
  final double value;

  const _PurpleSliderPainter({required this.value});

  static const double trackHeight = 5.0;
  static const double thumbRadius = 9.0;

  LinearGradient get gradient => const LinearGradient(
    colors: [
      Color(0xFF5B2E8A), // deep violet
      Color(0xFF7C3AED), // violet
      Color(0xFF9B6CFA), // soft purple
    ],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final trackTop = (size.height - trackHeight) / 2;
    final trackRect = Rect.fromLTWH(0, trackTop, size.width, trackHeight);

    // inactive
    final inactive = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(4)),
      inactive,
    );

    // active
    final activeWidth = (size.width * value).clamp(0.0, size.width).toDouble();
    if (activeWidth > 0) {
      final activeRect = Rect.fromLTWH(0, trackTop, activeWidth, trackHeight);

      final paint = Paint()
        ..shader = gradient.createShader(activeRect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(activeRect, const Radius.circular(4)),
        paint,
      );
    }

    // hollow thumb
    final thumbCenter = Offset(activeWidth, size.height / 2);

    final inner = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(thumbCenter, thumbRadius, inner);
    canvas.drawCircle(thumbCenter, thumbRadius, outline);
  }

  @override
  bool shouldRepaint(covariant _PurpleSliderPainter old) => old.value != value;
}
