import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'asset_integrity.dart';
import 'board_presets.dart';
import 'flasher_bridge.dart';
import 'flasher_event.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PolybiusFlasherApp());
}

class PolybiusFlasherApp extends StatelessWidget {
  const PolybiusFlasherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.shareTechMonoTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FlasherColors.voidBlack,
      colorScheme: const ColorScheme.dark(
        primary: FlasherColors.phosphor,
        secondary: FlasherColors.amber,
        surface: FlasherColors.panel,
        error: FlasherColors.danger,
      ),
      textTheme: mono.apply(
        bodyColor: FlasherColors.phosphor,
        displayColor: FlasherColors.phosphor,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: FlasherColors.panelHot,
        contentTextStyle: TextStyle(color: FlasherColors.phosphor),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'PØLYBÎŪS FLASHER',
      debugShowCheckedModeBanner: false,
      theme: base,
      home: const FlasherHomePage(),
    );
  }
}

class FlasherColors {
  static const voidBlack = Color(0xFF05070A);
  static const panel = Color(0xFF0C1218);
  static const panelHot = Color(0xFF111C24);
  static const phosphor = Color(0xFF5CFF8A);
  static const amber = Color(0xFFFFB84D);
  static const cyan = Color(0xFF40D9FF);
  static const magenta = Color(0xFFFF4DFF);
  static const dim = Color(0xFF6B7C6E);
  static const danger = Color(0xFFFF4D6A);
  static const grid = Color(0x145CFF8A);
}

enum FlashTarget {
  r36s,
  cydClassic,
  cyd2usb,
  esp32e,
  esp32Generic,
  tdeck,
  androidOtg,
}

extension FlashTargetX on FlashTarget {
  bool get isEsp => espPreset != null;
  bool get isAndroidOtg => this == FlashTarget.androidOtg;
  bool get isR36s => this == FlashTarget.r36s;

  EspPreset? get espPreset => switch (this) {
    FlashTarget.cydClassic => EspPreset.cydClassic,
    FlashTarget.cyd2usb => EspPreset.cyd2usb,
    FlashTarget.esp32e => EspPreset.esp32e,
    FlashTarget.esp32Generic => EspPreset.esp32Generic,
    FlashTarget.tdeck => EspPreset.tdeck,
    FlashTarget.r36s || FlashTarget.androidOtg => null,
  };

  String get title => switch (this) {
    FlashTarget.r36s => 'R36S SD',
    FlashTarget.cydClassic => 'CYD CLASSIC',
    FlashTarget.cyd2usb => 'CYD2USB',
    FlashTarget.esp32e => 'ESP32-32E',
    FlashTarget.esp32Generic => 'GENERIC ESP32',
    FlashTarget.tdeck => 'T-DECK',
    FlashTarget.androidOtg => 'ANDROID OTG',
  };

  String get subtitle => switch (this) {
    FlashTarget.r36s => 'PortMaster zip + SD preparation',
    FlashTarget.androidOtg => 'ADB over USB-C OTG or TCP',
    _ => espPreset!.subtitle,
  };

  String get defaultChip => espPreset?.chip ?? '';
  int get defaultBaud => espPreset?.defaultBaud ?? 115200;
  String get firmwareAsset => espPreset?.firmwareAsset ?? '';
  String get firmwareFileName => espPreset?.firmwareFileName ?? '';

  BundledAsset? get firmwareBundle => switch (espPreset) {
    EspPreset.tdeck => AssetIntegrity.tdeckBin,
    EspPreset.cydClassic ||
    EspPreset.cyd2usb ||
    EspPreset.esp32e ||
    EspPreset.esp32Generic => AssetIntegrity.cydBin,
    null => null,
  };
}

enum AddressMode { fullImage, appOnly, custom }

extension AddressModeX on AddressMode {
  String get label => switch (this) {
    AddressMode.fullImage => 'Full image @ 0x0',
    AddressMode.appOnly => 'App only @ 0x10000',
    AddressMode.custom => 'Custom offset',
  };
}

enum R36InstallMode { direct, autoinstall }

extension R36InstallModeX on R36InstallMode {
  String get bridgeValue => switch (this) {
    R36InstallMode.direct => 'direct',
    R36InstallMode.autoinstall => 'autoinstall',
  };

  String get label => switch (this) {
    R36InstallMode.direct => 'Direct copy',
    R36InstallMode.autoinstall => 'Autoinstall',
  };
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

class _InstallJob {
  _InstallJob.catalog(ApkCatalogItem item)
    : item = item,
      localPath = null,
      title = item.title;

  _InstallJob.local(this.localPath) : item = null, title = 'LOCAL APK';

  final ApkCatalogItem? item;
  final String? localPath;
  final String title;
}

class FlasherHomePage extends StatefulWidget {
  const FlasherHomePage({super.key});

