import 'package:alpha/services/tray.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alpha/startup/startup.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'init/window_init.dart';
import 'app.dart';
import 'services/hotkey.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required by window_manager before any window calls
  await windowManager.ensureInitialized();
  // await hotKeyManager.unregisterAll();
  // Modular window initialization
  await registerHotkeys();
  await WindowInit.initialize();

  await Startup.init();

  runApp(
    const ProviderScope(
      child: MaterialApp(debugShowCheckedModeBanner: false, home: App()),
    ),
  );
  await initSystemTray();
}
