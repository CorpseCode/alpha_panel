import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_audio_visualizer/visualizer/core/visualizer_type.dart';

class VisualizerThemeNotifier extends Notifier<VisualizerType> {
  @override
  VisualizerType build() => VisualizerType.circleSpectrum;

  void setTheme(VisualizerType newType) {
    state = newType;
  }

  void nextTheme() {
    final all = VisualizerType.values;
    final idx = all.indexOf(state);
    final next = all[(idx + 1) % all.length];
    state = next;
  }
}

final visualizerThemeProvider =
    NotifierProvider<VisualizerThemeNotifier, VisualizerType>(
      VisualizerThemeNotifier.new,
    );
