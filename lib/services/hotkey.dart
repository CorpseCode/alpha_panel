// import 'package:alpha/providers/global_providers.dart';
import 'package:alpha/providers/toggle_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
// import 'package:window_manager/window_manager.dart';

final HotKey toggleOn = HotKey(
  key: PhysicalKeyboardKey.backquote, // `
  modifiers: [HotKeyModifier.meta], // Win + `
  scope: HotKeyScope.system,
);

final HotKey toggleOff = HotKey(
  key: PhysicalKeyboardKey.escape,
  scope: HotKeyScope.inapp,
);

Future<void> registerHotkeys() async {
  // Ensure the manager is initialized
  await hotKeyManager.unregisterAll();

  // Register Toggle ON
  await hotKeyManager.register(
    toggleOn,
    keyDownHandler: (hotKey) {
      onToggle();
    },
  );

  // Register Toggle OFF
  await hotKeyManager.register(
    toggleOff,
    keyDownHandler: (hotKey) {
      onToggleOff();
    },
  );
}

late WidgetRef _appRef;

// called from build() so hotkeys mutate the SAME provider tree
void registerRiverpodRef(WidgetRef ref) {
  _appRef = ref;
}


void onToggle() {
  // Your logic when Win + ` is pressed system-wide
  _appRef.read(toggleProvider.notifier).toggle();
  if (kDebugMode) print('toggled');
  // windowManager.show();
}

void onToggleOff() {
  // Your logic when Esc is pressed inside your app
  _appRef.read(toggleProvider.notifier).disable();
  if (kDebugMode) print('toggle off');
}

Future<void> disposeHotkeys() async {
  await hotKeyManager.unregister(toggleOn);
  await hotKeyManager.unregister(toggleOff);
}
