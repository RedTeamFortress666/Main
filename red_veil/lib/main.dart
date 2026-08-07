import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Local status endpoint while the filter is active (for optional tooling).
const int kFilterStatusPort = 18766;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DarthCherryApp());
}

class DarthCherryApp extends StatelessWidget {
  const DarthCherryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DARTH CHERRY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2A2A),
          secondary: Color(0xFF8B0000),
          surface: Color(0xFF1A0505),
        ),
        fontFamily: 'monospace',
      ),
      home: const FilterControlScreen(),
    );
  }
}

class FilterControlScreen extends StatefulWidget {
  const FilterControlScreen({super.key});

  @override
  State<FilterControlScreen> createState() => _FilterControlScreenState();
}

class _FilterControlScreenState extends State<FilterControlScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.polybius.red_veil/overlay');

  double _intensity = 0.55;
  bool _active = false;
  bool _busy = false;
  String? _status;
  HttpServer? _statusServer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_deactivate());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_active &&
        _statusServer == null &&
        state == AppLifecycleState.resumed) {
      unawaited(_startStatusServer());
    }
  }

  Future<void> _startStatusServer() async {
    if (kIsWeb) return;
    if (_statusServer != null) return;
    try {
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        kFilterStatusPort,
      );
      _statusServer = server;
      server.listen((req) async {
        try {
          if (req.uri.path == '/veil' ||
              req.uri.path == '/status' ||
              req.uri.path == '/') {
            final body = jsonEncode({
              'active': true,
              'tint': 'red',
              'intensity': _intensity,
              'app': 'darth_cherry',
            });
            req.response.headers.contentType = ContentType.json;
            req.response.write(body);
          } else {
            req.response.statusCode = HttpStatus.notFound;
          }
        } finally {
          await req.response.close();
        }
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Status port unavailable');
    }
  }

  Future<void> _stopStatusServer() async {
    await _statusServer?.close(force: true);
    _statusServer = null;
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_active) {
        await _deactivate();
      } else {
        await _activate();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _activate() async {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    if (isAndroid) {
      try {
        final permitted =
            await _channel.invokeMethod<bool>('checkOverlayPermission') ??
                false;
        if (!permitted) {
          await _channel.invokeMethod('requestOverlayPermission');
          setState(() => _status =
              'Grant "Display over other apps", return here, tap ENABLE again.');
          return;
        }
        await _channel.invokeMethod('showOverlay', {'intensity': _intensity});
      } on PlatformException catch (e) {
        setState(() => _status = 'Overlay: ${e.message}');
        return;
      }
    }

    await _startStatusServer();
    if (!mounted) return;
    setState(() {
      _active = true;
      _status = isAndroid
          ? 'FILTER ON — cherry red veil over your screen.'
          : 'FILTER ON (preview). On Android this overlays other apps.';
    });

    if (!isAndroid && mounted) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, _, _) => FilterPreviewStage(
            intensity: _intensity,
            onIntensity: (v) => setState(() => _intensity = v),
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      );
      await _deactivate();
    }
  }

  Future<void> _deactivate() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('hideOverlay');
      } catch (_) {}
    }
    await _stopStatusServer();
    if (mounted) {
      setState(() {
        _active = false;
        _status = 'FILTER OFF';
      });
    } else {
      _active = false;
    }
  }

  Future<void> _updateIntensity(double v) async {
    setState(() => _intensity = v);
    if (_active && !kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('updateOverlay', {'intensity': v});
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Image.asset(
                  'assets/icons/darth_cherry.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.brightness_2,
                    size: 72,
                    color: Color(0xFFFF2A2A),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'DARTH CHERRY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  letterSpacing: 4,
                  color: Color(0xFFFF2A2A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'night red-light filter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFAA4444),
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'A cherry-red screen veil for late hours — easier on night vision, '
                'warmer on the eyes. Enable the filter to dim and tint your display; '
                'on Android it floats over other apps without blocking touch.',
                style: TextStyle(color: Color(0xFFCC8888), height: 1.5),
              ),
              const SizedBox(height: 28),
              Text(
                'INTENSITY  ${(_intensity * 100).round()}%',
                style: const TextStyle(color: Color(0xFFFF6666), fontSize: 12),
              ),
              Slider(
                value: _intensity,
                min: 0.15,
                max: 0.85,
                activeColor: const Color(0xFFFF2A2A),
                inactiveColor: const Color(0xFF4A1010),
                onChanged: _updateIntensity,
              ),
              const Spacer(),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _status!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFAA88),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _busy ? null : _toggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _active
                      ? const Color(0xFF4A1010)
                      : const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  _active ? 'DISABLE FILTER' : 'ENABLE FILTER',
                  style: const TextStyle(letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterPreviewStage extends StatelessWidget {
  const FilterPreviewStage({
    super.key,
    required this.intensity,
    required this.onIntensity,
    required this.onClose,
  });

  final double intensity;
  final ValueChanged<double> onIntensity;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: ColoredBox(
              color: Color.fromRGBO(180, 0, 0, intensity),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xEE1A0505),
                  border: Border.all(color: const Color(0xFF8B0000)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'DARTH CHERRY',
                      style: TextStyle(
                        color: Color(0xFFFF6666),
                        letterSpacing: 3,
                        fontSize: 11,
                      ),
                    ),
                    Slider(
                      value: intensity,
                      min: 0.15,
                      max: 0.85,
                      activeColor: const Color(0xFFFF2A2A),
                      onChanged: onIntensity,
                    ),
                    TextButton(
                      onPressed: onClose,
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(color: Color(0xFFFFAAAA)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
