import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(SafeArea(child: GameWidget<SpaceShooterGame>(game: SpaceShooterGame())));
}

class SpaceShooterGame extends FlameGame<World> with PanDetector, HasCollisionDetection<Broadphase<ShapeHitbox>> {
  late Player player;

  @override
  Future<void> onLoad() async {
    final ParallaxComponent<FlameGame<World>> parallax = await loadParallaxComponent(
      <ParallaxData>[ParallaxImageData('stars_0.png'), ParallaxImageData('stars_1.png'), ParallaxImageData('stars_2.png')],
      baseVelocity: Vector2(0, -5),
      repeat: ImageRepeat.repeat,
      velocityMultiplierDelta: Vector2(0, 5),
    );
    add(parallax);
    player = Player();
    add(player);
    add(SpawnComponent(factory: (int index) => Enemy(), period: 1, area: Rectangle.fromLTWH(0, 0, size.x, -Enemy.enemySize)));
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    player.move(info.delta.global);
  }

  @override
  void onPanStart(DragStartInfo info) {
    player.startShooting();
  }

  @override
  void onPanEnd(DragEndInfo info) {
    player.stopShooting();
  }
}

class Player extends SpriteAnimationComponent with HasGameReference<SpaceShooterGame> {
  late final SpawnComponent _bulletSpawner;

  Player() : super(size: Vector2(100, 150), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await game.loadSpriteAnimation('player.png', SpriteAnimationData.sequenced(amount: 4, stepTime: .2, textureSize: Vector2(32, 48)));
    position = game.size / 2;
    _bulletSpawner = SpawnComponent(
      period: .2,
      selfPositioning: true,
      factory: (int index) {
        return Bullet(position: position + Vector2(0, -height / 2));
      },
      autoStart: false,
    );
    game.add(_bulletSpawner);
  }

  void move(Vector2 delta) {
    position.add(delta);
  }

  void startShooting() {
    _bulletSpawner.timer.start();
  }

  void stopShooting() {
    _bulletSpawner.timer.stop();
  }
}

class Bullet extends SpriteAnimationComponent with HasGameReference<SpaceShooterGame> {
  Bullet({super.position}) : super(size: Vector2(25, 50), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await game.loadSpriteAnimation('bullet.png', SpriteAnimationData.sequenced(amount: 4, stepTime: .2, textureSize: Vector2(8, 16)));
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += dt * -500;
    if (position.y < -height) {
      removeFromParent();
    }
  }
}

class Enemy extends SpriteAnimationComponent with HasGameReference<SpaceShooterGame>, CollisionCallbacks {
  static const double enemySize = 50.0;

  Enemy({super.position}) : super(size: Vector2.all(enemySize), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await game.loadSpriteAnimation('enemy.png', SpriteAnimationData.sequenced(amount: 4, stepTime: .2, textureSize: Vector2.all(16)));
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += dt * 250;
    if (position.y > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Bullet) {
      removeFromParent();
      other.removeFromParent();
      game.add(Explosion(position: position));
    }
  }
}

class Explosion extends SpriteAnimationComponent with HasGameReference<SpaceShooterGame> {
  Explosion({super.position}) : super(size: Vector2.all(150), anchor: Anchor.center, removeOnFinish: true);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await game.loadSpriteAnimation('explosion.png', SpriteAnimationData.sequenced(amount: 6, stepTime: .1, textureSize: Vector2.all(32), loop: false));
  }
}
