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

  const CustomContainer({
    super.key,
    required this.height,
    required this.width,
    required this.child,
    this.backgroundColor = const Color(0x1A000000), // black26
    this.borderColor = const Color(0x8032FFFF), // cyan with alpha
    this.borderWidth = 2.0,
    this.radius = 10.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(width: borderWidth, color: borderColor),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}
