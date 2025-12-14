import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/vault_info.dart';

class VaultService {
  static const markerName = '.alpha_vault';

  static Future<String> defaultVaultPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'Alpha', 'Vaults', 'Default');
  }

  static bool isVault(String path) {
    return File(p.join(path, markerName)).existsSync();
  }

  static Future<VaultInfo> createVault({
    required String path,
    required String name,
  }) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final marker = File(p.join(path, markerName));
    await marker.writeAsString(
      jsonEncode({
        'version': 1,
        'app': 'alpha',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'name': name,
      }),
    );

    await Directory(p.join(path, 'notes')).create();
    await Directory(p.join(path, 'assets')).create();

    final welcome = File(p.join(path, 'notes', 'welcome.md'));
    if (!welcome.existsSync()) {
      await welcome.writeAsString('# Welcome\n\nYour Alpha vault is ready.');
    }

    return VaultInfo(path: path, name: name);
  }

  static VaultInfo readVaultInfo(String path) {
    final marker = File(p.join(path, markerName));
    final json = jsonDecode(marker.readAsStringSync());
    return VaultInfo(path: path, name: json['name'] ?? 'Vault');
  }
}
