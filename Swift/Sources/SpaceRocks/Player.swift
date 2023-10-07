import SGHelpers
import SwiftGodot

extension SignalWith1Argument<Int> {
    static let livesChanged = Self("lives_changed", classType: Player.self)
    static let scored = Self("scored", classType: Player.self)
}

extension SignalWith1Argument<Double> {
    static let shieldChanged = Self("shield_changed", classType: Player.self)
}

extension SignalWithNoArguments {
    static let dead = Self("dead", classType: Player.self)
}

@Godot public class Player: RigidBody2D {
    @SceneTree(path: "Sprite2D") var sprite: Sprite2D!
    @SceneTree(path: "CollisionShape2D") var collisionShape: CollisionShape2D!
    @SceneTree(path: "GunCooldown") var gunCooldownTimer: Timer!
    @SceneTree(path: "Muzzle") var muzzleMarker: Marker2D!
    @SceneTree(path: "InvulnerabilityTimer") var invulnerabilityTimer: Timer!
    @SceneTree(path: "Explosion") var explosion: Sprite2D!
    @SceneTree(path: "Explosion/AnimationPlayer") var explosionPlayer: AnimationPlayer!
    @SceneTree(path: "LaserSound") var laserSound: AudioStreamPlayer!
    @SceneTree(path: "EngineSound") var engineSound: AudioStreamPlayer!
    @SceneTree(path: "ExplosionSound") var explosionSound: AudioStreamPlayer!
    @SceneTree(path: "Exhaust") var exhaust: GPUParticles2D!

    lazy var screenSize = getViewportRect().size
    var enginePower: Int64 = 500
    var spinPower = 8000.0
    var thrust = Vector2.zero
    var rotationDirection = 0.0
    var fireRate = 0.25
    var gunState: GunState = .ready
    var resetPosition = false

    let maxShield = 100.0
    let shieldRegenRate = 1.0
    var shield: Double = 0 {
        didSet {
            emit(signal: .shieldChanged, shield / maxShield)
            if shield <= 0 {
                lives -= 1
                explode()
            }
        }
    }

    var lives = 0 {
        didSet {
            emit(signal: .livesChanged, lives)
            if lives <= 0 {
                update(state: .dead)
            } else {
                update(state: .invulnerable)
            }
            shield = maxShield
        }
    }

    enum GunState {
        case ready
        case cooldown
    }

    enum State {
        case initial
        case alive
        case invulnerable
        case dead
    }

    private(set) var state: State = .initial

    func update(state newState: State) {
        switch newState {
        case .initial:
            collisionShape.setDeferred(property: .disabled, value: true)
            sprite.modulate.alpha = 0.5
        case .alive:
            collisionShape.setDeferred(property: .disabled, value: false)
            sprite.modulate.alpha = 1.0
        case .invulnerable:
            collisionShape.setDeferred(property: .disabled, value: true)
            sprite.modulate.alpha = 0.5
            invulnerabilityTimer.start()
        case .dead:
            collisionShape.setDeferred(property: .disabled, value: true)
            sprite.hide()
            linearVelocity = .zero
            engineSound.stop()
            exhaust.emitting = false
            emit(signal: .dead)
        }
        state = newState
    }

    func reset() {
        resetPosition = true
        sprite.show()
        lives = 3
        update(state: .alive)
        exhaust.emitting = false
    }

    override public func _ready() {
        update(state: .alive)
        gunCooldownTimer.waitTime = fireRate

        gunCooldownTimer.timeout.connect { [weak self] in
            self?.gunState = .ready
        }

        invulnerabilityTimer.timeout.connect { [weak self] in
            self?.update(state: .alive)
        }

        bodyEntered.connect { [weak self] body in
            guard let self else { return }

            if let rock = body as? Rock {
                shield -= rock.kind.shieldDamage
                rock.explode()
            }
        }
    }

    override public func _process(delta: Double) {
        guard !Engine.isEditorHint() else { return }
        getInput()
        shield = (0 ... maxShield).clamp(shield + shieldRegenRate * delta)
    }

    func explode() {
        explosionSound.play()
        explosion.show()
        explosionPlayer.play(.explosion)
        explosionPlayer.animationFinished.connect { [weak self] _ in
            self?.explosion.hide()
        }
    }

    func shoot() {
        guard state != .invulnerable, gunState == .ready else { return }
        gunState = .cooldown
        gunCooldownTimer.start()
        let bullet = Bullet.makeScene()
        getTree()?.root?.addChild(node: bullet)
        laserSound.play()
        bullet.start(transform: muzzleMarker.globalTransform)
        bullet.connect(signal: .bulletHit, to: self, method: "bulletHit")
    }

    @Callable func bulletHit(target: ObjectWrapper<CollisionObject2D>) {
        if target.object is Rock {
            emit(signal: .scored, 1)
        }

        if target.object is Enemy {
            emit(signal: .scored, 5)
        }
    }

    func getInput() {
        thrust = .zero
        guard ![.dead, .initial].contains(state) else {
            return
        }

        rotationDirection = Input.getAxis(negative: .rotateLeft, positive: .rotateRight)

        if Input.isActionPressed(.thrust) {
            thrust = transform.x * enginePower
            if !engineSound.isPlaying() {
                engineSound.play()
            }

            exhaust.emitting = true
        } else {
            engineSound.stop()
            exhaust.emitting = false
        }

        if Input.isActionPressed(.shoot) {
            shoot()
        }
    }

    override public func _physicsProcess(delta: Double) {
        constantForce = thrust
        constantTorque = rotationDirection * spinPower
    }

    override public func _integrateForces(state physicsState: PhysicsDirectBodyState2D?) {
        guard var xform = physicsState?.transform else {
            GD.print("no state")
            return
        }

        if resetPosition {
            xform.origin = screenSize / 2.0
            xform.origin.y += 70 // get it out of the way of the message text
            resetPosition = false
        } else {
            xform.origin.x = Float(
                GD.wrapf(
                    value: Double(xform.origin.x),
                    min: 0,
                    max: Double(screenSize.x)
                )
            )
            xform.origin.y = Float(
                GD.wrapf(
                    value: Double(xform.origin.y),
                    min: 0,
                    max: Double(screenSize.y)
                )
            )
        }

        physicsState?.transform = xform
    }
}
