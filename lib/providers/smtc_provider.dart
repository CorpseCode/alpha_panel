import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/smtc_service.dart';

final smtcProvider = Provider<SmtcService>((ref) {
  return SmtcService.instance;
});

final nowPlayingProvider = StreamProvider<SmtcData>((ref) {
  return SmtcService.instance.stream;
});
