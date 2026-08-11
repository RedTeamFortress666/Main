import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flasher_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PolybiusFlasherApp());
}

class PolybiusFlasherApp extends StatelessWidget {
  const PolybiusFlasherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FlasherColors.voidBlack,
      colorScheme: const ColorScheme.dark(
        primary: FlasherColors.phosphor,
        secondary: FlasherColors.amber,
        surface: FlasherColors.panel,
      ),
      textTheme: GoogleFonts.shareTechMonoTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'PØLYBÎŪS FLASHER',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(
          bodyColor: FlasherColors.phosphor,
          displayColor: FlasherColors.phosphor,
        ),
      ),
      home: const FlasherHomePage(),
    );
  }
}

class FlasherColors {
  static const voidBlack = Color(0xFF05070A);
  static const panel = Color(0xFF0C1218);
  static const phosphor = Color(0xFF5CFF8A);
  static const amber = Color(0xFFFFB84D);
  static const dim = Color(0xFF6B7C6E);
  static const danger = Color(0xFFFF4D6A);
  static const grid = Color(0x145CFF8A);
}

enum FlashTarget { r36s, cyd, esp32e, tdeck, androidOtg }

extension FlashTargetX on FlashTarget {
  bool get isEsp =>
      this == FlashTarget.cyd ||
      this == FlashTarget.esp32e ||
      this == FlashTarget.tdeck;

  bool get isAndroidOtg => this == FlashTarget.androidOtg;

  String get defaultChip =>
      this == FlashTarget.tdeck ? 'esp32s3' : 'esp32';

  int get defaultBaud => switch (this) {
        FlashTarget.esp32e => 460800,
        FlashTarget.cyd => 115200,
        FlashTarget.tdeck => 115200,
        FlashTarget.r36s => 115200,
        FlashTarget.androidOtg => 115200,
      };

  String get firmwareAsset => switch (this) {
        FlashTarget.cyd || FlashTarget.esp32e =>
          'assets/firmware/polybius-cyd.bin',
        FlashTarget.tdeck => 'assets/firmware/polybius-tdeck.bin',
        FlashTarget.r36s || FlashTarget.androidOtg => '',
      };

  String get firmwareFileName => switch (this) {
        FlashTarget.cyd || FlashTarget.esp32e => 'polybius-cyd.bin',
        FlashTarget.tdeck => 'polybius-tdeck.bin',
        FlashTarget.r36s || FlashTarget.androidOtg => '',
      };
}

enum AddressMode { fullImage, appOnly, custom }

class FlasherHomePage extends StatefulWidget {
  const FlasherHomePage({super.key});

  @override
  State<FlasherHomePage> createState() => _FlasherHomePageState();
}

