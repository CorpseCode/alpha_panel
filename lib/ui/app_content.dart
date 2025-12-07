import 'package:alpha/ui/sidebar.dart';
import 'package:alpha/ui/top_bar.dart';
import 'package:alpha/widgets/brightness_controller.dart';
import 'package:alpha/widgets/now_playing_panel.dart';
import 'package:alpha/widgets/volume_controller.dart';
import 'package:alpha/widgets/av_panel.dart';
import 'package:flutter/material.dart';

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TopBar(),
        SidebarOverlay(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisAlignment: .spaceBetween,
            children: [
              AudioVisualizerModule(),
              NowPlayingPanel(),
              VolumeControl(),
              BrightnessControl(),
            ],
          ),
        ),
      ],
    );
  }
}
