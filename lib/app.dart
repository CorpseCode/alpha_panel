import 'package:alpha/services/hotkey.dart';
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
  bool _handlingBlur = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _controller.forward();
      await SmtcService.instance.start(); // start initially
      // optional: start visualizer here too if you want it active on first show
      SystemAudioVisualizer.start();
    });

    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _controller.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // WINDOW BLUR
  // -------------------------------------------------------------------------
  @override
  void onWindowBlur() async {
    if (_handlingBlur) return;
    _handlingBlur = true;

    final visible = ref.read(toggleProvider);

    if (visible) {
      // toggle off panel
      ref.read(toggleProvider.notifier).disable();

      // 1) stop AV first
      SystemAudioVisualizer.stop();

      // 2) then freeze SMTC
      await SmtcService.instance.freeze();
    }

    _handlingBlur = false;
  }

  // -------------------------------------------------------------------------
  // WINDOW FOCUS
  // -------------------------------------------------------------------------
  @override
  void onWindowFocus() async {
    final visible = ref.read(toggleProvider);
    if (visible) {
      // 1) resume SMTC
      await SmtcService.instance.resume();

      // 2) resume AV
      SystemAudioVisualizer.start();
    }
  }

  // -------------------------------------------------------------------------
  // ANIMATION BASED ON GLOBAL TOGGLE STATE
  // -------------------------------------------------------------------------
  Future<void> _animateBasedOnState(bool visible) async {
    if (visible == _lastVisibleState) return;
    _lastVisibleState = visible;

    if (visible) {
      await windowManager.show();
      await windowManager.focus();

      // resume SMTC + visualizer before fade-in finishes
      await SmtcService.instance.resume();
      SystemAudioVisualizer.start();

      await _controller.forward();
    } else {
      // stop AV immediately when we start hiding
      SystemAudioVisualizer.stop();

      // run fade-out
      await _controller.reverse();

      // hide window
      await windowManager.hide();

      // freeze SMTC after it's fully invisible
      await SmtcService.instance.freeze();
    }
  }

  @override
  Widget build(BuildContext context) {
    registerRiverpodRef(ref);

    final visible = ref.watch(toggleProvider);

    if (!_firstFrame) {
      _animateBasedOnState(visible);
    }
    _firstFrame = false;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        height: 900,
        width: 1800,
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.systemCyan.withAlpha(120),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(130, 0, 38, 104),
        ),
        child: const AppContent(),
      ),
    );
  }
}
