import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/providers/intro_provider.dart';
import 'package:polybius/core/routing/router_refresh.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Cinematic boot: logo → matrix + third eye → GAME OVER typewriter →
/// CRT power-off → loading → start screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

enum _Phase {
  logo,
  matrixEye,
  blackBeat,
  gameOverType,
  tvOff,
  loading,
  done,
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  _Phase _phase = _Phase.logo;
  String _typed = '';
  static const _line = 'brought to you by GÅMÊ ØVĒR...';
  double _tvScale = 1;
  double _tvOpacity = 1;
  int _eyeBlink = 0;
  bool _showQuestion = false;
  bool _navigated = false;
  Timer? _loadingTimer;
  Timer? _failsafeTimer;
  late final AnimationController _matrixCtrl;
  late final AnimationController _eyePulse;
  final _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _matrixCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _eyePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    // Absolute failsafe — never strand on splash past ~10s.
    _failsafeTimer = Timer(const Duration(seconds: 10), () {
      _finishIntroAndGo();
    });
    _runSequence();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _failsafeTimer?.cancel();
    _matrixCtrl.dispose();
    _eyePulse.dispose();
    super.dispose();
  }

  String _destinationFor(AuthState auth) {
    if (!AppFlavor.requiresStartupLogin) {
      return AppFlavor.postSplashRoute;
    }
    if (!auth.isRestoring &&
        auth.isAuthenticated &&
        auth.needsPin &&
        auth.user != null) {
      return '/pin';
    }
    if (!auth.isRestoring && auth.isAuthenticated) {
      return '/menu';
    }
    return '/login';
  }

  /// Leave splash immediately — never wait on auth restore.
  void _finishIntroAndGo() {
    if (_navigated) return;
    _navigated = true;
    _loadingTimer?.cancel();
    _failsafeTimer?.cancel();

    // Flip the intro gate so GoRouter redirect will allow leaving `/`.
    try {
      ref.read(introCompleteProvider.notifier).state = true;
      // Belt-and-suspenders: poke refresh even if listen missed a frame.
      ref.read(routerRefreshProvider).ping();
    } catch (_) {}

    void goNow() {
      if (!mounted) return;
      try {
        final target = _destinationFor(ref.read(authProvider));
        GoRouter.of(context).go(target);
      } catch (_) {
        try {
          context.go(AppFlavor.requiresStartupLogin ? '/login' : '/game');
        } catch (_) {}
      }
    }

    // Navigate immediately and again next frame (covers mid-build cases).
    goNow();
    WidgetsBinding.instance.addPostFrameCallback((_) => goNow());
  }

  Future<void> _runSequence() async {
    // 1) Logo
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted || _navigated) return;
    setState(() => _phase = _Phase.matrixEye);

    // 2) Matrix + eye blinks
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || _navigated) return;
      setState(() {
        _eyeBlink = i + 1;
        _showQuestion = true;
      });
      unawaited(_eyePulse.forward(from: 0));
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted || _navigated) return;
      setState(() => _showQuestion = false);
      await Future<void>.delayed(const Duration(milliseconds: 320));
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || _navigated) return;

    // 3) Black beat
    setState(() => _phase = _Phase.blackBeat);
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted || _navigated) return;

    // 4) Typewriter
    setState(() {
      _phase = _Phase.gameOverType;
      _typed = '';
    });
    for (var i = 0; i < _line.length; i++) {
      await Future<void>.delayed(Duration(milliseconds: 28 + _rng.nextInt(18)));
      if (!mounted || _navigated) return;
      setState(() => _typed = _line.substring(0, i + 1));
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || _navigated) return;

    // 5) Glitch + TV off
    setState(() => _phase = _Phase.tvOff);
    const steps = 14;
    for (var i = 0; i <= steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 22));
      if (!mounted || _navigated) return;
      final t = i / steps;
      setState(() {
        _tvScale = 1.0 - (0.92 * Curves.easeIn.transform(t));
        _tvOpacity = 1.0 - (0.15 * t);
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted || _navigated) return;
    setState(() {
      _tvScale = 0.02;
      _tvOpacity = 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted || _navigated) return;
    setState(() => _tvOpacity = 0);

    // 6) Loading — own Timer so we leave even if an await above races.
    if (!mounted || _navigated) return;
    setState(() => _phase = _Phase.loading);
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _navigated) return;
      setState(() => _phase = _Phase.done);
      _finishIntroAndGo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: switch (_phase) {
          _Phase.logo => _LogoPhase(key: const ValueKey('logo')),
          _Phase.matrixEye => _MatrixEyePhase(
              key: const ValueKey('matrix'),
              controller: _matrixCtrl,
              pulse: _eyePulse,
              showQuestion: _showQuestion,
              blinkIndex: _eyeBlink,
            ),
          _Phase.blackBeat => const SizedBox.expand(key: ValueKey('black')),
          _Phase.gameOverType => _TypePhase(
              key: const ValueKey('type'),
              text: _typed,
            ),
          _Phase.tvOff => _TvOffPhase(
              key: const ValueKey('tv'),
              scale: _tvScale,
              opacity: _tvOpacity,
              text: _typed,
            ),
          _Phase.loading => const _LoadingPhase(key: ValueKey('loading')),
          // Black frame while go_router swaps — never re-show loading.
          _Phase.done => const SizedBox.expand(key: ValueKey('done')),
        },
      ),
    );
  }
}