  @override
  State<FlasherHomePage> createState() => _FlasherHomePageState();
}

class _FlasherHomePageState extends State<FlasherHomePage>
    with SingleTickerProviderStateMixin {
  final _bridge = FlasherBridge.instance;
  final _logs = <String>[];
  final _customOffsetCtrl = TextEditingController(text: '0x0');
  final _tcpHostCtrl = TextEditingController(text: '192.168.1.1');
  final _tcpPortCtrl = TextEditingController(text: '5555');

  late final AnimationController _pulse;
  StreamSubscription<FlasherEvent>? _eventSub;

  FlashTarget? _target = FlashTarget.cydClassic;
  List<UsbDeviceInfo> _devices = [];
  List<UsbDeviceInfo> _usbInventory = [];
  UsbDeviceInfo? _selected;
  bool _busy = false;
  double _progress = 0;
  String _status = 'SELECT TARGET. VERIFY POWER. FLASH WITH INTENT.';

  AddressMode _addressMode = AddressMode.fullImage;
  int _baud = 115200;
  bool _eraseAll = false;
  bool _hardResetAfter = true;
  bool _skipAutoReset = false;
  int _serialMonitorMs = 0;

  String? _lastSdTreeUri;
  List<R36PathCandidate> _r36Candidates = const [];
  String? _selectedR36Hint;
  bool _prepareSdBeforeFlash = true;
  bool _wipePreviousPolybius = true;
  bool _logicalFormatSd = false;
  R36InstallMode _r36InstallMode = R36InstallMode.direct;

  final Set<String> _selectedApkIds = {};
  String? _localApkPath;
  bool _forceDowngrade = false;
  bool _forceUser0 = true;
  bool _useTcpAdb = false;
  String _androidUsbMessage = 'Scan USB inventory before install.';

  static const _baudOptions = [115200, 230400, 460800, 921600];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bridge.ensureListening();
    _eventSub = _bridge.events.listen((event) {
      if (!mounted) return;
      setState(() {
        _logs.add(event.toLogLine());
        if (_logs.length > 200) {
          _logs.removeRange(0, _logs.length - 200);
        }
        if (event.percent != null) {
          _progress = event.percent!.clamp(0.0, 1.0);
        }
      });
    });
    _loadPrefs();
    _refreshUsb(checkBattery: false, silent: true);
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _pulse.dispose();
    _customOffsetCtrl.dispose();
    _tcpHostCtrl.dispose();
    _tcpPortCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _target = _parseTarget(prefs.getString('last_target')) ?? _target;
      _lastSdTreeUri = prefs.getString('r36s_tree_uri');
      _prepareSdBeforeFlash =
          prefs.getBool('prepare_sd_before_flash') ?? _prepareSdBeforeFlash;
      _wipePreviousPolybius =
          prefs.getBool('wipe_previous_polybius') ?? _wipePreviousPolybius;
      _logicalFormatSd = prefs.getBool('logical_format_sd') ?? _logicalFormatSd;
      _r36InstallMode = _parseR36Mode(prefs.getString('r36_install_mode'));
      _selectedApkIds
        ..clear()
        ..addAll(prefs.getStringList('android_apk_ids') ?? const <String>[]);
      final legacyApk = prefs.getString('android_apk_id');
      if (_selectedApkIds.isEmpty && legacyApk != null) {
        _selectedApkIds.add(legacyApk);
      }
      _localApkPath = prefs.getString('android_local_apk');
      _forceDowngrade = prefs.getBool('android_force_downgrade') ?? false;
      _forceUser0 = prefs.getBool('android_force_user0') ?? true;
      _useTcpAdb = prefs.getBool('android_use_tcp') ?? false;
      _tcpHostCtrl.text = prefs.getString('android_tcp_host') ?? '192.168.1.1';
      _tcpPortCtrl.text = prefs.getString('android_tcp_port') ?? '5555';
      if (_target?.isEsp ?? false) {
        _applyEspDefaults(_target!, prefs: prefs);
      }
    });
  }

  FlashTarget? _parseTarget(String? value) {
    if (value == null) return null;
    if (value == 'cyd') return FlashTarget.cydClassic;
    for (final target in FlashTarget.values) {
      if (target.name == value) return target;
    }
    return null;
  }

  R36InstallMode _parseR36Mode(String? value) {
    for (final mode in R36InstallMode.values) {
      if (mode.name == value || mode.bridgeValue == value) return mode;
    }
    return R36InstallMode.direct;
  }

  void _applyEspDefaults(FlashTarget target, {SharedPreferences? prefs}) {
    final preset = target.espPreset;
    if (preset == null) return;
    final key = target.name;
    _addressMode = AddressMode.values.firstWhere(
      (mode) => mode.name == prefs?.getString('${key}_address_mode'),
      orElse: () => AddressMode.fullImage,
    );
    _customOffsetCtrl.text = prefs?.getString('${key}_custom_offset') ?? '0x0';
    _baud = prefs?.getInt('${key}_baud') ?? preset.defaultBaud;
    _eraseAll = prefs?.getBool('${key}_erase_all') ?? false;
    _hardResetAfter = prefs?.getBool('${key}_hard_reset_after') ?? true;
    _skipAutoReset =
        prefs?.getBool('${key}_skip_auto_reset') ?? preset.preferSkipAutoReset;
    _serialMonitorMs = prefs?.getInt('${key}_serial_monitor_ms') ?? 0;
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final target = _target;
    if (target != null) {
      await prefs.setString('last_target', target.name);
    }
    await prefs.setBool('prepare_sd_before_flash', _prepareSdBeforeFlash);
    await prefs.setBool('wipe_previous_polybius', _wipePreviousPolybius);
    await prefs.setBool('logical_format_sd', _logicalFormatSd);
    await prefs.setString('r36_install_mode', _r36InstallMode.name);
    if (_lastSdTreeUri != null) {
      await prefs.setString('r36s_tree_uri', _lastSdTreeUri!);
    }
    await prefs.setStringList('android_apk_ids', _selectedApkIds.toList());
    if (_localApkPath != null) {
      await prefs.setString('android_local_apk', _localApkPath!);
    } else {
      await prefs.remove('android_local_apk');
    }
    await prefs.setBool('android_force_downgrade', _forceDowngrade);
    await prefs.setBool('android_force_user0', _forceUser0);
    await prefs.setBool('android_use_tcp', _useTcpAdb);
    await prefs.setString('android_tcp_host', _tcpHostCtrl.text.trim());
    await prefs.setString('android_tcp_port', _tcpPortCtrl.text.trim());
    if (target?.isEsp ?? false) {
      final key = target!.name;
      await prefs.setString('${key}_address_mode', _addressMode.name);
      await prefs.setString('${key}_custom_offset', _customOffsetCtrl.text);
      await prefs.setInt('${key}_baud', _baud);
      await prefs.setBool('${key}_erase_all', _eraseAll);
      await prefs.setBool('${key}_hard_reset_after', _hardResetAfter);
      await prefs.setBool('${key}_skip_auto_reset', _skipAutoReset);
      await prefs.setInt('${key}_serial_monitor_ms', _serialMonitorMs);
    }
  }

  Future<void> _copyLogs() async {
    await Clipboard.setData(ClipboardData(text: _bridge.dumpEventLog()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event log copied to clipboard.')),
    );
  }

  Future<void> _withBusy(String label, Future<void> Function() body) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _status = label;
    });
    try {
      await body();
    } on PlatformException catch (e) {
      _setStatus('Native bridge error ${e.code}: ${e.message ?? e.details}');
    } on Object catch (e) {
      _setStatus('Operation failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
      await _savePrefs();
    }
  }

  void _setStatus(String value) {
    if (!mounted) return;
    setState(() {
      _status = value;
    });
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    String action = 'CONTINUE',
    bool destructive = false,
  }) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlasherColors.panel,
        title: Text(title, style: GoogleFonts.orbitron()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: FlasherColors.danger,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _acknowledgeBattery() async {
    final battery = await _bridge.getBatteryStatus();
    final warning = battery.warning.trim().isNotEmpty
        ? battery.warning.trim()
        : battery.low
        ? 'Battery is low. Keep this host device powered during flashing.'
        : '';
    if (warning.isEmpty) return true;
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: FlasherColors.panel,
        title: Text('POWER WARNING', style: GoogleFonts.orbitron()),
        content: Text(
          '$warning\n\nHost battery: ${battery.percent}%'
          '${battery.charging ? ' (charging)' : ''}\n\n'
          'Acknowledge before any USB OTG operation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ABORT'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I ACKNOWLEDGE'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _cancelOperation() async {
    await _bridge.cancelFlash();
    _setStatus('Cancel requested. Waiting for native operation to stop.');
  }

  Future<void> _refreshUsb({
    bool checkBattery = true,
    bool silent = false,
  }) async {
    if (checkBattery && !await _acknowledgeBattery()) return;
    try {
      final devices = await _bridge.listUsbDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        if (_selected != null &&
            !devices.any((d) => d.deviceId == _selected!.deviceId)) {
          _selected = null;
        }
        if (!silent) {
          _status = devices.isEmpty
              ? 'No USB devices detected.'
              : 'USB scan complete: ${devices.length} device(s).';
        }
      });
    } on Object catch (e) {
      if (!silent) _setStatus('USB scan failed: $e');
    }
  }

  Future<void> _refreshAndroidInventory({bool checkBattery = true}) async {
    if (checkBattery && !await _acknowledgeBattery()) return;
    final inventory = await _bridge.listUsbInventory();
    final adb = inventory.where((d) => d.isAdb).toList();
    final mtpOnly = inventory
        .where((d) => d.hasMtpOrStorage && !d.isAdb)
        .map((d) => d.label)
        .toList();
    if (!mounted) return;
    setState(() {
      _usbInventory = inventory;
      _androidUsbMessage = adb.isNotEmpty
          ? 'ADB inventory: ${adb.length} target(s) ready.'
          : mtpOnly.isNotEmpty
          ? 'MTP/storage device detected but no ADB interface. Enable Developer Options, USB debugging, then accept the target-phone RSA prompt.'
          : 'No ADB device detected. Connect TARGET phone by OTG and authorize USB debugging.';
      _status = _androidUsbMessage;
    });
  }

  Future<UsbDeviceInfo?> _pickDeviceFromDialog({
    required String title,
    required List<UsbDeviceInfo> devices,
    UsbDeviceInfo? initial,
  }) async {
    if (devices.isEmpty || !mounted) return null;
    var selected =
        initial != null && devices.any((d) => d.deviceId == initial.deviceId)
        ? initial
        : devices.first;
    final result = await showDialog<UsbDeviceInfo>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: FlasherColors.panel,
          title: Text(title, style: GoogleFonts.orbitron()),
          content: SizedBox(
            width: 520,
            child: _UsbPicker(
              devices: devices,
              selectedDeviceId: selected.deviceId,
              onSelected: (device) {
                setLocalState(() {
                  selected = device;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('USE DEVICE'),
            ),
          ],
        ),
      ),
    );
    return result;
  }

  Future<UsbDeviceInfo?> _freshUsbDevice({
    bool adbOnly = false,
    bool checkBattery = true,
  }) async {
    if (checkBattery && !await _acknowledgeBattery()) return null;
    final scanned = adbOnly
        ? await _bridge.listUsbInventory()
        : await _bridge.listUsbDevices();
    final candidates = adbOnly
        ? scanned.where((d) => d.isAdb).toList()
        : scanned.where((d) => !d.isAdb && !d.hasMtpOrStorage).toList();
    if (mounted) {
      setState(() {
        if (adbOnly) {
          _usbInventory = scanned;
          _androidUsbMessage =
              candidates.isEmpty &&
                  scanned.any((d) => d.hasMtpOrStorage && !d.isAdb)
              ? 'MTP-only phone present. Enable/authorize USB debugging; ADB is not available yet.'
              : 'ADB scan complete: ${candidates.length} target(s).';
        } else {
          _devices = scanned;
        }
      });
    }
    if (candidates.isEmpty) {
      _setStatus(
        adbOnly
            ? _androidUsbMessage
            : 'No ESP-class USB serial/JTAG device detected.',
      );
      return null;
    }

    var selected = _selected != null
        ? candidates.where((d) => d.deviceId == _selected!.deviceId).firstOrNull
        : null;
    if (selected == null || candidates.length > 1) {
      selected = await _pickDeviceFromDialog(
        title: adbOnly ? 'SELECT ADB TARGET' : 'SELECT USB FLASH TARGET',
        devices: candidates,
        initial: selected,
      );
    }
    if (selected == null) return null;

    var fresh = scanned.firstWhere((d) => d.deviceId == selected!.deviceId);
    if (!fresh.hasPermission) {
      final granted = await _bridge.requestUsbPermission(fresh.deviceId);
      if (!granted) {
        _setStatus('USB permission denied for ${fresh.label}.');
        return null;
      }
      final rescanned = adbOnly
          ? await _bridge.listUsbInventory()
          : await _bridge.listUsbDevices();
      final matching = rescanned.where((d) => d.deviceId == fresh.deviceId);
      if (matching.isEmpty) {
        _setStatus(
          'USB device changed after permission grant. Re-scan and retry.',
        );
        return null;
      }
      fresh = matching.first;
      if (mounted) {
        setState(() {
          if (adbOnly) {
            _usbInventory = rescanned;
          } else {
            _devices = rescanned;
          }
        });
      }
    }
    if (mounted) {
      setState(() {
        _selected = fresh;
      });
    }
    return fresh;
  }

  int _espOffset() {
    return switch (_addressMode) {
      AddressMode.fullImage => 0x0,
      AddressMode.appOnly => 0x10000,
      AddressMode.custom => _parseOffset(_customOffsetCtrl.text),
    };
  }

  int _parseOffset(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.startsWith('0x')) {
      return int.parse(value.substring(2), radix: 16);
    }
    return int.parse(value);
  }

  Future<void> _showDownloadModeSheet(EspPreset preset, String reason) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlasherColors.panel,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DOWNLOAD MODE', style: GoogleFonts.orbitron(fontSize: 20)),
            const SizedBox(height: 8),
            Text(reason, style: const TextStyle(color: FlasherColors.amber)),
            const SizedBox(height: 16),
            Text(preset.manualBootSteps),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _materializeEspFirmware(FlashTarget target) async {
    final bundle = target.firmwareBundle;
    final preset = target.espPreset;
    if (bundle == null || preset == null) return null;
    final path = await _bridge.materializeAsset(
      bundle.assetPath,
      bundle.fileName,
      expectedSha256: bundle.sha256,
    );
    final bytes = await File(path).length();
    if (bytes > preset.flashSizeHintBytes) {
      final ok = await _confirm(
        title: 'FLASH SIZE WARNING',
        message:
            '${bundle.fileName} is ${_formatBytes(bytes)}, larger than the ${_formatBytes(preset.flashSizeHintBytes)} flash-size hint for ${preset.title}. Continue only if this board has enough flash.',
        action: 'FLASH ANYWAY',
        destructive: true,
      );
      if (!ok) return null;
    }
    return path;
  }

  Future<void> _runEsp({required bool syncOnly}) async {
    final target = _target;
    final preset = target?.espPreset;
    if (target == null || preset == null) return;
    await _withBusy(
      syncOnly ? 'Testing ESP connection...' : 'Flashing ${target.title}...',
      () async {
        final report = OperationReport(
          target: target.name,
          title: syncOnly
              ? '${target.title} connection test'
              : '${target.title} flash',
        );

        if (_eraseAll && !syncOnly) {
          final ok = await _confirm(
            title: 'ERASE ALL FLASH',
            message:
                'Erase all flash before writing ${target.firmwareFileName}? This removes existing firmware, settings, and launchers.',
            action: 'ERASE + FLASH',
            destructive: true,
          );
          if (!ok) return;
        }

        if (!syncOnly) {
          final ok = await _confirm(
            title: 'OVERWRITE WARNING',
            message: preset.overwriteWarning,
            action: 'OVERWRITE',
            destructive: true,
          );
          if (!ok) return;
        }

        if (_skipAutoReset || preset.preferSkipAutoReset) {
          await _showDownloadModeSheet(
            preset,
            'Manual boot is recommended for this target before sync.',
          );
        }

        final device = await _freshUsbDevice(adbOnly: false);
        if (device == null) return;
        report.add(name: 'USB permission', ok: true, detail: device.label);

        String? firmwarePath;
        if (!syncOnly) {
          firmwarePath = await _materializeEspFirmware(target);
          if (firmwarePath == null) return;
          report.add(
            name: 'Firmware SHA verified',
            ok: true,
            detail: target.firmwareBundle!.version,
          );
        }

        final result = await _bridge.flashEsp(
          deviceId: device.deviceId,
          firmwarePath: firmwarePath,
          chip: preset.chip,
          offset: _espOffset(),
          baud: _baud,
          eraseAll: _eraseAll && !syncOnly,
          skipAutoReset: _skipAutoReset,
          syncOnly: syncOnly,
          hardResetAfter: _hardResetAfter,
          flashSizeHint: preset.flashSizeHintBytes,
          serialMonitorMs: _serialMonitorMs,
          target: target.name,
        );
        report.add(
          name: syncOnly ? 'Sync test' : 'Flash',
          ok: result.ok,
          detail: _nativeDetail(result),
        );
        _setStatus(report.summary());
        final text = '${result.message}\n${result.detail}'.toLowerCase();
        if (!result.ok && text.contains('sync failed')) {
          await _showDownloadModeSheet(
            preset,
            'Sync failed. Put the board in download mode, then retry.',
          );
        }
      },
    );
  }

  Future<void> _pickR36Tree() async {
    final tree = await _bridge.pickSdTree();
    if (tree == null || tree.isEmpty) return;
    final candidates = await _bridge.detectR36Paths(tree);
    final all = [
      ...candidates,
      R36PathCandidate(
        label: 'Create roms/ports',
        hint: 'roms/ports',
        exists: false,
      ),
    ];
    if (!mounted) return;
    setState(() {
      _lastSdTreeUri = tree;
      _r36Candidates = all;
      _selectedR36Hint = all.firstOrNull?.hint;
      _status = 'SD tree selected. Choose install path candidate.';
    });
    await _savePrefs();
  }

  Future<String?> _ensureR36Tree({bool forcePick = false}) async {
    if (forcePick || _lastSdTreeUri == null) {
      await _pickR36Tree();
    }
    return _lastSdTreeUri;
  }

  Future<bool> _confirmR36WipeIfNeeded(String action) async {
    if (!_wipePreviousPolybius && !_logicalFormatSd) return true;
    final parts = [
      if (_wipePreviousPolybius) 'wipe previous PØLYBÎŪS files',
      if (_logicalFormatSd) 'perform logical format',
    ].join(' and ');
    return _confirm(
      title: 'CONFIRM SD WRITE',
      message: '$action will $parts on the selected SD tree.',
      action: 'CONTINUE',
      destructive: true,
    );
  }

  Future<NativeResult?> _prepareR36Sd(
    String treeUri,
    OperationReport report,
  ) async {
    if (!await _confirmR36WipeIfNeeded('Prepare SD')) return null;
    final result = await _bridge.prepareSd(
      treeUri: treeUri,
      logicalFormat: _logicalFormatSd,
      wipePrevious: _wipePreviousPolybius,
    );
    report.add(
      name: 'Prepare SD',
      ok: result.ok,
      detail: _nativeDetail(result),
    );
    return result;
  }

  Future<void> _prepareR36Only() async {
    await _withBusy('Preparing R36S SD...', () async {
      final tree = await _ensureR36Tree();
      if (tree == null) return;
      final report = OperationReport(target: 'r36s', title: 'R36S prepare SD');
      await _prepareR36Sd(tree, report);
      _setStatus(report.summary());
    });
  }

  Future<void> _testR36Connection() async {
    await _withBusy('Testing SD write access...', () async {
      final tree = await _ensureR36Tree(forcePick: true);
      if (tree == null) return;
      final report = OperationReport(
        target: 'r36s',
        title: 'R36S SD write test',
      );
      final result = await _bridge.probeSdWrite(tree);
      report.add(
        name: 'Probe SD write',
        ok: result.ok,
        detail: _nativeDetail(result),
      );
      _setStatus(report.summary());
    });
  }

  Future<void> _installR36() async {
    await _withBusy('Installing R36S package...', () async {
      final tree = await _ensureR36Tree();
      if (tree == null) return;
      final report = OperationReport(target: 'r36s', title: 'R36S install');
      if (_prepareSdBeforeFlash) {
        final prep = await _prepareR36Sd(tree, report);
        if (prep == null || !prep.ok) {
          _setStatus(report.summary());
          return;
        }
      }
      final zipPath = await _bridge.materializeAsset(
        AssetIntegrity.r36sZip.assetPath,
        AssetIntegrity.r36sZip.fileName,
        expectedSha256: AssetIntegrity.r36sZip.sha256,
      );
      report.add(
        name: 'R36S zip SHA verified',
        ok: true,
        detail: AssetIntegrity.r36sZip.version,
      );
      final result = await _bridge.installR36s(
        zipPath: zipPath,
        treeUri: tree,
        mode: _r36InstallMode.bridgeValue,
        preferredHint: _selectedR36Hint,
      );
      final extra = [
        _nativeDetail(result),
        if (result.verified) 'verified',
        if (result.portsPath.isNotEmpty) 'portsPath=${result.portsPath}',
      ].where((part) => part.trim().isNotEmpty).join(' · ');
      report.add(name: 'Install package', ok: result.ok, detail: extra);
      _setStatus(report.summary());
    });
  }

  Future<void> _openSystemFormat() async {
    final ok = await _confirm(
      title: 'OPEN SYSTEM FORMAT',
      message:
          'This opens Android system storage format settings. Confirm before wiping or formatting any SD card.',
      action: 'OPEN SETTINGS',
      destructive: true,
    );
    if (!ok) return;
    final result = await _bridge.openSystemSdFormat();
    _setStatus(_nativeDetail(result));
  }

  Future<bool> _authorizeAdbDialog() async {
    if (!mounted) return false;
    var message = _androidUsbMessage;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: FlasherColors.panel,
          title: Text('AUTHORIZE USB DEBUGGING', style: GoogleFonts.orbitron()),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Authorize USB debugging on the TARGET phone.'),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(color: FlasherColors.amber),
                ),
                const SizedBox(height: 12),
                Text(
                  'If the RSA prompt is missing: unplug/replug OTG, set USB mode to file transfer once, then re-scan.',
                  style: TextStyle(color: FlasherColors.dim),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            OutlinedButton(
              onPressed: () async {
                final inventory = await _bridge.listUsbInventory();
                final adb = inventory.where((d) => d.isAdb).length;
                final mtpOnly = inventory.any(
                  (d) => d.hasMtpOrStorage && !d.isAdb,
                );
                if (mounted) {
                  setState(() {
                    _usbInventory = inventory;
                    _androidUsbMessage = adb > 0
                        ? 'ADB inventory: $adb target(s) ready.'
                        : mtpOnly
                        ? 'MTP-only phone detected; USB debugging is not authorized yet.'
                        : 'No ADB target detected.';
                  });
                }
                setLocalState(() {
                  message = _androidUsbMessage;
                });
              },
              child: const Text('RE-SCAN DEVICES'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _pickLocalApk() async {
    final path = await _bridge.pickApk();
    if (path == null || path.isEmpty) return;
    setState(() {
      _localApkPath = path;
      _selectedApkIds.clear();
      _status = 'Local APK selected; catalog selection cleared.';
    });
    await _savePrefs();
  }

  List<_InstallJob> _installJobs() {
    final jobs = FlasherBridge.apkCatalog
        .where((item) => _selectedApkIds.contains(item.id))
        .map(_InstallJob.catalog)
        .toList();
    final local = _localApkPath;
    if (local != null && local.isNotEmpty) {
      jobs.add(_InstallJob.local(local));
    }
    return jobs;
  }

  Future<void> _testAndroidConnection() async {
    await _withBusy('Testing Android ADB USB inventory...', () async {
      await _refreshAndroidInventory();
      final report = OperationReport(
        target: 'android_otg',
        title: 'Android OTG test',
      );
      final device = await _freshUsbDevice(adbOnly: true, checkBattery: false);
      report.add(
        name: 'ADB USB target',
        ok: device != null,
        detail: device?.label ?? _androidUsbMessage,
      );
      _setStatus(report.summary());
    });
  }

  Future<void> _installAndroidApks() async {
    final jobs = _installJobs();
    if (jobs.isEmpty) {
      _setStatus('Select at least one bundled APK or pick a local APK.');
      return;
    }
    if (jobs.length >= 2) {
      final ok = await _confirm(
        title: 'CONFIRM MULTI-APK INSTALL',
        message:
            'Install ${jobs.length} APKs in sequence? Non-fatal failures will be reported and the queue will continue.',
        action: 'INSTALL ${jobs.length}',
      );
      if (!ok) return;
    }
    if (_useTcpAdb) {
      final ok = await _confirm(
        title: 'WIRELESS ADB REQUIRED',
        message:
            'TCP ADB assumes the target is already in adb tcpip mode or Wireless debugging is active at ${_tcpHostCtrl.text.trim()}:${_tcpPortCtrl.text.trim()}.',
        action: 'USE TCP ADB',
      );
      if (!ok) return;
    }

    await _withBusy('Installing Android APK queue...', () async {
      if (!await _acknowledgeBattery()) return;
      await _refreshAndroidInventory(checkBattery: false);
      if (!await _authorizeAdbDialog()) return;

      UsbDeviceInfo? device;
      String host = '';
      int port = 0;
      if (_useTcpAdb) {
        host = _tcpHostCtrl.text.trim();
        port = int.parse(_tcpPortCtrl.text.trim());
      } else {
        device = await _freshUsbDevice(adbOnly: true, checkBattery: false);
        if (device == null) return;
      }

      final report = OperationReport(
        target: 'android_otg',
        title: 'Android APK install queue',
      );

      for (var i = 0; i < jobs.length; i++) {
        final job = jobs[i];
        try {
          _setStatus('Resolving ${job.title} (${i + 1}/${jobs.length})...');
          final path = job.item == null
              ? job.localPath!
              : await _bridge.resolveApk(
                  job.item!,
                  onProgress: (progress, received, total) {
                    if (!mounted) return;
                    setState(() {
                      _progress = progress.clamp(0.0, 1.0);
                      _status =
                          'Resolving ${job.title}: ${_formatBytes(received)} / ${total > 0 ? _formatBytes(total) : 'unknown'}';
                    });
                  },
                );
          _setStatus('Installing ${job.title} (${i + 1}/${jobs.length})...');
          final result = _useTcpAdb
              ? await _bridge.installApkAdbTcp(
                  host: host,
                  port: port,
                  apkPath: path,
                  forceDowngrade: _forceDowngrade,
                  forceUser0: _forceUser0,
                )
              : await _bridge.installApkAdbUsb(
                  deviceId: device!.deviceId,
                  apkPath: path,
                  forceDowngrade: _forceDowngrade,
                  forceUser0: _forceUser0,
                );
          report.add(
            name: job.title,
            ok: result.ok,
            detail: _nativeDetail(result),
          );
        } on Object catch (e) {
          report.add(name: job.title, ok: false, detail: 'exception: $e');
        }
      }
      _setStatus(report.summary());
    });
  }

  Future<void> _setTcpAdb(bool value) async {
    if (!value) {
      setState(() => _useTcpAdb = false);
      await _savePrefs();
      return;
    }
    final ok = await _confirm(
      title: 'ENABLE TCP ADB',
      message:
          'Confirm the target phone is already in adb tcpip mode or Wireless debugging is active. USB authorization is still recommended before switching.',
      action: 'ENABLE TCP',
    );
    if (!ok) return;
    setState(() => _useTcpAdb = true);
    await _savePrefs();
  }

  String _nativeDetail(NativeResult result) {
    final parts = [
      result.message,
      if (result.errorCode.isNotEmpty) 'errorCode=${result.errorCode}',
      if (result.detail.isNotEmpty) result.detail,
      if (result.pmOutput.isNotEmpty) result.pmOutput,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.isEmpty ? (result.ok ? 'OK' : 'FAILED') : parts.join(' · ');
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PØLYBÎŪS FLASHER',
          style: GoogleFonts.orbitron(
            color: FlasherColors.phosphor,
            letterSpacing: 2,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _copyLogs,
            icon: const Icon(Icons.copy_all, size: 18),
            label: const Text('COPY LOGS'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _Atmosphere(animation: _pulse),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroHeader(
                        status: _status,
                        progress: _progress,
                        busy: _busy,
                        onCancel: _cancelOperation,
                      ),
                      const SizedBox(height: 18),
                      _buildTargetTiles(),
                      const SizedBox(height: 18),
                      if (_target != null) _buildTargetPanel(_target!),
                      const SizedBox(height: 18),
                      _Console(logs: _logs),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetTiles() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: FlashTarget.values.map((target) {
        return SizedBox(
          width: target.isEsp ? 300 : 230,
          child: _TargetTile(
            title: target.title,
            subtitle: target.subtitle,
            selected: _target == target,
            icon: target.isAndroidOtg
                ? Icons.android
                : target.isR36s
                ? Icons.sd_storage
                : Icons.developer_board,
            onTap: _busy
                ? null
                : () async {
                    setState(() {
                      _target = target;
                      if (target.isEsp) _applyEspDefaults(target);
                      _status = '${target.title} selected.';
                    });
                    await _savePrefs();
                  },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetPanel(FlashTarget target) {
    return _Panel(
      child: switch (target) {
        FlashTarget.r36s => _buildR36Panel(),
        FlashTarget.androidOtg => _buildAndroidPanel(),
        _ => _buildEspPanel(target),
      },
    );
  }

  Widget _buildEspPanel(FlashTarget target) {
    final preset = target.espPreset!;
    final bundle = target.firmwareBundle!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('${target.title} ESP FLASH'),
        Text(preset.title, style: const TextStyle(color: FlasherColors.amber)),
        const SizedBox(height: 4),
        Text(
          'Bundled ${bundle.label}: ${bundle.version} · ${bundle.fileName}',
          style: const TextStyle(color: FlasherColors.cyan),
        ),
        const SizedBox(height: 4),
        Text(
          'Last USB scan: ${_devices.length} device(s)'
          '${_selected == null ? '' : ' · selected ${_selected!.label}'}',
          style: const TextStyle(color: FlasherColors.dim),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ChoiceBox(
              title: 'Address',
              child: Column(
                children: AddressMode.values
                    .map(
                      (mode) => RadioListTile<AddressMode>(
                        value: mode,
                        groupValue: _addressMode,
                        dense: true,
                        title: Text(mode.label),
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _addressMode = value);
                                _savePrefs();
                              },
                      ),
                    )
                    .toList(),
              ),
            ),
            _ChoiceBox(
              title: 'Baud',
              child: DropdownButtonFormField<int>(
                value: _baud,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _baudOptions
                    .map(
                      (baud) => DropdownMenuItem(
                        value: baud,
                        child: Text(baud == 460800 ? 'Fast 460800' : '$baud'),
                      ),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _baud = value);
                        _savePrefs();
                      },
              ),
            ),
            _ChoiceBox(
              title: 'Serial monitor',
              child: DropdownButtonFormField<int>(
                value: _serialMonitorMs,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('0 ms / off')),
                  DropdownMenuItem(
                    value: 1500,
                    child: Text('Capture Bruce/Launcher 1500 ms'),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _serialMonitorMs = value);
                        _savePrefs();
                      },
              ),
            ),
          ],
        ),
        if (_addressMode == AddressMode.custom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customOffsetCtrl,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Custom offset',
              hintText: '0x0',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _savePrefs(),
          ),
        ],
        const SizedBox(height: 12),
        SwitchListTile(
          value: _eraseAll,
          onChanged: _busy
              ? null
              : (value) {
                  setState(() => _eraseAll = value);
                  _savePrefs();
                },
          title: const Text('Erase all before flash'),
          subtitle: const Text(
            'Requires confirmation before the operation runs.',
          ),
        ),
        SwitchListTile(
          value: _hardResetAfter,
          onChanged: _busy
              ? null
              : (value) {
                  setState(() => _hardResetAfter = value);
                  _savePrefs();
                },
          title: const Text('Hard reset after flash'),
        ),
        SwitchListTile(
          value: _skipAutoReset,
          onChanged: _busy
              ? null
              : (value) {
                  setState(() => _skipAutoReset = value);
                  _savePrefs();
                },
          title: const Text('Skip auto-reset / manual download mode'),
          subtitle: Text(
            preset.preferSkipAutoReset
                ? 'Default ON for T-Deck and other flaky DTR paths.'
                : 'Use when BOOT/RESET must be handled manually.',
          ),
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Advanced ESP package mode'),
          children: const [
            SwitchListTile(
              value: false,
              onChanged: null,
              title: Text('Multi-file mode'),
              subtitle: Text(
                'Multi-file assets not bundled — using merged full image @ 0x0',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _refreshUsb(checkBattery: true),
              icon: const Icon(Icons.usb),
              label: const Text('RE-SCAN USB'),
            ),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _showDownloadModeSheet(
                      preset,
                      'Follow these steps before sync/flash when auto-reset is unreliable.',
                    ),
              icon: const Icon(Icons.info_outline),
              label: const Text('DOWNLOAD MODE HELP'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : () => _runEsp(syncOnly: true),
              icon: const Icon(Icons.cable),
              label: const Text('TEST CONNECTION ONLY'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : () => _runEsp(syncOnly: false),
              icon: const Icon(Icons.flash_on),
              label: const Text('FLASH ESP'),
            ),
            if (_busy)
              OutlinedButton.icon(
                onPressed: _cancelOperation,
                icon: const Icon(Icons.cancel),
                label: const Text('CANCEL'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildR36Panel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('R36S SD HARDENED INSTALL'),
        Text(
          'Bundle: ${AssetIntegrity.r36sZip.label} · ${AssetIntegrity.r36sZip.version}',
          style: const TextStyle(color: FlasherColors.cyan),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickR36Tree,
              icon: const Icon(Icons.folder_open),
              label: const Text('PICK SD TREE'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _testR36Connection,
              icon: const Icon(Icons.fact_check),
              label: const Text('TEST CONNECTION'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _prepareR36Only,
              icon: const Icon(Icons.sd_card_alert),
              label: const Text('PREPARE SD ONLY'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _openSystemFormat,
              icon: const Icon(Icons.settings),
              label: const Text('SYSTEM FORMAT SETTINGS'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lastSdTreeUri != null)
          Text(
            'Selected tree: $_lastSdTreeUri',
            style: const TextStyle(color: FlasherColors.dim),
          ),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: _prepareSdBeforeFlash,
          onChanged: _busy
              ? null
              : (value) {
                  setState(() => _prepareSdBeforeFlash = value ?? true);
                  _savePrefs();
                },
          title: const Text('Prepare SD before install'),
        ),
        CheckboxListTile(
          value: _wipePreviousPolybius,
          onChanged: _busy
              ? null
              : (value) {
                  setState(() => _wipePreviousPolybius = value ?? true);
                  _savePrefs();
                },
          title: const Text('Wipe previous PØLYBÎŪS files'),
        ),
        CheckboxListTile(
          value: _logicalFormatSd,
          onChanged: _busy
              ? null
              : (value) {
                  setState(() => _logicalFormatSd = value ?? false);
                  _savePrefs();
                },
          title: const Text('Logical format selected tree'),
          subtitle: const Text('Requires confirmation before write/prepare.'),
        ),
        const Divider(color: FlasherColors.grid),
        Text('Install mode', style: GoogleFonts.orbitron(fontSize: 14)),
        Wrap(
          children: R36InstallMode.values
              .map(
                (mode) => SizedBox(
                  width: 240,
                  child: RadioListTile<R36InstallMode>(
                    value: mode,
                    groupValue: _r36InstallMode,
                    title: Text(mode.label),
                    onChanged: _busy
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _r36InstallMode = value);
                            _savePrefs();
                          },
                  ),
                ),
              )
              .toList(),
        ),
        if (_r36Candidates.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Detected path candidates',
            style: GoogleFonts.orbitron(fontSize: 14),
          ),
          ..._r36Candidates.map(
            (candidate) => RadioListTile<String>(
              value: candidate.hint,
              groupValue: _selectedR36Hint,
              title: Text(candidate.label),
              subtitle: Text(
                '${candidate.hint} · ${candidate.exists ? 'exists' : 'will create'}',
              ),
              onChanged: _busy
                  ? null
                  : (value) {
                      setState(() => _selectedR36Hint = value);
                    },
            ),
          ),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _busy ? null : _installR36,
          icon: const Icon(Icons.download_for_offline),
          label: const Text('INSTALL R36S PORT'),
        ),
      ],
    );
  }

  Widget _buildAndroidPanel() {
    final bundledCount = FlasherBridge.apkCatalog
        .where((item) => item.isBundled)
        .length;
    final jobs = _installJobs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('ANDROID OTG ADB INSTALLER'),
        Text(
          _androidUsbMessage,
          style: const TextStyle(color: FlasherColors.amber),
        ),
        const SizedBox(height: 4),
        Text(
          'Inventory rows: ${_usbInventory.length}',
          style: const TextStyle(color: FlasherColors.dim),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _refreshAndroidInventory,
              icon: const Icon(Icons.usb),
              label: const Text('RE-SCAN DEVICES'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _testAndroidConnection,
              icon: const Icon(Icons.cable),
              label: const Text('TEST CONNECTION'),
            ),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      setState(() {
                        _selectedApkIds
                          ..clear()
                          ..addAll(
                            FlasherBridge.apkCatalog
                                .where((item) => item.isBundled)
                                .map((item) => item.id),
                          );
                        _localApkPath = null;
                      });
                      _savePrefs();
                    },
              icon: const Icon(Icons.select_all),
              label: Text('SELECT ALL BUNDLED ($bundledCount)'),
            ),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      setState(() {
                        _selectedApkIds.clear();
                        _localApkPath = null;
                      });
                      _savePrefs();
                    },
              icon: const Icon(Icons.clear_all),
              label: const Text('CLEAR ALL'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickLocalApk,
              icon: const Icon(Icons.android),
              label: const Text('PICK LOCAL APK'),
            ),
          ],
        ),
        if (_localApkPath != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Local APK: $_localApkPath',
                  style: const TextStyle(color: FlasherColors.cyan),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() => _localApkPath = null);
                        _savePrefs();
                      },
                child: const Text('CLEAR LOCAL'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _ApkCatalogList(
          selectedIds: _selectedApkIds,
          enabled: !_busy,
          onChanged: (item, selected) {
            setState(() {
              _localApkPath = null;
              if (selected) {
                _selectedApkIds.add(item.id);
              } else {
                _selectedApkIds.remove(item.id);
              }
            });
            _savePrefs();
          },
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Advanced ADB flags'),
          children: [
            CheckboxListTile(
              value: _forceDowngrade,
              onChanged: _busy
                  ? null
                  : (value) {
                      setState(() => _forceDowngrade = value ?? false);
                      _savePrefs();
                    },
              title: const Text('forceDowngrade (-d)'),
            ),
            CheckboxListTile(
              value: _forceUser0,
              onChanged: _busy
                  ? null
                  : (value) {
                      setState(() => _forceUser0 = value ?? true);
                      _savePrefs();
                    },
              title: const Text('forceUser0 (--user 0)'),
            ),
            SwitchListTile(
              value: _useTcpAdb,
              onChanged: _busy ? null : _setTcpAdb,
              title: const Text('useTcpAdb'),
              subtitle: const Text(
                'Requires target already in adb tcpip / wireless debugging.',
              ),
            ),
            if (_useTcpAdb)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tcpHostCtrl,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          labelText: 'ADB host',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _savePrefs(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _tcpPortCtrl,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _savePrefs(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _installAndroidApks,
          icon: const Icon(Icons.install_mobile),
          label: Text(
            jobs.length <= 1 ? 'INSTALL APK' : 'INSTALL ${jobs.length} APKS',
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.status,
    required this.progress,
    required this.busy,
    required this.onCancel,
  });

  final String status;
  final double progress;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FlasherColors.panel.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: FlasherColors.phosphor.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: FlasherColors.phosphor.withValues(alpha: 0.12),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HARDENED FLASH CONTROL',
                  style: GoogleFonts.orbitron(
                    color: FlasherColors.phosphor,
                    fontSize: 22,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              if (busy)
                OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel),
                  label: const Text('CANCEL'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(status),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: busy ? progress.clamp(0.0, 1.0) : progress,
              minHeight: 8,
              backgroundColor: FlasherColors.voidBlack,
              color: busy ? FlasherColors.amber : FlasherColors.phosphor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => CustomPaint(
        painter: _AtmospherePainter(animation.value),
        size: Size.infinite,
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [FlasherColors.voidBlack, Color(0xFF091015), Color(0xFF020305)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = FlasherColors.grid
      ..strokeWidth = 1;
    const step = 36.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              FlasherColors.phosphor.withValues(alpha: 0.08 + value * 0.05),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.72, size.height * 0.18),
              radius: size.width * 0.45,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);

    final scan = Paint()..color = Colors.white.withValues(alpha: 0.025);
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scan);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? FlasherColors.phosphor : FlasherColors.dim;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? FlasherColors.panelHot.withValues(alpha: 0.95)
              : FlasherColors.panel.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.9 : 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      color: selected ? FlasherColors.phosphor : Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: FlasherColors.dim),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsbPicker extends StatelessWidget {
  const _UsbPicker({
    required this.devices,
    required this.selectedDeviceId,
    required this.onSelected,
  });

  final List<UsbDeviceInfo> devices;
  final int? selectedDeviceId;
  final ValueChanged<UsbDeviceInfo> onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          final serial = device.serial.trim().isEmpty
              ? 'unknown serial'
              : device.serial;
          return RadioListTile<int>(
            value: device.deviceId,
            groupValue: selectedDeviceId,
            onChanged: (_) => onSelected(device),
            title: Text(device.label),
            subtitle: Text(
              'serial: $serial · permission: ${device.hasPermission ? 'granted' : 'request needed'}',
            ),
          );
        },
      ),
    );
  }
}

class _Console extends StatelessWidget {
  const _Console({required this.logs});

  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('EVENT CONSOLE (${logs.length}/200)'),
          const SizedBox(height: 8),
          Container(
            height: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FlasherColors.grid),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No bridge events yet.',
                      style: TextStyle(color: FlasherColors.dim),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final line = logs[logs.length - 1 - index];
                      final color =
                          line.contains('[error]') || line.contains(' FAIL ')
                          ? FlasherColors.danger
                          : line.contains('[warn]')
                          ? FlasherColors.amber
                          : line.contains('[success]') || line.contains(' OK ')
                          ? FlasherColors.phosphor
                          : Colors.white70;
                      return Text(
                        line,
                        style: TextStyle(color: color, fontSize: 12),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FlasherColors.panel.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FlasherColors.grid),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        color: FlasherColors.phosphor,
        fontSize: 18,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ChoiceBox extends StatelessWidget {
  const _ChoiceBox({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.orbitron(fontSize: 13)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ApkCatalogList extends StatelessWidget {
  const _ApkCatalogList({
    required this.selectedIds,
    required this.enabled,
    required this.onChanged,
  });

  final Set<String> selectedIds;
  final bool enabled;
  final void Function(ApkCatalogItem item, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FlasherColors.grid),
      ),
      child: Column(
        children: FlasherBridge.apkCatalog.map((item) {
          return CheckboxListTile(
            value: selectedIds.contains(item.id),
            onChanged: enabled
                ? (value) => onChanged(item, value ?? false)
                : null,
            title: Text(item.title),
            subtitle: Text(
              [
                item.subtitle,
                if (item.version.isNotEmpty) item.version,
                item.isBundled ? 'bundled' : 'download',
                item.fileName,
              ].where((part) => part.trim().isNotEmpty).join(' · '),
            ),
          );
        }).toList(),
      ),
    );
  }
}
