import SGHelpers
import SwiftGodot

extension SignalWithNoArguments {
    static let startGame = Self("start_game", classType: HUD.self)
}

extension Texture2D {
    static let green = #texture2DLiteral("res://assets/bar_green_200.png")
    static let yellow = #texture2DLiteral("res://assets/bar_yellow_200.png")
    static let red = #texture2DLiteral("res://assets/bar_red_200.png")
}

@Godot public class HUD: CanvasLayer {
    @SceneTree(path: "MarginContainer/HBoxContainer/LivesCounter") var livesContainer: HBoxContainer!
    @SceneTree(path: "MarginContainer/HBoxContainer/ScoreLabel") var scoreLabel: Label!
    @SceneTree(path: "VBoxContainer/Message") var messageLabel: Label!
    @SceneTree(path: "VBoxContainer/StartButton") var startButton: TextureButton!
    @SceneTree(path: "MessageTimer") var messageTimer: Timer!
    @SceneTree(path: "MarginContainer/HBoxContainer/ShieldBar") var shieldBar: TextureProgressBar!

    override public func _ready() {
        startButton.pressed.connect { [weak self] in
            guard let self else { return }
            startButton.hide()
            emit(signal: .startGame)
        }

        messageTimer.timeout.connect { [weak self] in
            self?.hideMessage()
        }
    }

    func show(message: String, dismissAutomatically: Bool = true) {
        messageLabel.text = message
        messageLabel.show()

        if dismissAutomatically {
            messageTimer.start()
        }
    }

    func hideMessage() {
        messageLabel.hide()
        messageLabel.text = ""
    }

    func updateScore(to score: Int) {
        scoreLabel.text = String(score)
    }

    @Callable func updateShield(to shieldPercent: Double) {
        switch shieldPercent {
        case 0.0 ..< 0.4:
            shieldBar.textureProgress = .red
        case 0.4 ..< 0.7:
            shieldBar.textureProgress = .yellow
        case 0.7 ... 1.0:
            shieldBar.textureProgress = .green
        default:
            GD.pushError("Unexpected Shield % value: \(shieldPercent) — should be between 0.0 and 1.0")
        }
        shieldBar.value = shieldPercent
    }

    @Callable func updateLifeCount(to lifeCount: Int) {
        let lives = livesContainer.getChildren().compactMap { $0 as? TextureRect }

        for (index, life) in lives.enumerated() {
            life.visible = lifeCount > index
        }
    }

    func gameOver() {
        Task { @MainActor [weak self] in
            show(message: "Game Over")
            await messageTimer.timeout
            self?.startButton.show()
        }
    }
}