class _LogoPhase extends StatelessWidget {
  const _LogoPhase({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: NeonTheme.neonPink,
              shadows: [
                Shadow(color: NeonTheme.neonPink.withValues(alpha: 0.8), blurRadius: 18),
                Shadow(color: NeonTheme.neonCyan.withValues(alpha: 0.5), blurRadius: 28),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ARCADE TERMINAL',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              letterSpacing: 4,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixEyePhase extends StatelessWidget {
  const _MatrixEyePhase({
    super.key,
    required this.controller,
    required this.pulse,
    required this.showQuestion,
    required this.blinkIndex,
  });

  final AnimationController controller;
  final AnimationController pulse;
  final bool showQuestion;
  final int blinkIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, pulse]),
      builder: (context, _) {
        return CustomPaint(
          painter: _MatrixEyePainter(
            t: controller.value,
            pulse: pulse.value,
            showQuestion: showQuestion,
            blinkIndex: blinkIndex,
            rng: Random(blinkIndex + 7),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _MatrixEyePainter extends CustomPainter {
  _MatrixEyePainter({
    required this.t,
    required this.pulse,
    required this.showQuestion,
    required this.blinkIndex,
    required this.rng,
  });

  final double t;
  final double pulse;
  final bool showQuestion;
  final int blinkIndex;
  final Random rng;

  static const _palette = [
    Color(0xFF39FF14),
    Color(0xFF00F0FF),
    Color(0xFFFF2D95),
    Color(0xFFFFF200),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    final cols = (size.width / 14).floor().clamp(8, 40);
    final rows = (size.height / 16).floor().clamp(12, 60);
    final glyphs = '01アイウエオカキクケコサシスセソタチツテト01PØLYBĪUS';

    for (var c = 0; c < cols; c++) {
      final speed = 0.35 + (c % 5) * 0.12;
      final head = ((t * speed * rows) + c * 3) % (rows + 8);
      for (var r = 0; r < rows; r++) {
        final dist = (head - r);
        if (dist < 0 || dist > 12) continue;
        final ch = glyphs[(c * 13 + r + (t * 40).floor()) % glyphs.length];
        final color = _palette[(c + r) % _palette.length]
            .withValues(alpha: (1.0 - dist / 12).clamp(0.15, 0.95));
        final tp = TextPainter(
          text: TextSpan(
            text: ch,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(c * 14.0, r * 16.0));
      }
    }

    // Illuminati third eye (triangle + eye)
    final cx = size.width / 2;
    final cy = size.height / 2;
    final flash = 0.55 + 0.45 * sin(t * pi * 6);
    final blinkClose = showQuestion ? (0.15 + 0.85 * (1 - pulse)) : 1.0;

    final tri = Path()
      ..moveTo(cx, cy - 90)
      ..lineTo(cx - 78, cy + 55)
      ..lineTo(cx + 78, cy + 55)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF39FF14).withValues(alpha: flash),
    );
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black.withValues(alpha: 0.55),
    );

    // Eye white / iris
    final eyeR = 28.0 * blinkClose;
    if (eyeR > 2) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 8), width: 70, height: eyeR * 1.4),
        Paint()..color = const Color(0xFF39FF14).withValues(alpha: 0.25 + 0.2 * flash),
      );
      canvas.drawCircle(
        Offset(cx, cy - 8),
        16 * blinkClose,
        Paint()..color = const Color(0xFFFF2D95).withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        Offset(cx, cy - 8),
        8 * blinkClose,
        Paint()..color = const Color(0xFFFFF200),
      );
      // Pupil
      canvas.drawCircle(
        Offset(cx, cy - 8),
        5 * blinkClose,
        Paint()..color = Colors.black,
      );
      if (showQuestion && blinkClose > 0.4) {
        final q = TextPainter(
          text: const TextSpan(
            text: '?',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF39FF14),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        q.paint(canvas, Offset(cx - q.width / 2, cy - 8 - q.height / 2));
      }
    }

    // Accent rays
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3 + t * pi;
      final p = Paint()
        ..color = _palette[i % _palette.length].withValues(alpha: 0.35 * flash)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(cx + cos(a) * 40, cy - 8 + sin(a) * 40),
        Offset(cx + cos(a) * 110, cy - 8 + sin(a) * 110),
        p,
      );
    }

    // consume unused to keep analyzer quiet if tree shaken oddly
    rng.nextBool();
  }

  @override
  bool shouldRepaint(covariant _MatrixEyePainter old) =>
      old.t != t ||
      old.pulse != pulse ||
      old.showQuestion != showQuestion ||
      old.blinkIndex != blinkIndex;
}

class _TypePhase extends StatelessWidget {
  const _TypePhase({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              letterSpacing: 1.2,
              height: 1.5,
              color: NeonTheme.neonPink.withValues(alpha: 0.95),
              shadows: [
                Shadow(
                  color: NeonTheme.neonCyan.withValues(alpha: 0.55),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TvOffPhase extends StatelessWidget {
  const _TvOffPhase({
    super.key,
    required this.scale,
    required this.opacity,
    required this.text,
  });

  final double scale;
  final double opacity;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scaleY: scale.clamp(0.02, 1.0),
          scaleX: (0.15 + 0.85 * scale).clamp(0.02, 1.0),
          child: Center(
            child: scale < 0.08
                ? Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                : Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPhase extends StatelessWidget {
  const _LoadingPhase({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'loading...',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            letterSpacing: 3,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}
