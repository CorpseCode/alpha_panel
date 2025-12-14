import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final activeVaultProvider =
    NotifierProvider<ActiveVaultNotifier, String?>(
  ActiveVaultNotifier.new,
);

class ActiveVaultNotifier extends Notifier<String?> {
  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('active_vault');
  }

  Future<void> setActive(String path) async {
    state = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_vault', path);
  }
}
