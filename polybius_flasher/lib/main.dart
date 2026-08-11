import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

enum FlashTarget { r36s, cyd, tdeck }

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
  final _logs = <String>[];
  String? _status;
  late final AnimationController _pulse;
  StreamSubscription<String>? _logSub;
  StreamSubscription<double>? _progressSub;

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
        if (_logs.length > 80) _logs.removeAt(0);
      });
    });
    _progressSub = FlasherBridge.instance.progress.listen((p) {
      setState(() => _progress = p.clamp(0.0, 1.0));
    });
    _refreshUsb();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _logSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshUsb() async {
    try {
      final list = await FlasherBridge.instance.listUsbDevices();
      setState(() {
        _devices = list;
        if (_selected != null) {
          _selected = list
              .where((d) => d.deviceId == _selected!.deviceId)
              .firstOrNull;
        }
      });
    } catch (e) {
      _append('USB scan failed: $e');
    }
  }

  void _append(String line) {
    setState(() {
      _logs.add(line);
      if (_logs.length > 80) _logs.removeAt(0);
    });
  }

  Future<void> _run() async {
    final target = _target;
    if (target == null || _busy) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _status = null;
      _logs.clear();
    });
    try {
      switch (target) {
        case FlashTarget.r36s:
          await _runR36s();
        case FlashTarget.cyd:
          await _runEsp(
            asset: 'assets/firmware/polybius-cyd.bin',
            fileName: 'polybius-cyd.bin',
            chip: 'esp32',
          );
        case FlashTarget.tdeck:
          await _runEsp(
            asset: 'assets/firmware/polybius-tdeck.bin',
            fileName: 'polybius-tdeck.bin',
            chip: 'esp32s3',
          );
      }
    } catch (e) {
      setState(() => _status = 'Failed: $e');
      _append('ERROR $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runR36s() async {
    _append('Materializing R36S Port zip…');
    final zip = await FlasherBridge.instance.materializeAsset(
      'assets/r36s/polybius-r36s-port.zip',
      'polybius-r36s-port.zip',
    );
    _append('Pick the SD card roms/ or roms/ports/ folder…');
    final tree = await FlasherBridge.instance.pickSdTree();
    if (tree == null) {
      setState(() => _status = 'Cancelled — no SD folder selected');
      return;
    }
    _append('Writing PortMaster layout…');
    final result = await FlasherBridge.instance.installR36s(
      zipPath: zip,
      treeUri: tree,
    );
    setState(() => _status = result.message);
    _append(result.ok ? 'OK ${result.message}' : 'FAIL ${result.message}');
  }

  Future<void> _runEsp({
    required String asset,
    required String fileName,
    required String chip,
  }) async {
    await _refreshUsb();
    if (_devices.isEmpty) {
      setState(
        () => _status =
            'No USB serial device — use a USB-OTG cable and plug in the board',
      );
      return;
    }
    var device = _selected ?? _devices.first;
    if (!device.hasPermission) {
      _append('Requesting USB permission…');
      final ok =
          await FlasherBridge.instance.requestUsbPermission(device.deviceId);
      if (!ok) {
        setState(() => _status = 'USB permission denied');
        return;
      }
      await _refreshUsb();
      device = _devices
              .where((d) => d.deviceId == device.deviceId)
              .firstOrNull ??
          device;
    }

    _append('Preparing $fileName ($chip)…');
    final path = await FlasherBridge.instance.materializeAsset(asset, fileName);
    _append(
      'If sync fails: hold BOOT, tap RESET, keep BOOT until sync succeeds.',
    );
    final result = await FlasherBridge.instance.flashEsp(
      deviceId: device.deviceId,
      firmwarePath: path,
      chip: chip,
    );
    setState(() => _status = result.message);
    _append(result.ok ? 'OK ${result.message}' : 'FAIL ${result.message}');
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
                      const SizedBox(height: 28),
                      Expanded(
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: SingleChildScrollView(
                                      child: _buildTargets(),
                                    ),
                                  ),
                                  const SizedBox(width: 28),
                                  Expanded(flex: 6, child: _buildConsole()),
                                ],
                              )
                            : ListView(
                                children: [
                                  _buildTargets(),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 360,
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

  Widget _buildTargets() {
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
          subtitle:
              'Install Port zip into SD roms/ports (ArkOS / JELOS / PortMaster)',
          enabled: !_busy,
          onTap: () => setState(() => _target = FlashTarget.r36s),
        ),
        const SizedBox(height: 10),
        _TargetTile(
          selected: _target == FlashTarget.cyd,
          title: 'CYD ESP32-2432S028',
          subtitle: 'USB serial flash · polybius-cyd.bin @ 0x10000 · chip esp32',
          enabled: !_busy,
          onTap: () => setState(() => _target = FlashTarget.cyd),
        ),
        const SizedBox(height: 10),
        _TargetTile(
          selected: _target == FlashTarget.tdeck,
          title: 'LilyGO T-Deck',
          subtitle:
              'USB serial flash · polybius-tdeck.bin @ 0x10000 · chip esp32s3',
          enabled: !_busy,
          onTap: () => setState(() => _target = FlashTarget.tdeck),
        ),
        if (_target == FlashTarget.cyd || _target == FlashTarget.tdeck) ...[
          const SizedBox(height: 16),
          _UsbPicker(
            devices: _devices,
            selected: _selected,
            busy: _busy,
            onRefresh: _refreshUsb,
            onSelect: (d) => setState(() => _selected = d),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: (_target != null && !_busy) ? _run : null,
          style: FilledButton.styleFrom(
            backgroundColor: FlasherColors.phosphor,
            foregroundColor: FlasherColors.voidBlack,
            disabledBackgroundColor: FlasherColors.dim.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const RoundedRectangleBorder(),
          ),
          child: Text(
            _busy ? 'WORKING…' : 'FLASH',
            style: GoogleFonts.shareTechMono(
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              fontSize: 16,
            ),
          ),
        ),
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

  Widget _buildConsole() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FlasherColors.panel.withValues(alpha: 0.92),
        border: Border.all(color: FlasherColors.phosphor.withValues(alpha: 0.35)),
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
                  '${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
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
                minHeight: 3,
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
                  color: _status!.startsWith('FAIL') ||
                          _status!.startsWith('Failed')
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
}

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
                fontSize: 40,
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
            Transform.translate(
              offset: const Offset(2, -4),
              child: Text(
                'FLASHER',
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 10,
                  color: FlasherColors.amber,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Flash firmware to R36S SD · CYD · LilyGO T-Deck from this phone.',
              style: GoogleFonts.shareTechMono(
                color: FlasherColors.dim,
                fontSize: 13,
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
    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          FlasherColors.phosphor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.15),
        radius: size.shortestSide * 0.7,
      ));
    canvas.drawRect(Offset.zero & size, wash);
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
  });

  final List<UsbDeviceInfo> devices;
  final UsbDeviceInfo? selected;
  final bool busy;
  final VoidCallback onRefresh;
  final ValueChanged<UsbDeviceInfo> onSelect;

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
            'None found — connect OTG cable to the board.',
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
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      isSel
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 16,
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
