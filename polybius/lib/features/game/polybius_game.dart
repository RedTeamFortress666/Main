import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/game/data/level_names.dart';

class PolybiusGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  PolybiusGame({required this.difficulty, this.onGameOver});

  final int difficulty;
  final void Function(int score)? onGameOver;

  late PlayerShip player;
  final _random = Random();
  double _enemySpawnTimer = 0;
  double _glitchTimer = 0;
  String? _glitchText;
  int score = 0;
  int lives = 3;
  int level = 1;
  int killCount = 0;
  bool _gameOver = false;

  @override
  Color backgroundColor() => NeonTheme.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(StarfieldBackground());
    player = PlayerShip();
    add(player);
    add(HudComponent());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver) return;

    _enemySpawnTimer += dt;
    final spawnRate = max(0.4, 2.0 - difficulty * 0.15 - level * 0.1);
    if (_enemySpawnTimer >= spawnRate) {
      _enemySpawnTimer = 0;
      _spawnEnemy();
    }

    _glitchTimer += dt;
    if (_glitchTimer > 4 + _random.nextDouble() * 6) {
      _glitchTimer = 0;
      _glitchText =
          AppConstants.mkUltraPhrases[_random.nextInt(AppConstants.mkUltraPhrases.length)];
      Future.delayed(const Duration(milliseconds: 100), () {
        _glitchText = null;
      });
    }

    if (killCount >= 10 + level * 5) {
      killCount = 0;
      level = min(level + 1, levelNames.length);
      player.upgrade();
    }
  }

  void _spawnEnemy() {
    final x = _random.nextDouble() * (size.x - 40) + 20;
    add(Enemy(position: Vector2(x, -30), speed: 60 + difficulty * 10 + level * 5));
  }

  void addScore(int points) {
    score += points;
    killCount++;
  }

  void playerHit() {
    lives--;
    if (lives <= 0) {
      _gameOver = true;
      onGameOver?.call(score);
    }
  }

  String get levelName =>
      levelNames[min(level - 1, levelNames.length - 1)];

  String? get glitchText => _glitchText;
}

class StarfieldBackground extends Component with HasGameReference<PolybiusGame> {
  final _stars = <_Star>[];
  final _random = Random();

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < 60; i++) {
      _stars.add(_Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 20 + _random.nextDouble() * 80,
        size: 1 + _random.nextDouble() * 2,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    for (final star in _stars) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3 + star.size * 0.2);
      canvas.drawCircle(
        Offset(star.x * game.size.x, star.y * game.size.y),
        star.size,
        paint,
      );
    }
  }

  @override
  void update(double dt) {
    for (final star in _stars) {
      star.y += star.speed * dt / game.size.y;
      if (star.y > 1) {
        star.y = 0;
        star.x = _random.nextDouble();
      }
    }
  }
}

class _Star {
  _Star({required this.x, required this.y, required this.speed, required this.size});
  double x, y, speed, size;
}

