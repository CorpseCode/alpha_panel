// lib/services/smtc_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class SmtcData {
  final String title;
  final String artist;
  final String state;
  final String artwork;
  final double peak;

  const SmtcData({
    required this.title,
    required this.artist,
    required this.state,
    required this.artwork,
    required this.peak,
  });

  factory SmtcData.fromJson(Map<String, dynamic> j) {
    return SmtcData(
      title: (j['title'] ?? '') as String,
      artist: (j['artist'] ?? '') as String,
      state: (j['state'] ?? 'Unknown') as String,
      artwork: (j['artwork'] ?? '') as String,
      peak: ((j['peak'] ?? 0.0) as num).toDouble(),
    );
  }

  SmtcData copyWith({
    String? title,
    String? artist,
    String? state,
    String? artwork,
    double? peak,
  }) {
    return SmtcData(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      state: state ?? this.state,
      artwork: artwork ?? this.artwork,
      peak: peak ?? this.peak,
    );
  }

  static const empty = SmtcData(
    title: '',
    artist: '',
    state: 'Stopped',
    artwork: '',
    peak: 0.0,
  );
}

class SmtcService {
  SmtcService._internal();
  static final SmtcService instance = SmtcService._internal();

  Process? _proc;
  bool _running = false;
  bool _frozen = false;
  bool _launching = false;

  final _ctrl = StreamController<SmtcData>.broadcast();
  Stream<SmtcData> get stream => _ctrl.stream;

  SmtcData last = SmtcData.empty;

  // ----------------------------------------------------------
  // Resolve executable path
  // ----------------------------------------------------------
  String _resolveExe() {
    // 1) when running from flutter tool
    final exeFromFlutterBin = p.join(
      p.dirname(Platform.resolvedExecutable),
      'media_smtc_listener.exe',
    );
    if (File(exeFromFlutterBin).existsSync()) return exeFromFlutterBin;

    // 2) fallback: root
    final exeInRoot = p.join(Directory.current.path, 'media_smtc_listener.exe');
    if (File(exeInRoot).existsSync()) return exeInRoot;

    throw Exception("SMTC exe not found");
  }

  // ----------------------------------------------------------
  // Kill stale copies before launching
  // ----------------------------------------------------------
  Future<void> _killStaleProcesses() async {
    try {
      if (Platform.isWindows) {
        await Process.run('taskkill', [
          '/F',
          '/IM',
          'media_smtc_listener.exe',
        ], runInShell: true);
        if (kDebugMode) debugPrint("💀 Killed stale SMTC processes");
      }
    } catch (_) {}
  }

  // ----------------------------------------------------------
  // Public controls
  // ----------------------------------------------------------
  Future<void> start() async {
    _frozen = false;
    _running = true;
    _launch();
  }

  Future<void> stop() async {
    _frozen = true;
    _running = false;

    final old = _proc;
    _proc = null;

    if (old != null) {
      try {
        old.kill();
        if (kDebugMode) debugPrint("💀 Explicit kill of PID ${old.pid}");
      } catch (_) {}
    }
  }

  Future<void> resume() async {
    if (_frozen) {
      if (kDebugMode) debugPrint("▶ Resume called");
      _frozen = false;
      _running = true;
      _launch();
    }
  }

  Future<void> freeze() async {
    await stop();
    if (kDebugMode) debugPrint("⛔ SMTC frozen");
  }

  // ----------------------------------------------------------
  // Main launch logic — SINGLE INSTANCE ONLY
  // ----------------------------------------------------------
  Future<void> _launch() async {
    if (_frozen || !_running) return;
    if (_launching) return;

    // if we already have a working process, do nothing
    if (_proc != null) {
      if (kDebugMode) debugPrint("⚠ SMTC already active PID=${_proc!.pid}");
      return;
    }

    _launching = true;

    try {
      await _killStaleProcesses(); // <-- CRUCIAL

      final exe = _resolveExe();
      _proc = await Process.start(exe, const [], runInShell: true);

      if (kDebugMode) debugPrint("🔥 SMTC STARTED PID=${_proc!.pid}");

      _proc!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLine);

      _proc!.stderr.transform(utf8.decoder).listen((err) {
        debugPrint("SMTC STDERR: $err");
      });

      _proc!.exitCode.then((code) {
        if (kDebugMode) debugPrint("💔 SMTC EXIT code=$code");

        _proc = null;

        // Restart only if window is active & not frozen
        if (_running && !_frozen) {
          debugPrint("🔄 Restarting SMTC after exit…");
          Future.delayed(const Duration(milliseconds: 600), _launch);
        }
      });
    } catch (err) {
      debugPrint("🚫 Launch failed: $err");
      _proc = null;

      if (!_frozen && _running) {
        Future.delayed(const Duration(seconds: 2), _launch);
      }
    } finally {
      _launching = false;
    }
  }

  // ----------------------------------------------------------
  // Handle incoming JSON lines
  // ----------------------------------------------------------
  Future<void> _handleLine(String line) async {
    try {
      final json = jsonDecode(line);
      SmtcData d = SmtcData.fromJson(json);

      if (d.artwork.isEmpty && (d.title.isNotEmpty || d.artist.isNotEmpty)) {
        final maybe = await _fetchFallbackArt(d.title, d.artist);
        if (maybe != null) {
          d = d.copyWith(artwork: maybe);
        }
      }

      last = d;
      _ctrl.add(d);
    } catch (_) {}
  }

  // ----------------------------------------------------------
  // Fallback artwork via Apple API
  // ----------------------------------------------------------
  Future<String?> _fetchFallbackArt(String title, String artist) async {
    try {
      final q = Uri.encodeComponent("$title $artist");
      final url = Uri.parse(
        "https://itunes.apple.com/search?term=$q&limit=1&entity=song",
      );

      final resp = await http.get(url);
      if (resp.statusCode != 200) return null;

      final js = jsonDecode(resp.body);
      if (js['results'] == null || js['results'].isEmpty) return null;

      final art = js['results'][0]['artworkUrl100'] as String?;
      if (art == null || art.isEmpty) return null;

      return art.replaceAll("100x100", "600x600");
    } catch (_) {
      return null;
    }
  }
}
