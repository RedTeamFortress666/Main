import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/game/data/level_names.dart';

/// Neon vector arena shooter (Tempest + Asteroids + Geometry Wars).
///
/// The player is a glowing triangle roaming a black void, auto-firing
/// multi-directional lasers at homing geometric enemies. Everything is drawn
/// as pure vectors with additive-style glow, motion trails, a rotating
/// wireframe tunnel, hyperspace star streaks and matrix rain.
class PolybiusGame extends FlameGame with KeyboardEvents {
  PolybiusGame({required this.difficulty, this.onGameOver});

  final int difficulty;
  final void Function(int score)? onGameOver;

  static const _palette = <Color>[
    NeonTheme.neonCyan,
    NeonTheme.neonPink,
    NeonTheme.neonGreen,
    NeonTheme.neonPurple,
    NeonTheme.neonYellow,
    NeonTheme.dangerRed,
  ];

  final _random = Random();
  late PlayerShip player;

  double _spawnTimer = 0;
  double _glitchTimer = 0;
  String? _glitchText;

  double time = 0;
  double _shake = 0;
  final Vector2 _shakeOffset = Vector2.zero();

  int score = 0;
  int lives = 3;
  int level = 1;
  int killCount = 0;
  int totalKills = 0;
  bool _gameOver = false;

  /// 0..1 hypnotic pulse used to modulate glow across the whole scene.
  double get beat => 0.5 + 0.5 * sin(time * 6);

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(VectorTunnel());
    add(HyperspaceStreaks());
    add(MatrixRain());
    player = PlayerShip();
    add(player);
    add(_InputLayer());
    add(HudComponent());
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(_shakeOffset.x, _shakeOffset.y);
    super.render(canvas);
    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;

    if (_shake > 0) {
      _shake = max(0, _shake - dt * 3);
      final mag = _shake * 14;
      _shakeOffset
        ..x = (_random.nextDouble() * 2 - 1) * mag
        ..y = (_random.nextDouble() * 2 - 1) * mag;
    } else {
      _shakeOffset.setZero();
    }

    if (_gameOver) return;

    _spawnTimer += dt;
    final spawnRate = max(0.28, 1.6 - difficulty * 0.09 - level * 0.06);
    final maxEnemies = 6 + difficulty + level * 2;
    if (_spawnTimer >= spawnRate &&
        children.query<Enemy>().length < maxEnemies) {
      _spawnTimer = 0;
      _spawnEnemy();
    }

    _glitchTimer += dt;
    if (_glitchTimer > 3 + _random.nextDouble() * 5) {
      _glitchTimer = 0;
      _glitchText = AppConstants
          .mkUltraPhrases[_random.nextInt(AppConstants.mkUltraPhrases.length)];
      Future.delayed(const Duration(milliseconds: 140), () {
        _glitchText = null;
      });
    }

