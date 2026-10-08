/// Board / flash presets for ESP targets (CYD variants + T-Deck).
enum EspPreset {
  cydClassic,
  cyd2usb,
  esp32e,
  esp32Generic,
  tdeck,
}

extension EspPresetX on EspPreset {
  String get title => switch (this) {
        EspPreset.cydClassic => 'CYD classic 2.8″ resistive (ESP32-2432S028)',
        EspPreset.cyd2usb => 'CYD2USB',
        EspPreset.esp32e => 'ESP32-32E 2.8″ resistive',
        EspPreset.esp32Generic => 'Generic ESP32 full image @ 0x0',
        EspPreset.tdeck => 'LilyGO T-Deck (ESP32-S3)',
      };

  String get subtitle => switch (this) {
        EspPreset.cydClassic =>
          'polybius-cyd.bin · esp32 · 115200 · @ 0x0 · ~4 MiB flash',
        EspPreset.cyd2usb =>
          'polybius-cyd.bin · esp32 · 115200 · @ 0x0 · dual-USB CYD',
        EspPreset.esp32e =>
          'polybius-cyd.bin · esp32 · start 115200 (Fast 460800) · @ 0x0',
        EspPreset.esp32Generic =>
          'polybius-cyd.bin · esp32 · full merged image @ 0x0',
        EspPreset.tdeck =>
          'polybius-tdeck.bin · esp32s3 · 115200 · @ 0x0 · prefer Skip auto-reset',
      };

  String get chip => this == EspPreset.tdeck ? 'esp32s3' : 'esp32';

  int get defaultBaud => switch (this) {
        EspPreset.esp32e => 115200,
        EspPreset.tdeck => 115200,
        _ => 115200,
      };

  int get fastBaud => this == EspPreset.tdeck ? 460800 : 460800;

  int get defaultOffset => 0x0;

  String get firmwareAsset => this == EspPreset.tdeck
      ? 'assets/firmware/polybius-tdeck.bin'
      : 'assets/firmware/polybius-cyd.bin';

  String get firmwareFileName =>
      this == EspPreset.tdeck ? 'polybius-tdeck.bin' : 'polybius-cyd.bin';

  /// Prefer skipping auto-reset (USB-JTAG / flaky DTR).
  bool get preferSkipAutoReset => this == EspPreset.tdeck;

  int get flashSizeHintBytes =>
      this == EspPreset.tdeck ? 16 * 1024 * 1024 : 4 * 1024 * 1024;

  String get manualBootSteps => switch (this) {
        EspPreset.tdeck =>
          '1. Hold the trackball center (BOOT).\n'
              '2. Press RST (or power on) while holding.\n'
              '3. Keep holding 2–3s until the screen stays black / backlight off.\n'
              '4. Tap CONTINUE — Syncing… should start.\n'
              '5. If sync times out, retry this sequence.',
        _ =>
          '1. Hold BOOT (IO0).\n'
              '2. Press and release RESET (EN).\n'
              '3. Keep holding BOOT until Syncing… appears.\n'
              '4. Then release BOOT.\n'
              '5. If sync fails, unplug/replug OTG and retry.',
      };

  String get overwriteWarning =>
      'Full image @ 0x0 overwrites existing firmware / Launcher / Bruce. '
      'Continue only if you intend to replace the entire flash contents.';
}
