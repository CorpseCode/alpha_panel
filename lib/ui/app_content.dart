import 'package:alpha/ui/sidebar.dart';
import 'package:alpha/ui/top_bar.dart';
import 'package:alpha/widgets/brightness_controller.dart';
import 'package:alpha/widgets/clock_orbitron.dart';
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
        // main top bar
        TopBar(),

        // main left side
        SidebarOverlay(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AudioVisualizerModule(),
              NowPlayingPanel(),
              VolumeControl(),
              BrightnessControl(),
              OrbitronClock(),
            ],
          ),
        ),
      ],
    );
  }
}
