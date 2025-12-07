// widgets/system_controls_system.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:alpha/common/custom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:volume_controller/volume_controller.dart';

//
// Riverpod Provider (local)
//
final _volumeProvider = StateProvider<double>((ref) => 0.5);

/// VolumeControl
/// - Purple/violet minimal gradient slider
/// - Hollow outlined thumb
/// - Volume icon with mute/unmute toggle
/// - Numeric percentage display
class VolumeControl extends ConsumerStatefulWidget {
  const VolumeControl({super.key});

  @override
  ConsumerState<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends ConsumerState<VolumeControl> {
  bool _initialized = false;
  Timer? _volDebounce;

  double _preMuteVolume = 0.5;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initVolume();
  }

  Future<void> _initVolume() async {
    try {
      final v = await VolumeController.instance.getVolume();
      if (mounted) {
        final clamped = v.clamp(0.0, 1.0);
        ref.read(_volumeProvider.notifier).state = clamped;
        _preMuteVolume = clamped;
      }

      // system volume listener
      VolumeController.instance.addListener((newV) {
        if (!mounted) return;
        final val = (newV).clamp(0.0, 1.0);
        ref.read(_volumeProvider.notifier).state = val;

        // auto-detect mute (system triggered)
        if (val == 0.0 && !_isMuted) {
          _isMuted = true;
        }
      }, fetchInitialVolume: false);
    } catch (e) {
      debugPrint('Volume init error: $e');
    } finally {
      if (mounted) setState(() => _initialized = true);
    }
  }

  void _setSystemVolume(double v) {
    _volDebounce?.cancel();
    _volDebounce = Timer(const Duration(milliseconds: 40), () async {
      try {
        await VolumeController.instance.setVolume(v.clamp(0.0, 1.0));
      } catch (e) {
        debugPrint('setVolume failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _volDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final volume = ref.watch(_volumeProvider);

    return CustomContainer(
      height: 100,
      width: 450,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: .center,
        children: [
          Row(
            children: [
              // ───────────────────────────────────────────────
              // VOLUME ICON (mute/unmute toggle)
              // ───────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  if (_isMuted) {
                    // Restore
                    _isMuted = false;
                    ref.read(_volumeProvider.notifier).state = _preMuteVolume;
                    _setSystemVolume(_preMuteVolume);
                  } else {
                    // Mute
                    _isMuted = true;
                    _preMuteVolume = volume; // store
                    ref.read(_volumeProvider.notifier).state = 0.0;
                    _setSystemVolume(0.0);
                  }
                  setState(() {});
                },
                child: Icon(
                  (_isMuted || volume == 0.0)
                      ? Icons.volume_off
                      : Icons.volume_up,
                  size: 26,
                  color: Colors.white54,
                ),
              ),

              const SizedBox(width: 16),

              // ───────────────────────────────────────────────
              // SLIDER
              // ───────────────────────────────────────────────
              Expanded(
                child: _PurpleGradientSlider(
                  value: volume,
                  onChanged: (v) {
                    if (_isMuted && v > 0) {
                      _isMuted = false; // user restored volume manually
                    }
                    ref.read(_volumeProvider.notifier).state = v;
                    _setSystemVolume(v);
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(width: 16),

              // ───────────────────────────────────────────────
              // PERCENT NUMBER
              // ───────────────────────────────────────────────
              _ValueNumber(value: volume),
            ],
          ),

          if (!_initialized)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                "initializing…",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

//
// ───────────────────────────────────────────────────────────
// UI HELPERS
// ───────────────────────────────────────────────────────────
//

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
// PURPLE GRADIENT SLIDER
// ───────────────────────────────────────────────────────────
//

class _PurpleGradientSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _PurpleGradientSlider({required this.value, required this.onChanged});

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
  void didUpdateWidget(covariant _PurpleGradientSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_drag) _local = widget.value;
  }

  void _update(Offset global, RenderBox box) {
    final local = box.globalToLocal(global);
    final width = math.max(1.0, box.size.width);
    double v = (local.dx / width).clamp(0.0, 1.0).toDouble();
    setState(() => _local = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: LayoutBuilder(
        builder: (context, constraints) {
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
              painter: _PurpleGradientSliderPainter(value: _local),
            ),
          );
        },
      ),
    );
  }
}

class _PurpleGradientSliderPainter extends CustomPainter {
  final double value;
  const _PurpleGradientSliderPainter({required this.value});

  static const double trackHeight = 5.0;
  static const double thumbRadius = 9.0;

  LinearGradient get gradient => const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5B2E8A), Color(0xFF7C3AED), Color(0xFF9B6CFA)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final trackTop = (size.height - trackHeight) / 2;
    final trackRect = Rect.fromLTWH(0, trackTop, size.width, trackHeight);

    // inactive
    final inactive = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
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

    // thumb
    final thumbCenter = Offset(activeWidth, size.height / 2);

    final inner = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(thumbCenter, thumbRadius, inner);
    canvas.drawCircle(thumbCenter, thumbRadius, outline);
  }

  @override
  bool shouldRepaint(covariant _PurpleGradientSliderPainter old) =>
      old.value != value;
}