    if (killCount >= 8 + level * 4) {
      killCount = 0;
      level = min(level + 1, levelNames.length);
      player.upgrade();
      shake(0.6);
    }
  }

  void _spawnEnemy() {
    final edge = _random.nextInt(4);
    late Vector2 pos;
    switch (edge) {
      case 0:
        pos = Vector2(_random.nextDouble() * size.x, -40);
      case 1:
        pos = Vector2(size.x + 40, _random.nextDouble() * size.y);
      case 2:
        pos = Vector2(_random.nextDouble() * size.x, size.y + 40);
      default:
        pos = Vector2(-40, _random.nextDouble() * size.y);
    }

    // Weight tougher enemy types in at higher levels.
    final roll = _random.nextDouble();
    final EnemyType type;
    if (roll < 0.5) {
      type = EnemyType.saucer;
    } else if (roll < 0.8) {
      type = EnemyType.wanderer;
    } else {
      type = EnemyType.charger;
    }
    add(Enemy(
      position: pos,
      type: type,
      speed: 42 + difficulty * 6 + level * 5,
      color: _palette[_random.nextInt(_palette.length)],
    ));
  }

  void shake(double amount) => _shake = min(1.2, _shake + amount);

  void addScore(int points) {
    score += points;
    killCount++;
    totalKills++;
  }

  /// The hidden ERROR/dev report path is reachable only when the player loses
  /// early — under level 3 or before destroying 6 enemies.
  bool get errorPathEligible => level < 3 || totalKills < 6;

  void spawnExplosion(Vector2 at, Color color, {int lines = 12}) {
    add(Explosion(position: at.clone(), color: color, lines: lines));
    shake(0.25);
  }

  void spawnExplosion(Vector2 at, Color color, {int lines = 12}) {
    add(Explosion(position: at.clone(), color: color, lines: lines));
    shake(0.25);
  }

  void playerHit() {
    if (player.invulnerable || _gameOver) return;
    lives--;
    player.makeInvulnerable();
    spawnExplosion(player.position, NeonTheme.dangerRed, lines: 20);
    shake(0.9);
    if (lives <= 0) {
      _gameOver = true;
      onGameOver?.call(score);
    }
  }

  Enemy? nearestEnemyTo(Vector2 p) {
    Enemy? best;
    var bestDist = double.infinity;
    for (final e in children.query<Enemy>()) {
      final d = (e.position - p).length2;
      if (d < bestDist) {
        bestDist = d;
        best = e;
      }
    }
    return best;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final dir = Vector2.zero();
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      dir.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      dir.x += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      dir.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      dir.y += 1;
    }
    player.keyboardDirection = dir;
    return KeyEventResult.handled;
  }

  String get levelName => levelNames[min(level - 1, levelNames.length - 1)];
  String? get glitchText => _glitchText;
}

/// Draws a cheap neon glow: a wide translucent stroke under a bright thin one.
void _glowPath(Canvas canvas, Path path, Color color, double width,
    {double glow = 3, PaintingStyle style = PaintingStyle.stroke}) {
  if (style == PaintingStyle.fill) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
  }
  canvas.drawPath(
    path,
    Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * glow
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round,
  );
}

Path _polygonPath(int sides, double radius, double rotation) {
  final path = Path();
  for (var i = 0; i <= sides; i++) {
    final a = rotation + i * 2 * pi / sides;
    final p = Offset(cos(a) * radius, sin(a) * radius);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path;
}

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

class _InputLayer extends PositionComponent
    with HasGameReference<PolybiusGame>, DragCallbacks {
  _InputLayer() : super(priority: 1000);

  @override
  Future<void> onLoad() async => size = game.size;

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.player.pointerTarget = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    game.player.pointerTarget = event.localEndPosition.clone();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.player.pointerTarget = null;
  }
}

// ---------------------------------------------------------------------------
// Player
// ---------------------------------------------------------------------------

class PlayerShip extends PositionComponent with HasGameReference<PolybiusGame> {
  int mkLevel = 0;
  double _shootCooldown = 0;
  double _aimAngle = -pi / 2;
  double _invuln = 0;

  Vector2? pointerTarget;
  Vector2 keyboardDirection = Vector2.zero();
  final List<Vector2> _trail = [];

  static const double _speed = 420;

  bool get invulnerable => _invuln > 0;
  void makeInvulnerable() => _invuln = 1.6;

  @override
  Future<void> onLoad() async {
    size = Vector2(34, 34);
    anchor = Anchor.center;
    position = game.size / 2;
  }

  void upgrade() {
    if (mkLevel < shipMkNames.length - 1) mkLevel++;
    size = Vector2(34 + mkLevel * 3, 34 + mkLevel * 3);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_invuln > 0) _invuln -= dt;

    // Movement: pointer-follow takes priority, else keyboard.
    if (pointerTarget != null) {
      final delta = pointerTarget! - position;
      final dist = delta.length;
      if (dist > 1) {
        position += delta.normalized() * min(dist, _speed * dt);
      }
    } else if (keyboardDirection.length2 > 0) {
      position += keyboardDirection.normalized() * _speed * dt;
    }
    position.x = position.x.clamp(16.0, game.size.x - 16);
    position.y = position.y.clamp(16.0, game.size.y - 16);