class PlayerShip extends PositionComponent
    with HasGameReference<PolybiusGame>, DragCallbacks {
  int mkLevel = 0;
  double _shootCooldown = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2(40, 40);
    position = Vector2(game.size.x / 2, game.size.y - 80);
    anchor = Anchor.center;
  }

  void upgrade() {
    if (mkLevel < shipMkNames.length - 1) mkLevel++;
    size = Vector2(40 + mkLevel * 4, 40 + mkLevel * 4);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.x = (position.x + event.localDelta.x).clamp(20, game.size.x - 20);
    position.y =
        (position.y + event.localDelta.y).clamp(40, game.size.y - 40);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _shootCooldown -= dt;
    if (_shootCooldown <= 0) {
      _shoot();
      _shootCooldown = mkLevel >= 3 ? 0.15 : mkLevel >= 1 ? 0.3 : 0.5;
    }
  }

  void _shoot() {
    game.add(Bullet(
      position: Vector2(position.x, position.y - 20),
      isPlayer: true,
      damage: 1 + mkLevel ~/ 2,
    ));
    if (mkLevel >= 2) {
      game.add(Bullet(
        position: Vector2(position.x - 12, position.y - 15),
        isPlayer: true,
        damage: 1,
      ));
      game.add(Bullet(
        position: Vector2(position.x + 12, position.y - 15),
        isPlayer: true,
        damage: 1,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final colors = [
      NeonTheme.neonCyan,
      NeonTheme.neonGreen,
      NeonTheme.neonYellow,
      NeonTheme.neonOrange,
      NeonTheme.neonPink,
    ];
    final paint = Paint()
      ..color = colors[mkLevel]
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(size.x / 2, size.y * 0.7)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(path, paint);

    paint
      ..color = colors[mkLevel].withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, paint);
  }
}

class Enemy extends PositionComponent with HasGameReference<PolybiusGame> {
  Enemy({required Vector2 position, required this.speed}) {
    this.position = position;
    size = Vector2(30, 30);
    anchor = Anchor.center;
  }

  final double speed;

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > game.size.y + 30) removeFromParent();

    for (final child in game.children.query<Bullet>()) {
      if (!child.isPlayer) continue;
      if ((child.position - position).length < 25) {
        child.removeFromParent();
        game.addScore(100);
        game.add(Explosion(position: position.clone()));
        removeFromParent();
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = NeonTheme.dangerRed;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
    paint.color = NeonTheme.neonOrange;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 8, paint);
  }
}

class Bullet extends PositionComponent with HasGameReference<PolybiusGame> {
  Bullet({
    required Vector2 position,
    required this.isPlayer,
    this.damage = 1,
  }) {
    this.position = position;
    size = Vector2(4, 12);
    anchor = Anchor.center;
  }

  final bool isPlayer;
  final int damage;

  @override
  void update(double dt) {
    super.update(dt);
    position.y += isPlayer ? -400 * dt : 200 * dt;
    if (position.y < -20 || position.y > game.size.y + 20) {
      removeFromParent();
      return;
    }

    if (!isPlayer) {
      final player = game.player;
      if ((position - player.position).length < 20) {
        game.playerHit();
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = isPlayer ? NeonTheme.neonCyan : NeonTheme.dangerRed;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

class Explosion extends PositionComponent {
  Explosion({required Vector2 position}) {
    this.position = position;
    size = Vector2(50, 50);
    anchor = Anchor.center;
  }

  double _life = 0.4;

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final colors = [
      NeonTheme.neonPink,
      NeonTheme.neonCyan,
      NeonTheme.neonYellow,
      NeonTheme.neonGreen,
    ];
    for (var i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i].withValues(alpha: _life * 2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        (1 - _life / 0.4) * 30 + i * 5,
        paint,
      );
    }
  }
}

class HudComponent extends PositionComponent with HasGameReference<PolybiusGame> {
  HudComponent();

  @override
  void render(Canvas canvas) {
    final textStyle = TextStyle(
      fontFamily: 'monospace',
      color: NeonTheme.neonGreen,
      fontSize: 14,
    );

    void drawText(String text, double x, double y) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }

    drawText('SCORE: ${game.score}', 10, 10);
    drawText('LIVES: ${game.lives}', 10, 30);
    drawText(shipMkNames[game.player.mkLevel], 10, 50);
    drawText('LV${game.level}', game.size.x - 50, 10);

    final levelTp = TextPainter(
      text: TextSpan(
        text: game.levelName,
        style: textStyle.copyWith(fontSize: 10, color: NeonTheme.neonPink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    levelTp.paint(canvas, Offset((game.size.x - levelTp.width) / 2, 10));

    if (game.glitchText != null) {
      final glitchTp = TextPainter(
        text: TextSpan(
          text: game.glitchText,
          style: textStyle.copyWith(
            fontSize: 12,
            color: NeonTheme.neonPink.withValues(alpha: 0.4),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      glitchTp.paint(
        canvas,
        Offset(
          (game.size.x - glitchTp.width) / 2,
          game.size.y * 0.4,
        ),
      );
    }
  }
}
