import 'package:alpha/features/vault/providers/vault_setup_provider.dart';
import 'package:alpha/features/vault/ui/vault_setup_panel.dart';
import 'package:alpha/services/hotkey.dart';
import 'package:alpha/services/tray.dart';
import 'package:alpha/services/smtc_service.dart';
import 'package:alpha/ui/app_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_audio_visualizer/system_audio_visualizer.dart';

import 'providers/toggle_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App>
    with SingleTickerProviderStateMixin, WindowListener {
  late AnimationController _controller;
  late Animation<double> _fade;

  bool _firstFrame = true;
  bool _lastVisibleState = true;
  bool _animating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _controller.forward();

      // Start SMTC daemon ONCE
      await SmtcService.instance.start();
      SystemAudioVisualizer.start();
    });

    windowManager.addListener(this);
  }

  @override
  void dispose() {
    if (_controller.isAnimating || _controller.value != 0.0) {
      _controller.stop();
    }

    try {
      _controller.dispose();
    } catch (_) {}

    try {
      windowManager.removeListener(this);
    } catch (_) {}

    super.dispose();
  }

  @override
  void onWindowBlur() async {
    final visible = ref.read(toggleProvider);

    // If panel open and user switches away
    if (visible) {
      // ref.read(toggleProvider.notifier).disable();
      SystemAudioVisualizer.stop();
    }

    // IMPORTANT:
    // DO NOT CLOSE SMTC
    // DO NOT RESTART
  }

  @override
  void onWindowFocus() async {
    final visible = ref.read(toggleProvider);

    // if visible → only resume visualizer
    if (visible) {
      SystemAudioVisualizer.start();
    }

    // DO NOT restart SMTC here
  }

  Future<void> _animateVisibility(bool visible) async {
    if (_animating) return;
    _animating = true;

    if (visible == _lastVisibleState) {
      _animating = false;
      return;
    }

    _lastVisibleState = visible;

    if (visible) {
      // window fully visible
      await windowManager.show();
      await windowManager.focus();

      // restart SMTC ONLY ON SHOW
      await SmtcService.instance.restart();

      // visualizer follows UI
      SystemAudioVisualizer.start();

      await _controller.forward();
    } else {
      SystemAudioVisualizer.stop();

      await _controller.reverse();
      await windowManager.hide();

      // DO NOT kill SMTC
    }

    _animating = false;
  }

  @override
  Widget build(BuildContext context) {
    registerRiverpodRef(ref);
    registerTrayRef(ref);
    final needsSetup = ref.watch(needsVaultSetupProvider);
    final visible = ref.watch(toggleProvider);

    // Toggle is controlled indirectly by onWindowBlur
    if (!_firstFrame) {
      _animateVisibility(visible);
    }
    _firstFrame = false;

    return FadeTransition(
      opacity: _fade,
      child: Stack(
        // padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
        // height: 1000,
        // width: 1900,
        // decoration: BoxDecoration(
        //   border: Border.all(
        //     color: CupertinoColors.systemCyan.withAlpha(110),
        //     width: 2.0,
        //   ),
        //   borderRadius: BorderRadius.circular(10),
        //   color: const Color.fromARGB(130, 0, 38, 104),
        // ),
        children: <Widget>[
          const AppContent(),
          if (needsSetup) VaultSetupPanel(),
        ],
      ),
    );
  }
}
