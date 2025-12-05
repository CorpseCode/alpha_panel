import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

final SystemTray tray = SystemTray();
final AppWindow appWindow = AppWindow();

Future<void> initSystemTray() async {
  await tray.initSystemTray(title: "ALPHA", iconPath: "assets/tray_icon.ico");

  final Menu menu = Menu();

  await menu.buildFrom([
    MenuSeparator(),
    MenuItemLabel(
      label: "Exit",
      onClicked: (_) async {
        await windowManager.close();
      },
    ),
    MenuSeparator(),
  ]);

  await tray.setContextMenu(menu);

  tray.registerSystemTrayEventHandler((event) async {
    if (event == kSystemTrayEventClick) {
      await windowManager.show();
      await windowManager.focus();
    }
  });
}
