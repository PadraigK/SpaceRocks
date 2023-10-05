import SwiftGodot
import SwiftGodotMacros

class Player: RigidBody2D {
    @SceneTree(path: "Sprite2D") var sprite: Sprite2D!
    @SceneTree(path: "CollisionShape2D") var collisionShape: CollisionShape2D!
    @SceneTree(path: "GunCooldown") var gunCooldownTimer: Timer!
    @SceneTree(path: "Muzzle") var muzzleMarker: Marker2D!

    lazy var screenSize = getViewportRect().size
    var enginePower: Int64 = 500
    var spinPower = 8000.0
    var thrust = Vector2.zero
    var rotationDirection = 0.0
    var fireRate = 0.25
    var gunState: GunState = .ready

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
        case .alive:
            collisionShape.setDeferred(property: .disabled, value: false)
        case .invulnerable:
            collisionShape.setDeferred(property: .disabled, value: true)
        case .dead:
            collisionShape.setDeferred(property: .disabled, value: true)
        }
        state = newState
    }

    override func _ready() {
        update(state: .alive)
        gunCooldownTimer.waitTime = fireRate

        gunCooldownTimer.timeout.connect { [weak self] in
            self?.gunState = .ready
        }
    }

    override func _process(delta: Double) {
        guard !Engine.isEditorHint() else { return }
        getInput()
    }

    func shoot() {
        guard state != .invulnerable, gunState == .ready else { return }
        gunState = .cooldown
        gunCooldownTimer.start()
        let bullet = Bullet.makeScene()
        getTree()?.root?.addChild(node: bullet)
        bullet.start(transform: muzzleMarker.globalTransform)
    }

    func getInput() {
        thrust = .zero
        guard ![.dead, .initial].contains(state) else {
            return
        }

        if Input.isActionPressed(.thrust) {
            thrust = transform.x * enginePower
        }

        if Input.isActionPressed(.shoot) {
            shoot()
        }

        rotationDirection = Input.getAxis(negative: .rotateLeft, positive: .rotateRight)
    }

    override func _physicsProcess(delta: Double) {
        constantForce = thrust
        constantTorque = rotationDirection * spinPower
    }

    override func _integrateForces(state physicsState: PhysicsDirectBodyState2D?) {
        guard var xform = physicsState?.transform else {
            GD.print("no state")
            return
        }
        xform.origin.x = Float(GD.wrapf(value: Double(xform.origin.x), min: 0, max: Double(screenSize.x)))
        xform.origin.y = Float(GD.wrapf(value: Double(xform.origin.y), min: 0, max: Double(screenSize.y)))
        physicsState?.transform = xform
    }
}
