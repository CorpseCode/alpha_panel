// lib/services/smtc_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

/// REAL DATA MODEL
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
      title: (j['title'] ?? ''),
      artist: (j['artist'] ?? ''),
      state: (j['state'] ?? 'Unknown'),
      artwork: (j['artwork'] ?? ''),
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

/// SERVICE ITSELF
class SmtcService {
  SmtcService._internal();
  static final instance = SmtcService._internal();

  Process? _proc;
  bool _launching = false;
  bool _purgedOnce = false;

  final _ctrl = StreamController<SmtcData>.broadcast();
  Stream<SmtcData> get stream => _ctrl.stream;

  SmtcData last = SmtcData.empty;

  /// Cache artwork based on title+artist
  final Map<String, String> _artCache = {};

  /////////////////////////////////////////////////////////////////////////////
  // Resolve Executable
  /////////////////////////////////////////////////////////////////////////////
  String _resolveExe() {
    final devExe = p.join(
      p.dirname(Platform.resolvedExecutable),
      'media_smtc_listener.exe',
    );

    if (File(devExe).existsSync()) return devExe;

    final rootExe = p.join(Directory.current.path, 'media_smtc_listener.exe');

    if (File(rootExe).existsSync()) return rootExe;

    throw Exception("media_smtc_listener.exe not found");
  }

  /////////////////////////////////////////////////////////////////////////////
  // Public Lifecycle
  /////////////////////////////////////////////////////////////////////////////

  Future<void> start() async {
    if (_proc != null) {
      debugPrint("⚠ Already running, ignoring start()");
      return;
    }

    debugPrint("▶ SMTC START");
    await _launchFresh();
  }

  Future<void> restart() async {
    debugPrint("🔄 SMTC RESTART triggered");
    await _killCurrent();
    await _launchFresh();
  }

  /////////////////////////////////////////////////////////////////////////////
  // LAUNCH PROCESS
  /////////////////////////////////////////////////////////////////////////////
  Future<void> _launchFresh() async {
    if (_launching) return;
    _launching = true;

    await _purgeZombieProcesses();

    try {
      final exe = _resolveExe();
      _proc = await Process.start(exe, [], runInShell: true);

      final pid = _proc?.pid;
      debugPrint("🔥 SMTC ACTIVE PID=$pid");

      _proc!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLine);

      _proc!.stderr.transform(utf8.decoder).listen((err) {
        debugPrint("❌ SMTC error: $err");
      });

      _proc!.exitCode.then((code) async {
        final exitPid = pid; // safe copy
        debugPrint("💔 SMTC EXIT PID=$exitPid CODE=$code");

        final cleanExit = code == 0;

        _proc = null;

        if (cleanExit) {
          debugPrint("🟡 SMTC idle — not restarting");
          return;
        }

        debugPrint("🔴 Unexpected exit — restarting...");
        await Future.delayed(const Duration(milliseconds: 450));

        await _launchFresh();
      });
    } catch (err) {
      debugPrint("🚫 SMTC launch failed: $err");
      _proc = null;
      await Future.delayed(const Duration(seconds: 2));
      await _launchFresh();
    } finally {
      _launching = false;
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  Future<void> _killCurrent() async {
    final old = _proc;
    _proc = null;

    if (old == null) return;

    try {
      debugPrint("💀 Killing SMTC PID=${old.pid}");
      old.kill();
    } catch (_) {}
  }

  /////////////////////////////////////////////////////////////////////////////
  Future<void> _purgeZombieProcesses() async {
    if (_purgedOnce) return;
    _purgedOnce = true;

    try {
      await Process.run('taskkill', [
        '/F',
        '/IM',
        'media_smtc_listener.exe',
      ], runInShell: true);
      debugPrint("💣 Purged zombie SMTC instances");
    } catch (_) {}
  }

  /////////////////////////////////////////////////////////////////////////////
  // DATA HANDLER
  /////////////////////////////////////////////////////////////////////////////
  Future<void> _handleLine(String line) async {
    SmtcData raw;

    try {
      raw = SmtcData.fromJson(jsonDecode(line));
    } catch (_) {
      return;
    }

    final key = "${raw.title}:${raw.artist}".trim();
    SmtcData data = raw;

    // Case 1: Cached artwork
    if (_artCache.containsKey(key)) {
      data = data.copyWith(artwork: _artCache[key]);
      last = data;
      _ctrl.add(data);
      return;
    }

    // Case 2: SMTC provided artwork
    if (data.artwork.isNotEmpty) {
      _artCache[key] = data.artwork;
      last = data;
      _ctrl.add(data);
      return;
    }

    // Case 3: No artwork initially → emit immediately
    last = data;
    _ctrl.add(data);

    // Async fetch
    if (raw.title.isNotEmpty) {
      final url = await _fetchArt(raw.title, raw.artist);
      if (url != null) {
        _artCache[key] = url;
        final updated = data.copyWith(artwork: url);
        last = updated;
        _ctrl.add(updated);
      }
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // Fetch album art
  /////////////////////////////////////////////////////////////////////////////
  Future<String?> _fetchArt(String title, String artist) async {
    try {
      final query = Uri.encodeComponent("$title $artist");
      final url = Uri.parse(
        "https://itunes.apple.com/search?term=$query&limit=1&entity=song",
      );

      final resp = await http.get(url);
      if (resp.statusCode != 200) return null;

      final js = jsonDecode(resp.body);
      if (js["results"] == null || js["results"].isEmpty) return null;

      final art = js["results"][0]["artworkUrl100"];
      if (art == null) return null;

      return art.replaceAll("100x100", "600x600");
    } catch (_) {
      return null;
    }
  }
}
