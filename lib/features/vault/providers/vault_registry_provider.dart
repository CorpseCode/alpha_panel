import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vault_info.dart';

final vaultRegistryProvider =
    NotifierProvider<VaultRegistryNotifier, List<VaultInfo>>(
      VaultRegistryNotifier.new,
    );

class VaultRegistryNotifier extends Notifier<List<VaultInfo>> {
  @override
  List<VaultInfo> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('vault_registry');
    if (raw == null) return;

    state = (jsonDecode(raw) as List)
        .map((e) => VaultInfo.fromJson(e))
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'vault_registry',
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(VaultInfo vault) async {
    state = [...state, vault];
    await _save();
  }
}
