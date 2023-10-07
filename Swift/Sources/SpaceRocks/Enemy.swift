import SGHelpers
import SwiftGodot

extension AnimationName {
    static let flash = Self("flash")
}

@Godot class Enemy: Area2D {
    @SceneTree(path: "Sprite2D") var sprite: Sprite2D!
    @SceneTree(path: "EnemyPaths") var paths: Node!
    @SceneTree(path: "AnimationPlayer") var animationPlayer: AnimationPlayer!
    @SceneTree(path: "GunCooldown") var gunCooldownTimer: Timer!
    @SceneTree(path: "CollisionShape2D") var collisionShape: CollisionShape2D!
    @SceneTree(path: "Explosion") var explosion: Sprite2D!
    @SceneTree(path: "Explosion/AnimationPlayer") var explosionPlayer: AnimationPlayer!

    @SceneTree(path: "LaserSound") var laserSound: AudioStreamPlayer!
    @SceneTree(path: "ExplosionSound") var explosionSound: AudioStreamPlayer!

    var speed = 150.0
    var rotationSpeed = 120.0
    var health = 3
    var bulletSpread = 0.2

    var follow: PathFollow2D = .init()
    weak var target: Player? = nil
    var invulnerableAfterRockHit = false

    override func _ready() {
        guard !Engine.isEditorHint() else { return }
        sprite.frame = .random(in: 0 ... 2)

        guard let path = paths.getChildren().randomElement() else {
            GD.pushError("Didn't find any enemy paths")
            return
        }
        path.addChild(node: follow)
        follow.loop = false

        gunCooldownTimer.timeout.connect { [weak self] in
            self?.shootPulse(amount: .random(in: 1 ... 3), delay: .seconds(0.15))
        }

        bodyEntered.connect { [weak self] body in
            guard let self else { return }
            if let player = body as? Player {
                explode()
                player.shield -= 50
            }

            if body is Rock {
                guard !invulnerableAfterRockHit else {
                    return
                }
                invulnerableAfterRockHit = true
                takeDamage(amount: 1)
            }

            GD.print("enemy collided with \(body)")
        }
    }

    override func _physicsProcess(delta: Double) {
        guard !Engine.isEditorHint() else { return }
        rotation += GD.degToRad(deg: rotationSpeed) * delta
        follow.progress += speed * delta
        position = follow.globalPosition
        if follow.progressRatio >= 1 {
            queueFree()
        }
    }

    func takeDamage(amount: Int) {
        health -= amount
        GD.print("Enemy taking \(amount) damage to health \(health)")
        animationPlayer.play(.flash)

        if health <= 0 {
            explode()
            return
        }

        animationPlayer.animationFinished.connect { [weak self] _ in
            self?.invulnerableAfterRockHit = false
        }
    }

    func explode() {
        explosionSound.play()
        speed = 0
        gunCooldownTimer.stop()
        collisionShape.setDeferred(property: .disabled, value: true)
        sprite.hide()
        explosion.show()
        explosionPlayer.play(.explosion)
        explosionPlayer.animationFinished.connect { [weak self] _ in
            self?.queueFree()
        }
    }

    func shoot() {
        guard let target else { return }
        laserSound.play()
        let direction = globalPosition
            .directionTo(to: target.globalPosition)
            .rotated(angle: .random(in: -bulletSpread ... bulletSpread))

        let bullet = EnemyBullet.makeScene()
        getTree()?.root?.addChild(node: bullet)
        bullet.start(position: globalPosition, direction: direction)
    }

    func shootPulse(amount: Int, delay: Duration) {
        Task { @MainActor [weak self] in
            for _ in 1 ... amount {
                shoot()
                try? await Task.sleep(for: delay)
            }
        }
    }
}

extension Enemy: SceneInstantiable {
    static var resourcePath: String = "res://enemy.tscn"
}
