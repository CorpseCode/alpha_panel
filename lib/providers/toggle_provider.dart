import 'package:flutter_riverpod/flutter_riverpod.dart';

class ToggleNotifier extends Notifier<bool> {
  @override
  bool build() => true; // initial state

  // void toggle() => state = !state;

  void enable() => state = true;

  void disable() => state = false;
}

final toggleProvider = NotifierProvider<ToggleNotifier, bool>(
  ToggleNotifier.new,
);
