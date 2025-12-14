import 'package:alpha/common/custom_container.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/vault_service.dart';
import '../providers/vault_registry_provider.dart';
import '../providers/active_vault_provider.dart';

class VaultSetupPanel extends ConsumerStatefulWidget {
  const VaultSetupPanel({super.key});

  @override
  ConsumerState<VaultSetupPanel> createState() => _VaultSetupPanelState();
}

class _VaultSetupPanelState extends ConsumerState<VaultSetupPanel> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: CustomContainer(
          borderColor: Colors.transparent,
          width: 440,
          height: 260,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// TITLE
              Text(
                'Create Your Notes Vault',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  letterSpacing: 1.4,
                  decoration: TextDecoration.none,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),

              const SizedBox(height: 10),

              /// SUBTITLE
              Text(
                'Your notes stay local, private, and fully under your control.',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  letterSpacing: 0.6,
                  decoration: TextDecoration.none,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 34),

              /// ACTION BUTTON
              _chooseFolderButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chooseFolderButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () async {
          final path = await getDirectoryPath(
            confirmButtonText: 'Select Vault Folder',
          );
          if (path == null) return;

          final vault = VaultService.isVault(path)
              ? VaultService.readVaultInfo(path)
              : await VaultService.createVault(
                  path: path,
                  name: 'Vault',
                );

          await ref.read(vaultRegistryProvider.notifier).add(vault);
          await ref.read(activeVaultProvider.notifier).setActive(vault.path);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: CustomContainer(
            width: 300,
            height: 56,
            radius: 6,
            glow: _hovering
                ? Colors.cyanAccent.withValues(alpha: 0.25)
                : null,
            child: Center(
              child: Text(
                'Choose Folder',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  letterSpacing: 1.6,
                  decoration: TextDecoration.none,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.1
                    ..color = Colors.cyanAccent.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
