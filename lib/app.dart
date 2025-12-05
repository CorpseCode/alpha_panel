import 'package:alpha/services/hotkey.dart';
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
  bool _lastVisibleState = true; // prevents repeated triggers
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

    // Fade in on startup
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });

    // 🔥 Add window manager listener (new)
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this); // 🔥 cleanup
    _controller.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // 🔥 NEW: hide panel (toggle off) when window loses focus
  // --------------------------------------------------
  @override
  void onWindowBlur() {
    if (_handlingBlur) return;
    _handlingBlur = true;

    final visible = ref.read(toggleProvider);
    if (visible) {
      ref.read(toggleProvider.notifier).disable();
    }

    _handlingBlur = false;
  }

  // --------------------------------------------------
  // unchanged
  // --------------------------------------------------
  Future<void> _animateBasedOnState(bool visible) async {
    // Avoid double-calls
    if (visible == _lastVisibleState) return;
    _lastVisibleState = visible;

    if (visible) {
      await windowManager.show();
      await windowManager.focus();
      await _controller.forward();
    } else {
      await _controller.reverse();
      await windowManager.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    registerRiverpodRef(ref);
    final visible = ref.watch(toggleProvider);

    // Trigger animation ONLY when provider changes
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
          color: const Color.fromARGB(130, 127, 0, 23),
        ),
        child: const AppContent(),
      ),
    );
  }
}
