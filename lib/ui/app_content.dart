import 'package:alpha/widgets/brightness_controller.dart';
import 'package:alpha/widgets/now_playing_panel.dart';
import 'package:alpha/widgets/volume_controller.dart';
import 'package:alpha/widgets/av_panel.dart';
import 'package:flutter/material.dart';

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: .start,
          mainAxisAlignment: .spaceBetween,
          children: [
            AudioVisualizerModule(),
            NowPlayingPanel(),
            VolumeControl(),
            BrightnessControl(),
          ],
        ),
      ],
    );
  }
}
