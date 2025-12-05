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
  final _ctrl = StreamController<SmtcData>.broadcast();
  Stream<SmtcData> get stream => _ctrl.stream;

  SmtcData _last = SmtcData.empty;

  String _resolveExe() {
    final exe1 = p.join(p.dirname(Platform.resolvedExecutable), 'media_smtc_listener.exe');
    if (File(exe1).existsSync()) return exe1;

    final exe2 = p.join(Directory.current.path, 'media_smtc_listener.exe');
    if (File(exe2).existsSync()) return exe2;

    throw Exception("SMTC exe not found");
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _launch();
  }

  Future<void> stop() async {
    _running = false;
    _proc?.kill();
  }

  Future<void> _launch() async {
    try {
      final exe = _resolveExe();
      _proc = await Process.start(exe, [], runInShell: true);

      _proc!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(_onLine);
      _proc!.stderr.transform(utf8.decoder).listen((e) {
        if (kDebugMode) debugPrint("SMTC STDERR: $e");
      });

      _proc!.exitCode.then((code) {
        if (_running) Future.delayed(const Duration(seconds: 1), _launch);
      });
    } catch (e) {
      if (kDebugMode) debugPrint("SMTC start failed: $e");
      Future.delayed(const Duration(seconds: 2), _launch);
    }
  }

  Future<void> _onLine(String line) async {
    try {
      final j = jsonDecode(line);
      SmtcData d = SmtcData.fromJson(j);

      // If SMTC has no artwork → fetch from iTunes API
      if (d.artwork.isEmpty && (d.title.isNotEmpty || d.artist.isNotEmpty)) {
        final art = await _fetchFallbackArt(d.title, d.artist);
        if (art != null) d = d.copyWith(artwork: art);
      }

      _last = d;
      _ctrl.add(d);
    } catch (e) {
      if (kDebugMode) debugPrint("SMTC parse error: $e");
    }
  }

  Future<String?> _fetchFallbackArt(String title, String artist) async {
    try {
      final q = Uri.encodeComponent("$title $artist");
      final url = Uri.parse(
          "https://itunes.apple.com/search?term=$q&limit=1&entity=song");

      final resp = await http.get(url);
      if (resp.statusCode != 200) return null;

      final js = jsonDecode(resp.body);
      if (js['results'] == null || js['results'].isEmpty) return null;

      String art = js['results'][0]['artworkUrl100'] ?? '';
      if (art.isEmpty) return null;

      return art.replaceAll("100x100", "800x800");
    } catch (_) {
      return null;
    }
  }
}
