// lib/widgets/now_playing_panel.dart
import 'dart:convert';
import 'dart:ffi';
import 'package:alpha/common/custom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../providers/smtc_provider.dart';

// -----------------------------------------------------------
// MEDIA KEY FUNCTION
// -----------------------------------------------------------
void _sendMediaKey(int vk) {
  final inputs = calloc<INPUT>(2);

  // KEYDOWN
  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = vk;
  inputs[0].ki.dwFlags = 0;

  // KEYUP
  inputs[1].type = INPUT_KEYBOARD;
  inputs[1].ki.wVk = vk;
  inputs[1].ki.dwFlags = KEYEVENTF_KEYUP;

  final sent = SendInput(2, inputs, sizeOf<INPUT>());
  if (sent == 0) {
    // debugPrint("SendInput failed: ${GetLastError()}");
  }

  calloc.free(inputs);
}

class MediaKey {
  static const int playPause = 0xB3;
  static const int next = 0xB0;
  static const int prev = 0xB1;
}

// ===========================================================
// PANEL WIDGET
// ===========================================================
class NowPlayingPanel extends ConsumerStatefulWidget {
  const NowPlayingPanel({super.key});

  @override
  ConsumerState<NowPlayingPanel> createState() => _NowPlayingPanelState();
}

class _NowPlayingPanelState extends ConsumerState<NowPlayingPanel> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  bool _handleKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;

    // 🔴 If user is typing, ignore media keys
    final focused = FocusManager.instance.primaryFocus;
    if (focused != null &&
        focused.context != null &&
        focused.context!.widget is EditableText) {
      return false;
    }

    if (e.logicalKey == LogicalKeyboardKey.space) {
      _sendMediaKey(MediaKey.playPause);
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<dynamic> asyncNow = ref.watch(nowPlayingProvider);

    return asyncNow.when(
      loading: () => _panel(
        const Center(
          child: Text(
            "Listening…",
            style: TextStyle(
              color: Colors.white70,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
      error: (Object err, StackTrace? _) => _panel(
        Center(
          child: Text(
            "SMTC Error: $err",
            style: const TextStyle(
              color: Colors.redAccent,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
      data: (dynamic d) {
        // d is expected to be SmtcData-like with fields: title, artist, state, artwork, peak
        final String artwork = (d.artwork ?? '') as String;
        final String title = (d.title ?? '') as String;
        final String artist = (d.artist ?? '') as String;
        final String state = (d.state ?? 'Stopped') as String;
        final bool playing = state.toLowerCase() == 'playing';

        return _panel(
          Stack(
            children: [
              Row(
                mainAxisAlignment: .start,
                crossAxisAlignment: .center,
                children: <Widget>[
                  _albumArt(artwork),
                  const SizedBox(width: 16),
                  Expanded(child: _meta(title, artist)),
                  const SizedBox(width: 16),
                ],
              ),
              Positioned(left: 120, top: 55, child: _buttons(playing)),
            ],
          ),
        );
      },
    );
  }

  // PANEL CONTAINER
  Widget _panel(Widget child) {
    return CustomContainer(
      width: 450,
      height: 140,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  // ===========================================================
  // ALBUM ART (FIXED SIZE — NO SCALE ANIMATION)
  // ===========================================================
  Widget _albumArt(String artwork) {
    Widget artWidget;

    if (artwork.isEmpty) {
      artWidget = Container(
        color: Colors.white12,
        alignment: Alignment.center,
        child: const Icon(Icons.music_note, color: Colors.white70, size: 40),
      );
    } else if (artwork.startsWith('data:')) {
      try {
        final Uint8List bytes = base64Decode(artwork.split(',').last);
        artWidget = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        artWidget = const Icon(
          Icons.music_note,
          color: Colors.white70,
          size: 40,
        );
      }
    } else {
      artWidget = Image.network(artwork, fit: BoxFit.cover);
    }

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: artWidget,
      ),
    );
  }

  // ===========================================================
  // META SECTION WITH MARQUEE TEXT
  // ===========================================================
  Widget _meta(String title, String artist) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Marquee(
          text: title.isEmpty ? 'Unknown Title' : title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
          height: 22,
        ),
        const SizedBox(height: 6),
        _Marquee(
          text: artist.isEmpty ? 'Unknown Artist' : artist,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.none,
          ),
          height: 20,
        ),
      ],
    );
  }

  // ===========================================================
  // BUTTONS
  // ===========================================================
  Widget _buttons(bool playing) {
    return Row(
      children: <Widget>[
        _btn(Icons.skip_previous_rounded, () => _sendMediaKey(MediaKey.prev)),
        const SizedBox(width: 14),
        _btn(
          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          () => _sendMediaKey(MediaKey.playPause),
          big: false,
        ),
        const SizedBox(width: 14),
        _btn(Icons.skip_next_rounded, () => _sendMediaKey(MediaKey.next)),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, {bool big = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: big ? 56 : 42,
        height: big ? 56 : 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: big ? 0.12 : 0.06),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: big ? 30 : 22),
      ),
    );
  }
}

// ===========================================================
// MARQUEE WIDGET
// - Clips text to a fixed lane
// - Measures text width and animates only when overflow occurs
// - Ping-pong animation using AnimationController
// ===========================================================
class _Marquee extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double height;

  const _Marquee({
    required this.text,
    required this.style,
    required this.height,
  });

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;
  double _textWidth = 0.0;
  double _viewportWidth = 0.0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _setup(double viewportWidth) {
    // measure text width
    final TextPainter painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final double measured = painter.width;

    if (measured <= viewportWidth || viewportWidth <= 0) {
      // no overflow: dispose controller if exists
      if (_controller != null) {
        _controller!.stop();
        _controller!.dispose();
        _controller = null;
        _animation = null;
      }
      _textWidth = measured;
      _viewportWidth = viewportWidth;
      setState(() {});
      return;
    }

    // overflow case: create / update controller
    final double overflow = measured - viewportWidth;
    final int seconds = (overflow ~/ 30).clamp(4, 12);
    final Duration duration = Duration(seconds: seconds);

    // If controller exists and same settings, keep it
    if (_controller != null &&
        _viewportWidth == viewportWidth &&
        (_textWidth - measured).abs() < 0.5) {
      // already fine
      return;
    }

    _controller?.dispose();
    _controller = AnimationController(vsync: this, duration: duration);
    _animation = Tween<double>(
      begin: 0.0,
      end: -overflow,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));

    // ping-pong
    _controller!.repeat(reverse: true);

    _textWidth = measured;
    _viewportWidth = viewportWidth;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double vw = constraints.maxWidth;
          // Setup or update animation when constraints change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setup(vw);
          });

          if (_animation == null || _controller == null) {
            // static text (no overflow)
            return ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.text,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: widget.style.copyWith(decoration: TextDecoration.none),
                ),
              ),
            );
          }

          return ClipRect(
            child: AnimatedBuilder(
              animation: _animation!,
              builder: (BuildContext context, Widget? child) {
                final double offsetX = _animation!.value;
                return Transform.translate(
                  offset: Offset(offsetX, 0),
                  child: SizedBox(
                    width: _textWidth,
                    child: Text(
                      widget.text,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      style: widget.style.copyWith(
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
