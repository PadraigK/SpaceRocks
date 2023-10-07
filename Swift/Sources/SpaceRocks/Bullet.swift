import SGHelpers
import SwiftGodot

extension SignalWith1Argument<CollisionObject2D> {
    static let bulletHit = Self("bullet_hit", classType: Bullet.self)
}

@Godot public class Bullet: Area2D {
    @SceneTree(path: "VisibleOnScreenNotifier2D") var visibleOnScreenNotifier: VisibleOnScreenNotifier2D!

    var speed: Int64 = 1500
    var velocity = Vector2.zero

    func start(transform: Transform2D) {
        self.transform = transform
        velocity = transform.x * speed
    }

    override public func _ready() {
        guard !Engine.isEditorHint() else { return }
        visibleOnScreenNotifier.screenExited.connect { [weak self] in
            self?.queueFree()
        }

        areaEntered.connect { [weak self] in
            self?.collided(with: $0)
        }

        bodyEntered.connect { [weak self] in
            self?.collided(with: $0)
        }
    }

    private func collided(with object: Node) {
        if let enemy = object as? Enemy {
            emit(signal: .bulletHit, enemy)
            enemy.takeDamage(amount: 1)
        }

        if let rock = object as? Rock {
            emit(signal: .bulletHit, rock)
            rock.explode()
        }

        if let player = object as? Player {
            // don't do anything if its our own bullet
            return
        }

        queueFree()
    }

    override public func _process(delta: Double) {
        position = position + velocity * delta
    }
}

extension Bullet: SceneInstantiable {
    public static var resourcePath: String = "res://bullet.tscn"
}
