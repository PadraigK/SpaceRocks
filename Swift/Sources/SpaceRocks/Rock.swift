import SGHelpers
import SwiftGodot

extension AnimationName {
    static let explosion = Self("explosion")
}

extension SignalWith4Arguments<Int, Double, Vector2, Vector2> {
    static let exploded = Self("exploded", classType: Rock.self)
}

public class Rock: RigidBody2D {
    @SceneTree(path: "Sprite2D") var sprite: Sprite2D!
    @SceneTree(path: "CollisionShape2D") var collisionShape: CollisionShape2D!
    @SceneTree(path: "Explosion") var explosion: Sprite2D!
    @SceneTree(path: "Explosion/AnimationPlayer") var explosionPlayer: AnimationPlayer!

    enum Kind: Int {
        case large
        case medium
        case small

        var scale: Double {
            switch self {
            case .large: 3
            case .medium: 2
            case .small: 1
            }
        }

        var shieldDamage: Double {
            switch self {
            case .large: 75
            case .medium: 50
            case .small: 25
            }
        }

        func nextSizeDown() -> Kind? {
            switch self {
            case .large: .medium
            case .medium: .small
            case .small: nil
            }
        }
    }

    var screensize = Vector2.zero
    var kind = Kind.large
    var radius = 0.0
    var scaleFactor = 0.2

    func explode() {
        collisionShape.setDeferred(property: .disabled, value: true)
        sprite.hide()
        explosionPlayer.play(.explosion)
        explosion.show()
        emit(signal: .exploded, kind.rawValue, radius, position, linearVelocity)
        linearVelocity = .zero
        angularVelocity = 0
        explosionPlayer.animationFinished.connect { [weak self] _ in
            self?.queueFree()
        }
    }

    override public func _ready() {}

    func start(position: Vector2, velocity: Vector2, kind: Kind) {
        self.position = position
        self.kind = kind
        let mass = 1.5 * kind.scale
        sprite.scale = Vector2.one * scaleFactor * kind.scale
        guard let textureWidth = sprite.texture?.getSize().x else {
            GD.pushError("Couldn't get texture kind on \(sprite)")
            return
        }

        radius = Double(textureWidth / 2 * sprite.scale.x)
        let shape = CircleShape2D()
        shape.radius = radius
        collisionShape.shape = shape

        linearVelocity = velocity
        angularVelocity = .random(in: -.pi ... .pi)

        explosion.scale = Vector2.one * 0.75 * kind.scale
    }

    override public func _integrateForces(state: PhysicsDirectBodyState2D?) {
        guard var xform = state?.transform else {
            return
        }
        xform.origin.x = Float(
            GD.wrapf(
                value: .init(xform.origin.x),
                min: 0 - radius,
                max: .init(screensize.x) + radius
            )
        )
        xform.origin.y = Float(
            GD.wrapf(
                value: .init(xform.origin.y),
                min: 0 - radius,
                max: .init(screensize.y) + radius
            )
        )
        state?.transform = xform
    }
}

extension Rock: SceneInstantiable {
    public static var resourcePath: String = "res://rock.tscn"
}
