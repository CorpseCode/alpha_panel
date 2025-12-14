import 'package:alpha/widgets/app_settings_toggle.dart';
import 'package:alpha/widgets/settings_panel.dart';

import 'app_wrap.dart';
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
    return AppWrap(
      width: 1900,
      height: 1000,
      child: Stack(
        children: [
          // top bar
          TopBar(rightItems: [AppSettingsToggle()],),

          // main content
          Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
            ),
          ),
          AppSettingsPanel()
        ],
      ),
    );
  }
}
