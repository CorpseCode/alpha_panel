import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alpha/providers/sidebar_provider.dart';

class SidebarOverlay extends ConsumerWidget {
  const SidebarOverlay({super.key, required this.child});

  final Widget child; // This will be your column of buttons etc.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(sidebarProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: visible ? 0 : -450,
      bottom: 0,
      width: 400,
      child: child,
    );
  }
}
