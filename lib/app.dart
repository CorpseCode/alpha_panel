import 'package:alpha/services/hotkey.dart';
import 'package:alpha/services/smtc_service.dart';
import 'package:alpha/ui/app_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

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
      ref.read(toggleProvider.notifier).disable();
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
      await SmtcService.instance.resume();
    }
  }

  // -------------------------------------------------------------------------
  Future<void> _animateBasedOnState(bool visible) async {
    if (visible == _lastVisibleState) return;
    _lastVisibleState = visible;

    if (visible) {
      await windowManager.show();
      await windowManager.focus();

      await SmtcService.instance.resume();

      await _controller.forward();
    } else {
      // 1. Reverse animation
      await _controller.reverse();

      // 2. Hide window
      await windowManager.hide();

      // 3. Freeze AFTER everything is invisible
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
        padding: const EdgeInsets.all(20),
        height: 900,
        width: 1800,
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.systemCyan.withAlpha(120),
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(130, 0, 104, 80),
        ),
        child: const AppContent(),
      ),
    );
  }
}
