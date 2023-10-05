import SGHelpers
import SwiftGodot
import SwiftGodotMacros

@Godot public class Bullet: Area2D {
    @SceneTree(path: "VisibleOnScreenNotifier2D") var visibleOnScreenNotifier: VisibleOnScreenNotifier2D!

    var speed: Int64 = 1000
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

        bodyEntered.connect { [weak self] body in
            if let rock = body as? Rock {
                rock.explode()
                self?.queueFree()
            }
        }
    }

    override public func _process(delta: Double) {
        position = position + velocity * delta
    }
}

extension Bullet: SceneInstantiable {
    public static var resourcePath: String = "res://bullet.tscn"
}
