import 'dart:ui';

import 'package:alpha/common/custom_container.dart';
import 'package:alpha/providers/app_settings_panel_provider.dart';
import 'package:alpha/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettingsPanel extends ConsumerWidget {
  const AppSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(appStyleProvider);
    final ctrl = ref.read(appStyleProvider.notifier);
    final open = ref.watch(appSettingsPanelOpenProvider);

    return AnimatedSlide(
      offset: open ? Offset.zero : const Offset(1.05, 0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: open ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: Align(
          alignment: Alignment.centerRight,
          child: CustomContainer(
            width: 420,
            height: double.infinity,
            margin: const EdgeInsets.only(top: 50),
            padding: const EdgeInsets.all(18),
            backgroundColor: style.backgroundColor,
            borderColor: style.borderColor,
            glow: style.borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 26),

                _Section(
                  title: "Background",
                  subtitle: "Panel surface & transparency",
                  preview: style.backgroundColor,
                  child: HueAlphaPicker(
                    color: style.backgroundColor,
                    onChanged: ctrl.setBackground,
                  ),
                ),

                const SizedBox(height: 24),

                _Section(
                  title: "Border",
                  subtitle: "Outline & glow accent",
                  preview: style.borderColor,
                  child: HueAlphaPicker(
                    color: style.borderColor,
                    onChanged: ctrl.setBorder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Appearance",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: 6),
        Divider(
          thickness: 1,
          color: Color(0x33FFFFFF),
        ),
      ],
    );
  }
}

/* ────────────────────────────────────────────── */
/* SECTION WRAPPER                                */
/* ────────────────────────────────────────────── */

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color preview;
  final Widget child;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:  Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _ColorPreview(preview),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  final Color color;

  const _ColorPreview(this.color);

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      width: 28,
      height: 28,
      radius: 6,
      backgroundColor: color,
      borderColor: Colors.white.withValues(alpha: 0.25),
      borderWidth: 1.2,
      child: const SizedBox.shrink(),
    );
  }
}

/* ────────────────────────────────────────────── */
/* HUE + ALPHA PICKER                             */
/* ────────────────────────────────────────────── */

class HueAlphaPicker extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onChanged;

  const HueAlphaPicker({
    super.key,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(color);

    return Column(
      children: [
        _GradientSlider(
          value: hsv.hue,
          max: 360,
          gradient: const [
            Colors.red,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
          onChanged: (v) {
            onChanged(hsv.withHue(v).toColor().withValues(alpha: color.opacity));
          },
        ),
        const SizedBox(height: 12),
        _GradientSlider(
          value: color.a,
          max: 1,
          gradient: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 1),
          ],
          onChanged: (v) {
            onChanged(color.withValues(alpha: v));
          },
        ),
      ],
    );
  }
}

/* ────────────────────────────────────────────── */
/* GRADIENT SLIDER                                */
/* ────────────────────────────────────────────── */

class _GradientSlider extends StatelessWidget {
  final double value;
  final double max;
  final List<Color> gradient;
  final ValueChanged<double> onChanged;

  const _GradientSlider({
    required this.value,
    required this.max,
    required this.gradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(colors: gradient),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            trackShape: const RoundedRectSliderTrackShape(),
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const _GlowThumb(),
          ),
          child: Slider(
            value: value.clamp(0, max),
            min: 0,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/* ────────────────────────────────────────────── */
/* CUSTOM GLOW THUMB                              */
/* ────────────────────────────────────────────── */

class _GlowThumb extends SliderComponentShape {
  const _GlowThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(16, 16);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = Colors.white
        ..isAntiAlias = true,
    );

    canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = Colors.cyan.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
}
