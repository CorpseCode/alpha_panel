import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/vault_service.dart';
import 'active_vault_provider.dart';

final validActiveVaultProvider = Provider<bool>((ref) {
  final path = ref.watch(activeVaultProvider);

  if (path == null) return false;

  final dir = Directory(path);
  if (!dir.existsSync()) return false;

  return VaultService.isVault(path);
});
