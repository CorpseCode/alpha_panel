import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/providers/app_settings_panel_provider.dart';

class AppSettingsToggle extends ConsumerWidget {
  const AppSettingsToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(appSettingsPanelOpenProvider);

    return IconButton(
      tooltip: "Appearance Settings",
      icon: Icon(
        Icons.tune_rounded,
        size: 20,
        color: open
            ? Colors.cyanAccent
            : Colors.white.withValues(alpha: 0.8),
      ),
      onPressed: () {
        ref.read(appSettingsPanelOpenProvider.notifier).state = !open;
      },
    );
  }
}