    // Aim at the nearest enemy for that relentless auto-fire feel.
    final target = game.nearestEnemyTo(position);
    if (target != null) {
      final d = target.position - position;
      if (d.length2 > 0.01) _aimAngle = atan2(d.y, d.x);
    } else if (keyboardDirection.length2 > 0) {
      _aimAngle = atan2(keyboardDirection.y, keyboardDirection.x);
    }

    _shootCooldown -= dt;
    if (_shootCooldown <= 0) {
      _shoot();
      _shootCooldown = [0.24, 0.2, 0.17, 0.13, 0.1][mkLevel];
    }

    _trail.insert(0, position.clone());
    if (_trail.length > 7) _trail.removeLast();
  }

  void _shoot() {
    // Spread widens with each MK upgrade: single -> radial barrage.
    final spread = [1, 2, 3, 5, 8][mkLevel];
    final damage = 1 + mkLevel ~/ 2;
    if (spread == 1) {
      _fire(_aimAngle, damage);
      return;
    }
    if (mkLevel >= 4) {
      for (var i = 0; i < 8; i++) {
        _fire(_aimAngle + i * pi / 4, damage);
      }
      return;
    }
    const arc = 0.5;
    for (var i = 0; i < spread; i++) {
      final t = spread == 1 ? 0.0 : (i / (spread - 1)) - 0.5;
      _fire(_aimAngle + t * arc, damage);
    }
  }

  void _fire(double angle, int damage) {
    final dir = Vector2(cos(angle), sin(angle));
    game.add(Bullet(
      position: position + dir * 18,
      velocity: dir * 760,
      damage: damage,
      color: PolybiusGame._palette[mkLevel % PolybiusGame._palette.length],
    ));
  }

  @override
  void render(Canvas canvas) {
    // Motion afterimage trail.
    for (var i = _trail.length - 1; i >= 1; i--) {
      final a = (1 - i / _trail.length) * 0.25;
      final local = _trail[i] - position + (size / 2);
      canvas.drawCircle(
        Offset(local.x, local.y),
        3.0 * (1 - i / _trail.length),
        Paint()..color = NeonTheme.neonCyan.withValues(alpha: a),
      );
    }

    if (invulnerable && (game.time * 20).floor().isEven) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_aimAngle + pi / 2);

    final r = size.x / 2;
    Path ship() => Path()
      ..moveTo(0, -r)
      ..lineTo(r * 0.8, r * 0.8)
      ..lineTo(0, r * 0.4)
      ..lineTo(-r * 0.8, r * 0.8)
      ..close();

    // Pseudo chromatic aberration: offset magenta/cyan ghosts.
    canvas.drawPath(
      ship().shift(const Offset(-1.5, 0)),
      Paint()
        ..color = NeonTheme.neonPink.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawPath(
      ship().shift(const Offset(1.5, 0)),
      Paint()
        ..color = NeonTheme.neonCyan.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _glowPath(canvas, ship(), Colors.white, 2,
        glow: 4 + game.beat * 2, style: PaintingStyle.fill);
    canvas.restore();
  }
}

// ---------------------------------------------------------------------------
// Bullets
// ---------------------------------------------------------------------------