class _FlasherHomePageState extends State<FlasherHomePage>
    with SingleTickerProviderStateMixin {
  FlashTarget? _target;
  List<UsbDeviceInfo> _devices = [];
  UsbDeviceInfo? _selected;
  bool _busy = false;
  double _progress = 0;
  int _written = 0;
  int _total = 0;
  final _logs = <String>[];
  String? _status;
  late final AnimationController _pulse;
  StreamSubscription<String>? _logSub;
  StreamSubscription<ProgressInfo>? _progressSub;

  // ESP options
  AddressMode _addressMode = AddressMode.fullImage;
  final _customOffsetCtrl = TextEditingController(text: '0x0');
  String _chip = 'esp32s3';
  int _baud = 115200;
  bool _eraseAll = false;
  bool _hardResetAfter = true;
  bool _skipAutoReset = false;

  String? _lastSdTreeUri;
  bool _didAutoSuggest = false;

  // Android OTG ADB
  ApkCatalogItem? _apkItem;
  String? _localApkPath;
  bool _useTcpAdb = false;
  final _tcpHostCtrl = TextEditingController(text: '192.168.1.1');
  final _tcpPortCtrl = TextEditingController(text: '5555');

  static const _baudOptions = [115200, 230400, 460800, 921600];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    FlasherBridge.instance.ensureListening();
    _logSub = FlasherBridge.instance.logs.listen((line) {
      setState(() {
        _logs.add(line);
        if (_logs.length > 120) _logs.removeAt(0);
      });
    });
    _progressSub = FlasherBridge.instance.progress.listen((p) {
      setState(() {
        _progress = p.progress.clamp(0.0, 1.0);
        _written = p.written;
        _total = p.total;
      });
    });
    _loadPrefs();
    _refreshUsb();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _logSub?.cancel();
    _progressSub?.cancel();
    _customOffsetCtrl.dispose();
    _tcpHostCtrl.dispose();
    _tcpPortCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSdTreeUri = prefs.getString('r36s_tree_uri');
      final t = prefs.getString('last_target');
      _target = switch (t) {
        'cyd' => FlashTarget.cyd,
        'esp32e' => FlashTarget.esp32e,
        'tdeck' => FlashTarget.tdeck,
        'r36s' => FlashTarget.r36s,
        'androidOtg' => FlashTarget.androidOtg,
        _ => null,
      };
      if (_target == FlashTarget.androidOtg) {
        final apkId = prefs.getString('android_apk_id');
        _apkItem = FlasherBridge.apkCatalog
            .where((a) => a.id == apkId)
            .firstOrNull;
        _useTcpAdb = prefs.getBool('android_use_tcp') ?? false;
        _tcpHostCtrl.text = prefs.getString('android_tcp_host') ?? '192.168.1.1';
        _tcpPortCtrl.text = prefs.getString('android_tcp_port') ?? '5555';
      }
      if (_target != null && _target!.isEsp) {
        _applyTargetDefaults(_target!, loadSaved: true, prefs: prefs);
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _target?.name;
    if (key == null) return;
    await prefs.setString('last_target', key);
    if (_target == FlashTarget.r36s) {
      if (_lastSdTreeUri != null) {
        await prefs.setString('r36s_tree_uri', _lastSdTreeUri!);
      }
      return;
    }
    if (_target == FlashTarget.androidOtg) {
      if (_apkItem != null) {
        await prefs.setString('android_apk_id', _apkItem!.id);
      }
      await prefs.setBool('android_use_tcp', _useTcpAdb);
      await prefs.setString('android_tcp_host', _tcpHostCtrl.text.trim());
      await prefs.setString('android_tcp_port', _tcpPortCtrl.text.trim());
      return;
    }
    await prefs.setString('${key}_addressMode', _addressMode.name);
    await prefs.setString('${key}_customOffset', _customOffsetCtrl.text);
    await prefs.setString('${key}_chip', _chip);
    await prefs.setInt('${key}_baud', _baud);
    await prefs.setBool('${key}_eraseAll', _eraseAll);
    await prefs.setBool('${key}_hardReset', _hardResetAfter);
  }

  void _applyTargetDefaults(
    FlashTarget t, {
    bool loadSaved = false,
    SharedPreferences? prefs,
  }) {
    if (t == FlashTarget.r36s || t == FlashTarget.androidOtg) return;
    final key = t.name;
    if (loadSaved && prefs != null) {
      final mode = prefs.getString('${key}_addressMode');
      _addressMode = AddressMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => AddressMode.fullImage,
      );
      _customOffsetCtrl.text =
          prefs.getString('${key}_customOffset') ?? '0x0';
      _chip = prefs.getString('${key}_chip') ?? t.defaultChip;
      _baud = prefs.getInt('${key}_baud') ?? t.defaultBaud;
      _eraseAll = prefs.getBool('${key}_eraseAll') ?? false;
      _hardResetAfter = prefs.getBool('${key}_hardReset') ?? true;
      return;
    }
    _chip = t.defaultChip;
    _addressMode = AddressMode.fullImage;
    _customOffsetCtrl.text = '0x0';
    _baud = t.defaultBaud;
    _eraseAll = false;
    _skipAutoReset = false;
  }

  Future<void> _selectTarget(FlashTarget t) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _target = t;
      _applyTargetDefaults(t, loadSaved: true, prefs: prefs);
    });
    await prefs.setString('last_target', t.name);
  }

  Future<void> _refreshUsb() async {
    try {
      if (_target == FlashTarget.androidOtg) {
        final list = await FlasherBridge.instance.listAdbUsbDevices();
        setState(() {
          _devices = list;
          if (_selected != null) {
            _selected = list
                .where((d) => d.deviceId == _selected!.deviceId)
                .firstOrNull;
          }
        });
        for (final d in list) {
          _append('ADB ${d.label}');
        }
        return;
      }
      final list = await FlasherBridge.instance.listUsbDevices();
      setState(() {
        _devices = list;
        if (_selected != null) {
          _selected = list
              .where((d) => d.deviceId == _selected!.deviceId)
              .firstOrNull;
        }
      });
      for (final d in list) {
        _append('USB ${d.label}');
      }
      await _maybeSuggestEsp32e(list);
    } catch (e) {
      _append('USB scan failed: $e');
    }
  }

  /// Classic ESP32 UART bridges (CP210x / CH340 / FTDI) — not Espressif USB-JTAG.
  Future<void> _maybeSuggestEsp32e(List<UsbDeviceInfo> list) async {
    if (_didAutoSuggest || _target != null || list.isEmpty || !mounted) return;
    final classic = list.where((d) => !d.usbJtag).toList();
    if (classic.isEmpty) return;
    _didAutoSuggest = true;
    final d = classic.first;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlasherColors.panel,
        title: Text(
          'CLASSIC ESP32 DETECTED?',
          style: GoogleFonts.orbitron(color: FlasherColors.amber, fontSize: 13),
        ),
        content: Text(
          'USB ${d.label}\n\n'
          'This looks like a classic ESP32 UART bridge (not S3 USB-JTAG). '
          'Use ESP32-32E 240×320 Resistive / CYD-compatible target?',
          style: GoogleFonts.shareTechMono(
            color: FlasherColors.phosphor,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('NO', style: GoogleFonts.shareTechMono()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'YES — ESP32-32E',
              style: GoogleFonts.shareTechMono(color: FlasherColors.phosphor),
            ),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      await _selectTarget(FlashTarget.esp32e);
      setState(() => _selected = d);
    }
  }

  void _append(String line) {
    setState(() {
      _logs.add(line);
      if (_logs.length > 120) _logs.removeAt(0);
    });
  }

  int get _resolvedOffset {
    switch (_addressMode) {
      case AddressMode.fullImage:
        return 0x0;
      case AddressMode.appOnly:
        return 0x10000;
      case AddressMode.custom:
        final raw = _customOffsetCtrl.text.trim().toLowerCase();
        return int.tryParse(
              raw.startsWith('0x') ? raw.substring(2) : raw,
              radix: raw.startsWith('0x') ? 16 : 10,
            ) ??
            0x0;
    }
  }

  String get _downloadInstructions {
    switch (_target) {
      case FlashTarget.tdeck:
        return 'T-Deck (ESP32-S3 USB-JTAG)\n\n'
            '1. Plug USB-OTG into the phone and the T-Deck.\n'
            '2. Hold the trackball CENTER button (BOOT / GPIO0).\n'
            '3. Power on or press RST while still holding.\n'
            '4. Keep holding 2–3 seconds until the screen stays black.\n'
            '5. Release BOOT, then tap CONTINUE FLASH.\n\n'
            'Android often cannot auto-reset USB-JTAG — manual entry is normal.';
      case FlashTarget.cyd:
        return 'CYD ESP32-2432S028\n\n'
            '1. Plug USB-OTG into the phone and the CYD.\n'
            '2. Hold BOOT.\n'
            '3. Press & release RESET.\n'
            '4. Release BOOT.\n'
            '5. Tap CONTINUE FLASH.\n\n'
            'If auto-reset works you can skip the buttons — we still try DTR/RTS first.';
      case FlashTarget.esp32e:
        return 'ESP32-32E 240×320 Resistive\n\n'
            '1. Plug USB-OTG into the phone and the board.\n'
            '2. Hold BOOT.\n'
            '3. Press and release RESET.\n'
            '4. Release BOOT.\n'
            '5. Keep holding BOOT until the flasher says “Syncing…”, '
            'then release and tap CONTINUE FLASH.\n\n'
            'Common “ESP32-32E + 2.8″ 240×320 resistive” boards are often '
            'sold as CYD-compatible — same polybius-cyd.bin firmware.';
      default:
        return '';
    }
  }

  Future<_DownloadModeChoice?> _showDownloadModeSheet() async {
    return showModalBottomSheet<_DownloadModeChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlasherColors.panel,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'DOWNLOAD MODE',
                  style: GoogleFonts.orbitron(
                    color: FlasherColors.amber,
                    letterSpacing: 3,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _downloadInstructions,
                  style: GoogleFonts.shareTechMono(
                    color: FlasherColors.phosphor.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _DownloadModeChoice.auto),
                  style: FilledButton.styleFrom(
                    backgroundColor: FlasherColors.phosphor,
                    foregroundColor: FlasherColors.voidBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    'CONTINUE FLASH (TRY AUTO-RESET)',
                    style: GoogleFonts.shareTechMono(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _DownloadModeChoice.manualReady),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FlasherColors.amber,
                    side: const BorderSide(color: FlasherColors.amber),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    'I ALREADY PUT DEVICE IN DOWNLOAD MODE — SKIP',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.shareTechMono(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.shareTechMono(color: FlasherColors.dim),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showManualFailSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: FlasherColors.panel,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'SYNC FAILED',
                  style: GoogleFonts.orbitron(
                    color: FlasherColors.danger,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ROM never answered cmd 0x08.\n\n$_downloadInstructions\n\n'
                  'Then tap FLASH again and choose “I already put the device in download mode”.',
                  style: GoogleFonts.shareTechMono(
                    color: FlasherColors.phosphor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: FlasherColors.amber,
                    foregroundColor: FlasherColors.voidBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text('GOT IT', style: GoogleFonts.shareTechMono()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _run({bool testOnly = false}) async {
    final target = _target;
    if (target == null || _busy) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _written = 0;
      _total = 0;
      _status = null;
      _logs.clear();
    });
    try {
      switch (target) {
        case FlashTarget.r36s:
          await _runR36s();
        case FlashTarget.cyd:
        case FlashTarget.esp32e:
        case FlashTarget.tdeck:
          await _runEsp(
            asset: target.firmwareAsset,
            fileName: target.firmwareFileName,
            testOnly: testOnly,
          );
        case FlashTarget.androidOtg:
          if (testOnly) {
            setState(() => _status = 'Test connection not used for Android OTG');
            return;
          }
          await _runAndroidOtg();
      }
    } catch (e) {
      setState(() => _status = 'Failed: $e');
      _append('ERROR $e');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _savePrefs();
    }
  }

  Future<void> _runR36s() async {
    _append('Select the SD card roms/ or roms/ports/ folder…');
    if (_lastSdTreeUri != null) {
      _append('Last folder remembered — picker will open (re-select if needed).');
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlasherColors.panel,
        title: Text(
          'R36S SD FOLDER',
          style: GoogleFonts.orbitron(color: FlasherColors.amber, fontSize: 14),
        ),
        content: Text(
          'Select the roms or roms/ports folder on the SD card '
          '(ArkOS / JELOS / PortMaster).\n\n'
          'Example paths: /roms/ports or /roms2/ports',
          style: GoogleFonts.shareTechMono(
            color: FlasherColors.phosphor,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OPEN PICKER', style: GoogleFonts.shareTechMono()),
          ),
        ],
      ),
    );

    final zip = await FlasherBridge.instance.materializeAsset(
      'assets/r36s/polybius-r36s-port.zip',
      'polybius-r36s-port.zip',
    );
    final tree = await FlasherBridge.instance.pickSdTree();
    if (tree == null) {
      setState(
        () => _status =
            'No SD folder selected — open the picker and choose roms/ or roms/ports/',
      );
      _append('Cancelled folder picker.');
      return;
    }
    _lastSdTreeUri = tree;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('r36s_tree_uri', tree);
    _append('Writing PortMaster layout…');
    final result = await FlasherBridge.instance.installR36s(
      zipPath: zip,
      treeUri: tree,
    );
    setState(() => _status = result.message);
    _append(result.ok ? 'OK ${result.message}' : 'FAIL ${result.message}');
  }

  Future<UsbDeviceInfo?> _ensureDevice() async {
    await _refreshUsb();
    if (_devices.isEmpty) {
      setState(
        () => _status =
            'No USB serial device — use a USB-OTG cable and plug in the board',
      );
      return null;
    }
    var device = _selected ?? _devices.first;
    if (!device.hasPermission) {
      _append('Requesting USB permission…');
      final ok =
          await FlasherBridge.instance.requestUsbPermission(device.deviceId);
      if (!ok) {
        setState(() => _status = 'USB permission denied');
        return null;
      }
      await _refreshUsb();
      device = _devices
              .where((d) => d.deviceId == device.deviceId)
              .firstOrNull ??
          device;
    }
    return device;
  }

  Future<void> _runEsp({
    required String asset,
    required String fileName,
    required bool testOnly,
  }) async {
    final choice = await _showDownloadModeSheet();
    if (choice == null) {
      setState(() => _status = 'Cancelled');
      return;
    }
    _skipAutoReset = choice == _DownloadModeChoice.manualReady;

    final device = await _ensureDevice();
    if (device == null) return;

    _append(device.label);
    final offset = _resolvedOffset;
    _append(
      testOnly
          ? 'Test connection only — chip=$_chip baud=$_baud'
          : 'Flash $fileName · chip=$_chip · offset=0x${offset.toRadixString(16)} · baud=$_baud'
              '${_eraseAll ? ' · erase-all' : ''}',
    );

    String? path;
    if (!testOnly) {
      path = await FlasherBridge.instance.materializeAsset(asset, fileName);
      _append('Cached firmware: $path');
    }

    final result = await FlasherBridge.instance.flashEsp(
      deviceId: device.deviceId,
      firmwarePath: path,
      chip: _chip,
      offset: offset,
      baud: _baud,
      eraseAll: _eraseAll && !testOnly,
      skipAutoReset: _skipAutoReset,
      syncOnly: testOnly,
      hardResetAfter: _hardResetAfter && !testOnly,
    );

    setState(() => _status = result.message);
    _append(result.ok ? 'OK ${result.message}' : 'FAIL ${result.message}');

    if (!result.ok &&
        result.message.toLowerCase().contains('sync failed') &&
        mounted) {
      await _showManualFailSheet();
    }
  }

  Future<void> _runAndroidOtg() async {
    final localPath = _localApkPath;
    final catalog = _apkItem;
    if (localPath == null && catalog == null) {
      setState(() => _status = 'Pick a catalog APK or a local .apk file');
      return;
    }

    if (!_useTcpAdb) {
      final ok = await _confirmAndroidOtg();
      if (!ok) {
        setState(() => _status = 'Cancelled');
        return;
      }
    }

    late final String apkPath;
    if (localPath != null) {
      apkPath = localPath;
      _append('Using local APK: $apkPath');
    } else {
      _append('Downloading ${catalog!.fileName}…');
      setState(() => _status = 'Downloading ${catalog.title}…');
      apkPath = await FlasherBridge.instance.downloadApk(
        catalog,
        onProgress: (p, recv, total) {
          setState(() {
            _progress = p.clamp(0.0, 1.0);
            _written = recv;
            _total = total;
          });
        },
      );
      _append('Cached: $apkPath');
    }

    if (_useTcpAdb) {
      final host = _tcpHostCtrl.text.trim();
      final port = int.tryParse(_tcpPortCtrl.text.trim()) ?? 5555;
      _append('TCP ADB install → $host:$port');
      setState(() => _status = 'Installing over TCP ADB…');
      final result = await FlasherBridge.instance.installApkAdbTcp(
        host: host,
        port: port,
        apkPath: apkPath,
      );
      setState(() => _status = result.message);
      _append(result.ok ? 'OK ${result.message}' : 'FAIL ${result.message}');
      return;
    }

    final device = await _ensureAdbDevice();
    if (device == null) return;
    _append(device.label);
    setState(() => _status = 'Installing over USB OTG ADB…');
    final result = await FlasherBridge.instance.installApkAdbUsb(
      deviceId: device.deviceId,
      apkPath: apkPath,
    );
    setState(() => _status = result.message);
    _append(result.ok ? 'OK ${result.message}' : 'FAIL ${result.message}');
  }

  Future<bool> _confirmAndroidOtg() async {
    if (!mounted) return false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlasherColors.panel,
        title: Text(
          'ANDROID OTG ADB',
          style: GoogleFonts.orbitron(color: FlasherColors.amber, fontSize: 14),
        ),
        content: Text(
          'On the TARGET phone:\n'
          '1. Enable Developer options → USB debugging\n'
          '2. Connect with a data OTG cable (host = this flasher phone)\n'
          '3. When prompted, tap Allow USB debugging (RSA key)\n'
          '4. Leave the target unlocked during install\n\n'
          'Then tap INSTALL.',
          style: GoogleFonts.shareTechMono(
            color: FlasherColors.phosphor,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: GoogleFonts.shareTechMono()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'INSTALL',
              style: GoogleFonts.shareTechMono(color: FlasherColors.phosphor),
            ),
          ),
        ],
      ),
    );
    return go == true;
  }

  Future<UsbDeviceInfo?> _ensureAdbDevice() async {
    await _refreshUsb();
    if (_devices.isEmpty) {
      setState(
        () => _status =
            'No ADB USB device — enable USB debugging on the target and reconnect OTG',
      );
      return null;
    }
    var device = _selected ?? _devices.first;
    if (!device.hasPermission) {
      _append('Requesting USB permission…');
      final ok =
          await FlasherBridge.instance.requestUsbPermission(device.deviceId);
      if (!ok) {
        setState(() => _status = 'USB permission denied');
        return null;
      }
      await _refreshUsb();
      device = _devices
              .where((d) => d.deviceId == device.deviceId)
              .firstOrNull ??
          device;
    }
    return device;
  }

  Future<void> _pickLocalApk() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['apk'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) {
      _append('Could not read picked APK path');
      return;
    }
    setState(() {
      _localApkPath = path;
      _apkItem = null;
    });
    _append('Local APK selected: $path');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Atmosphere(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 48 : 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroHeader(pulse: _pulse),
                      const SizedBox(height: 20),
                      Expanded(
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: SingleChildScrollView(
                                      child: _buildControls(),
                                    ),
                                  ),
                                  const SizedBox(width: 28),
                                  Expanded(flex: 6, child: _buildConsole()),
                                ],
                              )
                            : ListView(
                                children: [
                                  _buildControls(),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 380,
                                    child: _buildConsole(),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final esp = _target?.isEsp ?? false;
    final android = _target?.isAndroidOtg ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SELECT TARGET',
          style: GoogleFonts.shareTechMono(
            color: FlasherColors.amber,
            letterSpacing: 3,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        _TargetTile(
          selected: _target == FlashTarget.r36s,
          title: 'R36S',
          subtitle: 'Install Port zip into SD roms/ports (ArkOS / JELOS)',
          enabled: !_busy,
          onTap: () => _selectTarget(FlashTarget.r36s),
        ),
        const SizedBox(height: 10),
        _TargetTile(
          selected: _target == FlashTarget.cyd,
          title: 'CYD ESP32-2432S028',
          subtitle: 'USB flash · polybius-cyd.bin · default full image @ 0x0',
          enabled: !_busy,
          onTap: () => _selectTarget(FlashTarget.cyd),
        ),
        const SizedBox(height: 10),
        _TargetTile(
          selected: _target == FlashTarget.esp32e,
          title: 'ESP32-32E 240×320 Resistive',
          subtitle:
              'USB serial flash · polybius-cyd.bin @ 0x0 · chip esp32',
          enabled: !_busy,
          onTap: () => _selectTarget(FlashTarget.esp32e),
        ),
        if (_target == FlashTarget.esp32e) ...[
          const SizedBox(height: 8),
          Text(
            'Note: common ESP32-32E + 2.8″ 240×320 resistive boards are often '
            'sold as CYD-compatible — same firmware as CYD.',
            style: GoogleFonts.shareTechMono(
              color: FlasherColors.dim,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 10),
        _TargetTile(
          selected: _target == FlashTarget.tdeck,
          title: 'LilyGO T-Deck',
          subtitle:
              'USB-JTAG flash · polybius-tdeck.bin · default full image @ 0x0',
          enabled: !_busy,
          onTap: () => _selectTarget(FlashTarget.tdeck),
        ),
        const SizedBox(height: 10),
        _TargetTile(
          selected: _target == FlashTarget.androidOtg,
          title: 'ANDROID (OTG ADB)',
          subtitle:
              'Install Portal / V.1 / Doomsday / etc onto another phone via USB',
          enabled: !_busy,
          onTap: () async {
            await _selectTarget(FlashTarget.androidOtg);
            await _refreshUsb();
          },
        ),
        if (esp) ...[
          const SizedBox(height: 16),
          _UsbPicker(
            devices: _devices,
            selected: _selected,
            busy: _busy,
            emptyHint: 'None found — connect OTG cable to the board.',
            onRefresh: _refreshUsb,
            onSelect: (d) => setState(() => _selected = d),
          ),
          const SizedBox(height: 16),
          _buildEspOptions(),
        ],
        if (android) ...[
          const SizedBox(height: 16),
          _buildAndroidOtgOptions(),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: (_target != null && !_busy) ? () => _run() : null,
          style: FilledButton.styleFrom(
            backgroundColor: FlasherColors.phosphor,
            foregroundColor: FlasherColors.voidBlack,
            disabledBackgroundColor: FlasherColors.dim.withValues(alpha: 0.3),
            minimumSize: const Size.fromHeight(52),
            shape: const RoundedRectangleBorder(),
          ),
          child: Text(
            _busy
                ? 'WORKING…'
                : android
                    ? 'INSTALL APK'
                    : 'FLASH',
            style: GoogleFonts.shareTechMono(
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              fontSize: 16,
            ),
          ),
        ),
        if (esp) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : () => _run(testOnly: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: FlasherColors.amber,
              side: const BorderSide(color: FlasherColors.amber),
              minimumSize: const Size.fromHeight(48),
              shape: const RoundedRectangleBorder(),
            ),
            child: Text(
              'TEST CONNECTION ONLY',
              style: GoogleFonts.shareTechMono(letterSpacing: 1),
            ),
          ),
        ],
        if (_busy) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => FlasherBridge.instance.cancelFlash(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.shareTechMono(color: FlasherColors.danger),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAndroidOtgOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'APK TO INSTALL',
          style: GoogleFonts.shareTechMono(
            color: FlasherColors.amber,
            letterSpacing: 2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Downloads once into cache, then pushes over ADB sync + pm install.',
          style: GoogleFonts.shareTechMono(
            color: FlasherColors.dim,
            fontSize: 11,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in FlasherBridge.apkCatalog) ...[
          InkWell(
            onTap: _busy
                ? null
                : () => setState(() {
                      _apkItem = item;
                      _localApkPath = null;
                    }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _apkItem?.id == item.id && _localApkPath == null
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: FlasherColors.phosphor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            color: FlasherColors.phosphor,
                          ),
                        ),
                        Text(
                          item.subtitle,
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10,
                            color: FlasherColors.dim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : _pickLocalApk,
          style: OutlinedButton.styleFrom(
            foregroundColor: FlasherColors.amber,
            side: const BorderSide(color: FlasherColors.amber),
            minimumSize: const Size.fromHeight(44),
            shape: const RoundedRectangleBorder(),
          ),
          child: Text(
            _localApkPath == null
                ? 'PICK LOCAL .APK'
                : 'LOCAL: ${_localApkPath!.split('/').last}',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _useTcpAdb,
          activeColor: FlasherColors.phosphor,
          title: Text(
            'Use TCP ADB instead of USB (adb tcpip 5555)',
            style: GoogleFonts.shareTechMono(fontSize: 12),
          ),
          onChanged: _busy
              ? null
              : (v) => setState(() => _useTcpAdb = v ?? false),
        ),
        if (_useTcpAdb) ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _tcpHostCtrl,
                  enabled: !_busy,
                  style: GoogleFonts.shareTechMono(color: FlasherColors.phosphor),
                  decoration: InputDecoration(
                    labelText: 'HOST',
                    labelStyle: GoogleFonts.shareTechMono(color: FlasherColors.dim),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tcpPortCtrl,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.shareTechMono(color: FlasherColors.phosphor),
                  decoration: InputDecoration(
                    labelText: 'PORT',
                    labelStyle: GoogleFonts.shareTechMono(color: FlasherColors.dim),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          _UsbPicker(
            devices: _devices,
            selected: _selected,
            busy: _busy,
            emptyHint:
                'No ADB gadget — enable USB debugging on the target phone.',
            onRefresh: _refreshUsb,
            onSelect: (d) => setState(() => _selected = d),
          ),
        ],
      ],
    );
  }

  Widget _buildEspOptions() {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: FlasherColors.phosphor.withValues(alpha: 0.25)),
        color: FlasherColors.panel.withValues(alpha: 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'FLASH OPTIONS',
              style: GoogleFonts.shareTechMono(
                color: FlasherColors.amber,
                letterSpacing: 2,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            Text('BINARY TYPE', style: _labelStyle()),
            RadioGroup<AddressMode>(
              groupValue: _addressMode,
              onChanged: (v) {
                if (_busy || v == null) return;
                setState(() => _addressMode = v);
              },
              child: Column(
                children: [
                  _radio(AddressMode.fullImage, 'Full image @ 0x0 (recommended)'),
                  _radio(AddressMode.appOnly, 'Application only @ 0x10000'),
                  _radio(AddressMode.custom, 'Custom address'),
                ],
              ),
            ),
            if (_addressMode == AddressMode.custom)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _customOffsetCtrl,
                  enabled: !_busy,
                  style: GoogleFonts.shareTechMono(color: FlasherColors.phosphor),
                  decoration: InputDecoration(
                    hintText: '0x0',
                    hintStyle: GoogleFonts.shareTechMono(color: FlasherColors.dim),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fxA-FX]')),
                  ],
                ),
              ),
            Text('CHIP', style: _labelStyle()),
            DropdownButtonFormField<String>(
              key: ValueKey('chip-$_chip'),
              initialValue: _chip,
              dropdownColor: FlasherColors.panel,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'esp32', child: Text('esp32')),
                DropdownMenuItem(value: 'esp32s3', child: Text('esp32s3')),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v != null) setState(() => _chip = v);
                    },
            ),
            const SizedBox(height: 10),
            Text('BAUD', style: _labelStyle()),
            DropdownButtonFormField<int>(
              key: ValueKey('baud-$_baud'),
              initialValue: _baud,
              dropdownColor: FlasherColors.panel,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final b in _baudOptions)
                  DropdownMenuItem(value: b, child: Text('$b')),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v != null) setState(() => _baud = v);
                    },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _eraseAll,
              activeColor: FlasherColors.phosphor,
              title: Text(
                'Erase entire flash before writing',
                style: GoogleFonts.shareTechMono(fontSize: 12),
              ),
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _eraseAll = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _hardResetAfter,
              activeColor: FlasherColors.phosphor,
              title: Text(
                'Hard reset after successful flash',
                style: GoogleFonts.shareTechMono(fontSize: 12),
              ),
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _hardResetAfter = v ?? true),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.shareTechMono(
        color: FlasherColors.dim,
        fontSize: 11,
        letterSpacing: 1,
      );

  Widget _radio(AddressMode mode, String label) {
    return RadioListTile<AddressMode>(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: mode,
      activeColor: FlasherColors.phosphor,
      title: Text(label, style: GoogleFonts.shareTechMono(fontSize: 12)),
    );
  }

  Widget _buildConsole() {
    final bytesLabel = _total > 0
        ? '${_formatBytes(_written)} / ${_formatBytes(_total)}'
        : '${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlasherColors.panel.withValues(alpha: 0.92),
        border:
            Border.all(color: FlasherColors.phosphor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text(
                  'CONSOLE',
                  style: GoogleFonts.shareTechMono(
                    color: FlasherColors.amber,
                    letterSpacing: 3,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  bytesLabel,
                  style: GoogleFonts.shareTechMono(
                    color: FlasherColors.phosphor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRect(
              child: LinearProgressIndicator(
                value: _busy || _progress > 0 ? _progress : 0,
                minHeight: 4,
                backgroundColor: FlasherColors.grid,
                color: FlasherColors.phosphor,
              ),
            ),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                _status!,
                style: GoogleFonts.shareTechMono(
                  color: _status!.toLowerCase().contains('fail') ||
                          _status!.toLowerCase().startsWith('failed')
                      ? FlasherColors.danger
                      : FlasherColors.amber,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              itemCount: _logs.length,
              itemBuilder: (context, i) {
                return Text(
                  '> ${_logs[i]}',
                  style: GoogleFonts.shareTechMono(
                    color: FlasherColors.phosphor.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int n) {
    if (n < 1024) return '${n}B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)}KB';
    return '${(n / (1024 * 1024)).toStringAsFixed(2)}MB';
  }
}

enum _DownloadModeChoice { auto, manualReady }

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.pulse});
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = 0.35 + pulse.value * 0.45;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PØLYBÎŪS',
              style: GoogleFonts.orbitron(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                color: FlasherColors.phosphor,
                shadows: [
                  Shadow(
                    color: FlasherColors.phosphor.withValues(alpha: glow),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
            Text(
              'FLASHER',
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 10,
                color: FlasherColors.amber,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'R36S SD · CYD · T-Deck · Android OTG ADB — flash boards & install apps.',
              style: GoogleFonts.shareTechMono(
                color: FlasherColors.dim,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF05070A),
            Color(0xFF0A1A12),
            Color(0xFF101008),
            Color(0xFF05070A),
          ],
          stops: [0, 0.35, 0.7, 1],
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FlasherColors.grid
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TargetTile extends StatefulWidget {
  const _TargetTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_TargetTile> createState() => _TargetTileState();
}

class _TargetTileState extends State<_TargetTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.selected
        ? FlasherColors.phosphor
        : FlasherColors.phosphor.withValues(alpha: 0.25);
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: widget.selected
              ? FlasherColors.phosphor.withValues(alpha: 0.08)
              : FlasherColors.panel.withValues(alpha: 0.65),
          border: Border(
            left: BorderSide(color: border, width: widget.selected ? 3 : 1),
            top: BorderSide(color: border.withValues(alpha: 0.5)),
            right: BorderSide(color: border.withValues(alpha: 0.5)),
            bottom: BorderSide(color: border.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.orbitron(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: widget.selected
                    ? FlasherColors.phosphor
                    : FlasherColors.phosphor.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: GoogleFonts.shareTechMono(
                fontSize: 11,
                height: 1.35,
                color: FlasherColors.dim,
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
    required this.selected,
    required this.busy,
    required this.onRefresh,
    required this.onSelect,
    this.emptyHint = 'None found — connect OTG cable to the board.',
  });

  final List<UsbDeviceInfo> devices;
  final UsbDeviceInfo? selected;
  final bool busy;
  final VoidCallback onRefresh;
  final ValueChanged<UsbDeviceInfo> onSelect;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'USB DEVICE',
              style: GoogleFonts.shareTechMono(
                color: FlasherColors.amber,
                letterSpacing: 2,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: busy ? null : onRefresh,
              child: Text(
                'RESCAN',
                style: GoogleFonts.shareTechMono(
                  color: FlasherColors.phosphor,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        if (devices.isEmpty)
          Text(
            emptyHint,
            style: GoogleFonts.shareTechMono(
              color: FlasherColors.dim,
              fontSize: 12,
            ),
          )
        else
          ...devices.map((d) {
            final isSel = selected?.deviceId == d.deviceId ||
                (selected == null && d == devices.first);
            return InkWell(
              onTap: busy ? null : () => onSelect(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isSel
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                      color: FlasherColors.phosphor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.label,
                        style: GoogleFonts.shareTechMono(
                          fontSize: 11,
                          color: FlasherColors.phosphor.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
