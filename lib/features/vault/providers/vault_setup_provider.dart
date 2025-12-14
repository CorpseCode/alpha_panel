import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vault_validation_provider.dart';

final needsVaultSetupProvider = Provider<bool>((ref) {
  final isValid = ref.watch(validActiveVaultProvider);
  return !isValid;
});
