// lib/services/smtc_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

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
  bool _launching = false; // <-- prevent concurrent spawns

  final _ctrl = StreamController<SmtcData>.broadcast();
  Stream<SmtcData> get stream => _ctrl.stream;

  SmtcData last = SmtcData.empty;

  // ----------------------------------------------------------
  // RESOLVE EXE LOCATION
  // ----------------------------------------------------------
  String _resolveExe() {
    final exeFromFlutterBin = p.join(
      p.dirname(Platform.resolvedExecutable),
      'media_smtc_listener.exe',
    );
    if (File(exeFromFlutterBin).existsSync()) return exeFromFlutterBin;

    final exeInRoot = p.join(Directory.current.path, 'media_smtc_listener.exe');
    if (File(exeInRoot).existsSync()) return exeInRoot;

    throw Exception("SMTC exe not found");
  }

  // ======================================================
  // PUBLIC CONTROL
  // ======================================================

  Future<void> start() async {
    _frozen = false;
    if (_running) return;

    _running = true;
    _launch(); // fire and forget
  }

  Future<void> stop() async {
    _frozen = true;
    _running = false;

    final p = _proc;
    _proc = null;

    if (p != null) {
      try {
        if (kDebugMode) debugPrint('SMTC: killing PID ${p.pid}');
        p.kill();
      } catch (_) {}
    }
  }

  /// Called BEFORE panel animation finishes
  Future<void> resume() async {
    if (_frozen) {
      _frozen = false;
      _running = true;
      _launch();
      debugPrint("SMTC Resumed");
    }
  }

  /// Called WHEN losing window focus
  Future<void> freeze() async {
    await stop();
    debugPrint("Freezed SMTC");
  }

  // ======================================================
  // MAIN PROCESS LAUNCH
  // ======================================================
  Future<void> _launch() async {
    if (_frozen || !_running) return;

    // already spawning or already have a process => no new one
    if (_launching) return;
    if (_proc != null) {
      if (kDebugMode)
        debugPrint("SMTC: process already running (PID ${_proc!.pid})");
      return;
    }

    _launching = true;

    try {
      final exe = _resolveExe();

      _proc = await Process.start(exe, const [], runInShell: true);

      if (kDebugMode) debugPrint("SMTC STARTED: PID=${_proc!.pid}");

      _proc!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLine);

      _proc!.stderr.transform(utf8.decoder).listen((err) {
        if (kDebugMode) debugPrint("SMTC STDERR: $err");
      });

      _proc!.exitCode.then((code) {
        if (kDebugMode) debugPrint("SMTC EXIT: code=$code");
        _proc = null; // mark as gone

        // if still supposed to run and not frozen, auto-restart
        if (_running && !_frozen) {
          Future.delayed(const Duration(milliseconds: 500), _launch);
        }
      });
    } catch (err) {
      if (kDebugMode) debugPrint("SMTC START FAILED: $err");

      _proc = null;

      if (!_frozen && _running) {
        Future.delayed(const Duration(seconds: 2), _launch);
      }
    } finally {
      _launching = false;
    }
  }

  // ======================================================
  // PARSE LINES FROM EXE
  // ======================================================
  Future<void> _handleLine(String line) async {
    try {
      final j = jsonDecode(line);
      SmtcData d = SmtcData.fromJson(j);

      // fetch fallback art only if needed
      if (d.artwork.isEmpty && (d.title.isNotEmpty || d.artist.isNotEmpty)) {
        final art = await _fetchFallbackArt(d.title, d.artist);
        if (art != null) d = d.copyWith(artwork: art);
      }

      last = d;
      _ctrl.add(d);
    } catch (e) {
      if (kDebugMode) debugPrint("SMTC parse error: $e\nline: $line");
    }
  }

  // ======================================================
  // EXTRA: artwork fetcher
  // ======================================================
  Future<String?> _fetchFallbackArt(String title, String artist) async {
    try {
      final query = Uri.encodeComponent("$title $artist");
      final url = Uri.parse(
        "https://itunes.apple.com/search?term=$query&limit=1&entity=song",
      );

      final resp = await http.get(url);
      if (resp.statusCode != 200) return null;

      final js = jsonDecode(resp.body);
      if (js['results'] is! List || js['results'].isEmpty) return null;

      final art = js['results'][0]['artworkUrl100'];
      if (art is! String) return null;

      return art.replaceAll("100x100", "600x600");
    } catch (_) {
      return null;
    }
  }
}
