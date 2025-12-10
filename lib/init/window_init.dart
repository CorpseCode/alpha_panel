import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowInit {
  static Future<void> initialize() async {
    const size = Size(1900, 1000);

    final options = WindowOptions(
      size: size,
      center: true,
      alwaysOnTop: kDebugMode? false : true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setHasShadow(false);
      await windowManager.setResizable(false);
      await windowManager.setMinimumSize(size);
      await windowManager.setMaximumSize(size);
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
