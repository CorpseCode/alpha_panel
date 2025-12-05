import 'package:alpha/common/custom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_audio_visualizer/system_audio_visualizer.dart';
import 'package:system_audio_visualizer/visualizer/core/visualizer_type.dart';
import 'package:system_audio_visualizer/visualizer/engine/smoothing.dart';
import 'package:system_audio_visualizer/visualizer/core/visualizer_config.dart';
import 'package:system_audio_visualizer/visualizer/impl/neon_bars.dart';
import 'package:system_audio_visualizer/visualizer/impl/anime_wave.dart';
import 'package:system_audio_visualizer/visualizer/impl/circle_spectrum.dart';

import '../providers/visualizer_theme_provider.dart';

class AudioVisualizerModule extends ConsumerStatefulWidget {
  const AudioVisualizerModule({super.key});

  @override
  ConsumerState<AudioVisualizerModule> createState() =>
      _AudioVisualizerModuleState();
}

class _AudioVisualizerModuleState extends ConsumerState<AudioVisualizerModule> {
  final config = VisualizerConfig();
  late SmoothFilter smoother;

  List<double> bins = List.filled(64, 0);

  @override
  void initState() {
    super.initState();

    smoother = SmoothFilter(64, config.smoothing);
    SystemAudioVisualizer.start();

    SystemAudioVisualizer.fftStream.listen((raw) {
      if (mounted) {
        setState(() => bins = smoother.apply(raw));
      }
    });
  }

  Widget _buildVisualizer(VisualizerType type) {
    switch (type) {
      case VisualizerType.neonBars:
        return NeonBarsVisualizer(
          bins: bins,
          config: config.copyWith(glow: 0, thickness: 2),
        );

      case VisualizerType.animeWave:
        return AnimeWaveVisualizer(
          bins: bins,
          config: config.copyWith(glow: 0, thickness: 4),
        );

      case VisualizerType.circleSpectrum:
        return CircleSpectrumVisualizer(
          bins: bins,
          config: config.copyWith(glow: 0, thickness: 4),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(visualizerThemeProvider);

    return CustomContainer(
      height: 450,
      width: 450,
      child: _buildVisualizer(theme),
    );
  }
}
