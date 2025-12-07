import 'package:alpha/common/custom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sidebar_provider.dart';

class TopBar extends ConsumerStatefulWidget {
  final List<Widget> rightItems;

  const TopBar({super.key, this.rightItems = const []});

  @override
  ConsumerState<TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  void _toggle() {
    final isOpen = ref.read(sidebarProvider);
    ref.read(sidebarProvider.notifier).state = !isOpen;

    if (isOpen) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = ref.watch(sidebarProvider);

    if (open && !_ctrl.isCompleted) _ctrl.forward();
    if (!open && !_ctrl.isDismissed) _ctrl.reverse();

    return CustomContainer(
      width: double.infinity,
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          // TOGGLE BLOCK
          _toggleBlock(),

          // OTHER CONTENT
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.rightItems,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBlock() {
    final open = ref.watch(sidebarProvider);

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 62,
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          color: open
              ? Colors.white.withValues(
                  alpha: 0.06,
                ) // highlighted only when open
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Icon(
            open ? Icons.close_rounded : Icons.menu_rounded,
            key: ValueKey<bool>(open),
            size: 22,
            color: open
                ? Colors.redAccent.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  // Widget _animatedIcon() {
  //   return AnimatedSwitcher(
  //     duration: const Duration(milliseconds: 200),
  //     transitionBuilder: (child, anim) =>
  //         FadeTransition(opacity: anim, child: child),
  //     child: Icon(
  //       _ctrl.value > 0.5 ? Icons.close_rounded : Icons.menu_rounded,
  //       key: ValueKey<bool>(_ctrl.value > 0.5),
  //       size: 22,
  //       color: _ctrl.value > 0.5
  //           ? Colors.redAccent.withValues(alpha: 0.9)
  //           : Colors.white.withValues(alpha: 0.9),
  //     ),
  //   );
  // }
}
