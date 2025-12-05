import 'dart:io';
import 'package:launch_at_startup/launch_at_startup.dart';

/// Fully isolated startup module with no external dependencies.
/// You define the appName manually below.
class Startup {
  static bool _initialized = false;

  // Set this once. It will not change unless *you* change it.
  static const String appName = "Alpha";

  /// Initialize launch_at_startup configuration.
  static Future<void> init() async {
    if (_initialized) return;

    launchAtStartup.setup(
      appName: appName,
      appPath: Platform.resolvedExecutable,
      // packageName is only needed for MSIX packaged Windows apps
      // so we keep it out for isolation.
    );

    _initialized = true;
  }

  static Future<void> enable() async {
    if (!_initialized) await init();
    await launchAtStartup.enable();
  }

  static Future<void> disable() async {
    if (!_initialized) await init();
    await launchAtStartup.disable();
  }

  static Future<bool> status() async {
    if (!_initialized) await init();
    return await launchAtStartup.isEnabled();
  }
}