class Bullet extends PositionComponent with HasGameReference<PolybiusGame> {
  Bullet({
    required Vector2 position,
    required this.velocity,
    required this.color,
    this.damage = 1,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(6);
  }

  Vector2 velocity;
  final Color color;
  final int damage;
  final List<Vector2> _trail = [];

  @override
  void update(double dt) {
    super.update(dt);
    _trail.insert(0, position.clone());
    if (_trail.length > 6) _trail.removeLast();
    position += velocity * dt;

    if (position.x < -30 ||
        position.x > game.size.x + 30 ||
        position.y < -30 ||
        position.y > game.size.y + 30) {
      removeFromParent();
      return;
    }

    for (final enemy in game.children.query<Enemy>()) {
      if ((enemy.position - position).length < enemy.radius) {
        enemy.damageBy(damage);
        removeFromParent();
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw the streaking trail in world space relative to the component.
    final path = Path()..moveTo(size.x / 2, size.y / 2);
    for (final p in _trail) {
      final local = p - position + (size / 2);
      path.lineTo(local.x, local.y);
    }
    _glowPath(canvas, path, color, 2.5, glow: 3);
  }
}

// ---------------------------------------------------------------------------
// Enemies
// ---------------------------------------------------------------------------

enum EnemyType { saucer, wanderer, charger }

class Enemy extends PositionComponent with HasGameReference<PolybiusGame> {
  Enemy({
    required Vector2 position,
    required this.type,
    required this.speed,
    required this.color,
  }) {
    this.position = position;
    anchor = Anchor.center;
    switch (type) {
      case EnemyType.saucer:
        radius = 18;
        _hp = 2;
      case EnemyType.wanderer:
        radius = 16;
        _hp = 1;
      case EnemyType.charger:
        radius = 22;
        _hp = 4;
    }
    size = Vector2.all(radius * 2);
  }

  final EnemyType type;
  final double speed;
  final Color color;

  late double radius;
  late int _hp;
  double _spin = 0;
  double _chargeTimer = 0;
  double _hitFlash = 0;
  final Vector2 _velocity = Vector2.zero();
  final _random = Random();

  void damageBy(int amount) {
    _hp -= amount;
    _hitFlash = 0.12;
    if (_hp <= 0) {
      final points = {
        EnemyType.saucer: 100,
        EnemyType.wanderer: 75,
        EnemyType.charger: 250,
      }[type]!;
      game.addScore(points);
      game.spawnExplosion(position, color, lines: type == EnemyType.charger ? 20 : 12);
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _spin += dt * (type == EnemyType.charger ? 3 : 1.6);
    if (_hitFlash > 0) _hitFlash -= dt;

    final toPlayer = game.player.position - position;
    switch (type) {
      case EnemyType.saucer:
        _velocity.setFrom(toPlayer.normalized() * speed);
      case EnemyType.wanderer:
        // Drift with wandering steering, mild pull toward the player.
        _velocity
          ..x += (_random.nextDouble() * 2 - 1) * speed * dt * 4
          ..y += (_random.nextDouble() * 2 - 1) * speed * dt * 4;
        _velocity.add(toPlayer.normalized() * speed * dt * 1.5);
        if (_velocity.length > speed) {
          _velocity.length = speed;
        }
      case EnemyType.charger:
        _chargeTimer += dt;
        if (_chargeTimer > 2.2) {
          _velocity.setFrom(toPlayer.normalized() * speed * 4);
          if (_chargeTimer > 2.6) _chargeTimer = 0;
        } else {
          _velocity.setFrom(toPlayer.normalized() * speed * 0.6);
        }
    }

    position += _velocity * dt;

    // Keep wanderers inside the arena.
    if (type == EnemyType.wanderer) {
      if (position.x < radius || position.x > game.size.x - radius) {
        _velocity.x = -_velocity.x;
      }
      if (position.y < radius || position.y > game.size.y - radius) {
        _velocity.y = -_velocity.y;
      }
      position.x = position.x.clamp(radius, game.size.x - radius);
      position.y = position.y.clamp(radius, game.size.y - radius);
    }

    if ((game.player.position - position).length < radius + 14) {
      game.playerHit();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    final c = _hitFlash > 0 ? Colors.white : color;
    final pulse = 1 + game.beat * 0.08;

    switch (type) {
      case EnemyType.saucer:
        canvas.rotate(_spin);
        _glowPath(canvas, _polygonPath(6, radius * pulse, 0), c, 2.2);
        _glowPath(canvas, _polygonPath(3, radius * 0.5, -_spin * 2), c, 1.6);
      case EnemyType.wanderer:
        // Tentacled core: small polygon with wavy radiating limbs.
        _glowPath(canvas, _polygonPath(4, radius * 0.5, _spin), c, 2);
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3 + _spin;
          final wob = sin(game.time * 6 + i) * 4;
          final path = Path()
            ..moveTo(cos(a) * radius * 0.5, sin(a) * radius * 0.5)
            ..lineTo(
              cos(a) * radius + cos(a + 1.4) * wob,
              sin(a) * radius + sin(a + 1.4) * wob,
            );
          _glowPath(canvas, path, c, 1.6, glow: 2.5);
        }
      case EnemyType.charger:
        canvas.rotate(_spin);
        final charging = _chargeTimer > 2.2;
        final spike = charging ? NeonTheme.dangerRed : c;
        final path = Path();
        for (var i = 0; i <= 16; i++) {
          final rr = i.isEven ? radius : radius * 0.5;
          final a = i * pi / 8;
          final p = Offset(cos(a) * rr, sin(a) * rr);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        _glowPath(canvas, path, spike, charging ? 3 : 2);
    }
    canvas.restore();
  }
}

// ---------------------------------------------------------------------------
// Explosions -> vector-line debris
// ---------------------------------------------------------------------------

class Explosion extends PositionComponent {
  Explosion({required Vector2 position, required this.color, this.lines = 12}) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.zero();
  }

  final Color color;
  final int lines;
  final _random = Random();
  final List<_Debris> _debris = [];

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < lines; i++) {
      final a = _random.nextDouble() * 2 * pi;
      final speed = 120 + _random.nextDouble() * 220;
      _debris.add(_Debris(
        velocity: Vector2(cos(a), sin(a)) * speed,
        length: 8 + _random.nextDouble() * 16,
        angle: a,
        life: 0.4 + _random.nextDouble() * 0.4,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    var alive = false;
    for (final d in _debris) {
      d.life -= dt;
      if (d.life <= 0) continue;
      alive = true;
      d.pos.add(d.velocity * dt);
      d.velocity *= 0.94;
    }
    if (!alive) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final d in _debris) {
      if (d.life <= 0) continue;
      final a = (d.life / d.maxLife).clamp(0.0, 1.0);
      final end = d.pos + Vector2(cos(d.angle), sin(d.angle)) * d.length * a;
      final path = Path()
        ..moveTo(d.pos.x, d.pos.y)
        ..lineTo(end.x, end.y);
      _glowPath(canvas, path, color.withValues(alpha: a), 2, glow: 2.5);
    }
  }
}

class _Debris {
  _Debris({
    required this.velocity,
    required this.length,
    required this.angle,
    required this.life,
  }) : maxLife = life;

  final Vector2 pos = Vector2.zero();
  Vector2 velocity;
  final double length;
  final double angle;
  double life;
  final double maxLife;
}

// ---------------------------------------------------------------------------
// Backgrounds
// ---------------------------------------------------------------------------

class VectorTunnel extends Component with HasGameReference<PolybiusGame> {
  VectorTunnel() : super(priority: -30);

  static const _rings = 11;
  static const _sides = 6;

  @override
  void render(Canvas canvas) {
    final center = game.size / 2;
    final maxR = game.size.length / 2;
    final phase = (game.time * 0.35) % 1.0;
    canvas.save();
    canvas.translate(center.x, center.y);
    for (var i = 0; i < _rings; i++) {
      final t = ((i / _rings) + phase) % 1.0;
      final radius = t * maxR;
      if (radius < 8) continue;
      final color = PolybiusGame._palette[i % PolybiusGame._palette.length];
      final alpha = (1 - t) * 0.35 * (0.6 + game.beat * 0.4);
      canvas.drawPath(
        _polygonPath(_sides, radius, game.time * 0.4 + i),
        Paint()
          ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    canvas.restore();
  }
}

class HyperspaceStreaks extends Component with HasGameReference<PolybiusGame> {
  HyperspaceStreaks() : super(priority: -20);

  final _random = Random();
  final List<_Streak> _streaks = [];

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < 70; i++) {
      _streaks.add(_spawn(initial: true));
    }
  }

  _Streak _spawn({bool initial = false}) {
    final angle = _random.nextDouble() * 2 * pi;
    final dist = initial ? _random.nextDouble() * 0.5 : 0.02;
    return _Streak(
      angle: angle,
      dist: dist,
      speed: 0.25 + _random.nextDouble() * 0.6,
    );
  }

  @override
  void update(double dt) {
    for (var i = 0; i < _streaks.length; i++) {
      final s = _streaks[i];
      s.dist += s.speed * dt;
      if (s.dist > 0.75) _streaks[i] = _spawn();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = game.size / 2;
    final maxR = game.size.length / 2;
    for (final s in _streaks) {
      final dir = Offset(cos(s.angle), sin(s.angle));
      final r1 = s.dist * maxR;
      final r2 = max(0.0, s.dist - 0.05 - s.speed * 0.04) * maxR;
      final p1 = Offset(center.x + dir.dx * r1, center.y + dir.dy * r1);
      final p2 = Offset(center.x + dir.dx * r2, center.y + dir.dy * r2);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.white.withValues(alpha: (s.dist * 0.9).clamp(0.0, 0.9))
          ..strokeWidth = 1 + s.dist * 1.5,
      );
    }
  }
}

class _Streak {
  _Streak({required this.angle, required this.dist, required this.speed});
  final double angle;
  double dist;
  final double speed;
}

class MatrixRain extends Component with HasGameReference<PolybiusGame> {
  MatrixRain() : super(priority: -10);

  static const _glyphs = 'アカサタナ01PØLYBIUS◈▲△▓';
  final _random = Random();
  final List<_RainColumn> _columns = [];

  void _rebuild() {
    _columns.clear();
    final count = (game.size.x / 26).floor().clamp(6, 22);
    for (var i = 0; i < count; i++) {
      _columns.add(_RainColumn(
        x: (i + 0.5) * game.size.x / count,
        y: _random.nextDouble() * game.size.y,
        speed: 60 + _random.nextDouble() * 140,
        glyph: _glyphs[_random.nextInt(_glyphs.length)],
      ));
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _rebuild();
  }

  @override
  void update(double dt) {
    if (_columns.isEmpty) _rebuild();
    for (final c in _columns) {
      c.y += c.speed * dt;
      if (c.y > game.size.y + 40) {
        c.y = -20;
        c.glyph = _glyphs[_random.nextInt(_glyphs.length)];
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final c in _columns) {
      for (var t = 0; t < 5; t++) {
        final y = c.y - t * 22;
        if (y < -20 || y > game.size.y + 20) continue;
        final tp = TextPainter(
          text: TextSpan(
            text: c.glyph,
            style: TextStyle(
              color: NeonTheme.neonGreen
                  .withValues(alpha: (0.18 - t * 0.035).clamp(0.0, 0.18)),
              fontSize: 16,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(c.x, y));
      }
    }
  }
}

class _RainColumn {
  _RainColumn({
    required this.x,
    required this.y,
    required this.speed,
    required this.glyph,
  });
  final double x;
  double y;
  final double speed;
  String glyph;
}

// ---------------------------------------------------------------------------
// HUD
// ---------------------------------------------------------------------------

class HudComponent extends PositionComponent with HasGameReference<PolybiusGame> {
  HudComponent() : super(priority: 900);

  @override
  void render(Canvas canvas) {
    final style = const TextStyle(
      fontFamily: 'monospace',
      color: NeonTheme.neonGreen,
      fontSize: 14,
    );

    void draw(String text, Offset at, TextStyle s) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: s),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at);
    }

    draw('SCORE ${game.score}', const Offset(12, 12), style);
    draw('LIVES ${game.lives}', const Offset(12, 30), style);
    draw(shipMkNames[game.player.mkLevel], const Offset(12, 48),
        style.copyWith(color: NeonTheme.neonCyan));
    draw('LV${game.level}', Offset(game.size.x - 54, 12),
        style.copyWith(color: NeonTheme.neonYellow));

    final levelTp = TextPainter(
      text: TextSpan(
        text: game.levelName,
        style: style.copyWith(fontSize: 10, color: NeonTheme.neonPink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    levelTp.paint(canvas, Offset((game.size.x - levelTp.width) / 2, 12));

    draw('DRAG TO MOVE • AUTO-FIRE',
        Offset(12, game.size.y - 26),
        style.copyWith(fontSize: 10, color: Colors.white24));

    if (game.glitchText != null) {
      final gtp = TextPainter(
        text: TextSpan(
          text: game.glitchText,
          style: style.copyWith(
            fontSize: 13,
            color: NeonTheme.neonPink.withValues(alpha: 0.45),
            letterSpacing: 3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      gtp.paint(
        canvas,
        Offset((game.size.x - gtp.width) / 2, game.size.y * 0.38),
      );
    }
  }
}
