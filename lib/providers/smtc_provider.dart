import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/smtc_service.dart';

final smtcProvider = Provider<SmtcService>((ref) {
  final s = SmtcService.instance;
  s.start();
  ref.onDispose(() => s.stop());
  return s;
});

final nowPlayingProvider = StreamProvider<SmtcData>((ref) {
  ref.watch(smtcProvider);
  return SmtcService.instance.stream;
});
