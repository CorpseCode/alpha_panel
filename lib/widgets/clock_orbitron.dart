// clock/orbitron_clock.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrbitronClock extends StatefulWidget {
  const OrbitronClock({super.key});

  @override
  State<OrbitronClock> createState() => _OrbitronClockState();
}

class _OrbitronClockState extends State<OrbitronClock> {
  bool is24hr = true;

  Stream<DateTime> _timeStream() {
    return Stream<DateTime>.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    ).startWith(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Column(
        mainAxisAlignment: .start,
        crossAxisAlignment: .start,
        children: [
          /// CLOCK SECTION (left aligned)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: StreamBuilder<DateTime>(
                stream: _timeStream(),
                builder: (context, snapshot) {
                  final now = snapshot.data ?? DateTime.now();

                  int hour = now.hour;
                  String suffix = "";

                  if (!is24hr) {
                    suffix = hour >= 12 ? " PM" : " AM";
                    hour = hour % 12;
                    if (hour == 0) hour = 12;
                  }

                  final hh = hour.toString().padLeft(2, '0');
                  final mm = now.minute.toString().padLeft(2, '0');
                  final ss = now.second.toString().padLeft(2, '0');

                  final timeText = "$hh:$mm:$ss$suffix";

                  return Text(
                    timeText,
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1.2
                        ..color = Colors.cyanAccent.withValues(alpha: 0.85),
                    ),
                  );
                },
              ),
            ),
          ),

          Row(
            mainAxisAlignment: .start,
            children: [
              _modeButton(
                "24",
                isSelected: is24hr,
                onTap: () {
                  setState(() => is24hr = true);
                },
              ),

              _modeButton(
                "12",
                isSelected: !is24hr,
                onTap: () {
                  setState(() => is24hr = false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    String label, {
    required bool isSelected,
    required void Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected
                ? Colors.cyanAccent.withValues(alpha: 0.9)
                : Colors.white24,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.cyanAccent : Colors.white70,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

// Simple extension so StreamBuilder has an initial value immediately
extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
