import SGHelpers
import SwiftGodot

@Godot public class EnemyBullet: Area2D {
    @SceneTree(path: "VisibleOnScreenNotifier2D") var visibleOnScreenNotifier: VisibleOnScreenNotifier2D!

    var speed: Int64 = 1000
    var damage: Double = 15

    func start(position: Vector2, direction: Vector2) {
        self.position = position
        rotation = direction.angle()
    }

    override public func _ready() {
        guard !Engine.isEditorHint() else { return }
        visibleOnScreenNotifier.screenExited.connect { [weak self] in
            self?.queueFree()
        }

        bodyEntered.connect { [weak self] body in
            guard let self else { return }
            if let rock = body as? Rock {
                rock.explode()
            }

            if let player = body as? Player {
                GD.print("Enemy bullet hit player, damaging shield for \(damage)")
                player.shield -= damage
            }

            queueFree()
        }
    }

    override public func _process(delta: Double) {
        guard !Engine.isEditorHint() else { return }
        position = position + transform.x * speed * delta
    }
}

extension EnemyBullet: SceneInstantiable {
    public static var resourcePath: String = "res://enemy_bullet.tscn"
}
