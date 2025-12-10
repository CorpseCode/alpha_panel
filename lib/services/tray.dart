import 'package:alpha/providers/toggle_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

final SystemTray tray = SystemTray();
final AppWindow appWindow = AppWindow();

late WidgetRef _appRef;

// called from build() so hotkeys mutate the SAME provider tree
void registerTrayRef(WidgetRef ref) {
  _appRef = ref;
}

Future<void> initSystemTray() async {
  await tray.initSystemTray(title: "ALPHA", iconPath: "assets/tray_icon.ico");

  final Menu menu = Menu();

  await menu.buildFrom([
    MenuItemLabel(
      name: 'ALPHA',
      label: "Exit",
      onClicked: (_) async {
        await windowManager.close();
      },
    ),
  ]);

  await tray.setContextMenu(menu);

  tray.registerSystemTrayEventHandler((event) async {
    if (event == kSystemTrayEventClick) {
      await windowManager.show();
      await windowManager.focus();
      _appRef.read(toggleProvider.notifier).enable();
    }
    if (event == kSystemTrayEventRightClick){
     tray.popUpContextMenu();
    }
  });
}
