import 'package:flutter_riverpod/legacy.dart';

enum SidePanelTab {
  none,
  bluetooth,
  wifi,
}

final sidePanelTabProvider =
    StateProvider<SidePanelTab>((ref) => SidePanelTab.none);
