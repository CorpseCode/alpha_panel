import 'package:alpha/common/custom_container.dart';
import 'package:alpha/providers/theme_provider.dart';
import 'package:alpha/providers/app_settings_panel_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AppSettingsPanel extends ConsumerWidget {
  const AppSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(appStyleProvider);
    final ctrl = ref.read(appStyleProvider.notifier);
    final open = ref.watch(appSettingsPanelOpenProvider);

    return AnimatedSlide(
      offset: open ? Offset.zero : const Offset(1.05, 0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: open ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: Align(
          alignment: Alignment.centerRight,
          child: CustomContainer(
            width: 400,
            height: double.maxFinite,
            margin: const EdgeInsets.only(top: 50),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title("Appearance"),

                      const SizedBox(height: 20),

                      _label("Background"),
                      const SizedBox(height: 10),

                      /// BACKGROUND COLOR (with opacity)
                      SlidePicker(
                        pickerColor: style.backgroundColor,
                        enableAlpha: true,
                        showParams: false,
                        showIndicator: true,
                        onColorChanged: ctrl.setBackground,
                      ),

                      const SizedBox(height: 26),

                      _label("Border"),
                      const SizedBox(height: 10),

                      /// BORDER COLOR (no opacity)
                      SlidePicker(
                        pickerColor: style.borderColor,
                        enableAlpha: false,
                        showParams: false,
                        showIndicator: true,
                        onColorChanged: ctrl.setBorder,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return const Text(
      "Appearance",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.75),
        decoration: TextDecoration.none,
      ),
    );
  }
}
