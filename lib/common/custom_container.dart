import 'package:flutter/material.dart';

class CustomContainer extends StatelessWidget {
  final double height;
  final double width;
  final Widget child;

  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Optional glow color (null = no glow)
  final Color? glow;

  const CustomContainer({
    super.key,
    required this.height,
    required this.width,
    required this.child,
    this.backgroundColor = const Color(0x1A000000),
    this.borderColor = const Color(0x8032FFFF),
    this.borderWidth = 2.0,
    this.radius = 10.0,
    this.padding,
    this.margin,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: glow == null ? 0.0 : 1.0,
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          height: height,
          width: width,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              width: borderWidth,
              color: borderColor,
            ),
            boxShadow: glow == null
                ? null
                : [
                    BoxShadow(
                      color: glow!.withValues(alpha: 0.35 * value),
                      blurRadius: 18 * value,
                      spreadRadius: 2 * value,
                    ),
                  ],
          ),
          child: child,
        );
      },
    );
  }
}
