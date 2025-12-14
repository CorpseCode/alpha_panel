import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AppStyleState {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;

  const AppStyleState({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  AppStyleState copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
  }) {
    return AppStyleState(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }
}

class AppStyleController extends Notifier<AppStyleState> {
  @override
  AppStyleState build() {
    // 👇 EXACTLY your current hardcoded values
    return AppStyleState(
      backgroundColor: const Color.fromARGB(130, 0, 38, 104),
      borderColor: Colors.cyan.withAlpha(110),
      borderWidth: 2.0,
      borderRadius: BorderRadius.circular(10),
    );
  }

  // Optional setters for later use
  void setBackground(Color color) {
    state = state.copyWith(backgroundColor: color);
  }

  void setBorder(Color color) {
    state = state.copyWith(borderColor: color);
  }
}

final appStyleProvider =
    NotifierProvider<AppStyleController, AppStyleState>(
  AppStyleController.new,
);
