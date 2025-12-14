import 'package:alpha/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class AppWrap extends ConsumerWidget {
  final Widget child;
  final EdgeInsets padding;
  final double width;
  final double height;

  const AppWrap({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    this.padding = const EdgeInsets.fromLTRB(10, 10, 10, 20),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(appStyleProvider);

    return Container(
      padding: padding,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
        borderRadius: style.borderRadius,
      ),
      child: child,
    );
  }
}
