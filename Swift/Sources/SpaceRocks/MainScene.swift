import SwiftGodot

@Godot public class MainScene: Node {
    @SceneTree(path: "RockPath/PathFollow2D") var spawnPath: PathFollow2D!
    @SceneTree(path: "Player") var player: Player!
    @SceneTree(path: "EnemyTimer") var enemyTimer: Timer!
    @SceneTree(path: "HUD") var hud: HUD!
    @SceneTree(path: "ExplosionSound") var explosionSound: AudioStreamPlayer!
    @SceneTree(path: "LevelUpSound") var levelUpSound: AudioStreamPlayer!
    @SceneTree(path: "Music") var music: AudioStreamPlayer!

    lazy var screeensize = getViewport()?.getVisibleRect().size ?? .zero

    var level: Int = 0
    var score: Int = 0 {
        didSet {
            hud.updateScore(to: score)
        }
    }

    var playing = false

    override public func _ready() {
        hud.connect(signal: .startGame, to: self, method: "newGame")
        player.connect(signal: .livesChanged, to: hud, method: "updateLifeCount")
        player.connect(signal: .dead, to: self, method: "gameOver")
        player.connect(signal: .scored, to: self, method: "scored")
        player.connect(signal: .shieldChanged, to: hud, method: "updateShield")
        enemyTimer.timeout.connect { [weak self] in
            self?.spawnEnemy()
        }
        // keeps it responding even when paused
        processMode = .always

        player.shield = player.maxShield
    }

    private func spawnEnemy() {
        let enemy = Enemy.makeScene()
        addChild(node: enemy)
        enemy.target = player
        enemyTimer.start(timeSec: .random(in: 20 ... 40))
    }

    @Callable func scored(amount: Int) {
        score += amount
    }

    override public func _process(delta: Double) {
        guard playing else { return }

        if getTree()?.getNodesInGroup("rocks").size() == 0 {
            newLevel()
        }
    }

    override public func _input(event: InputEvent) {
        // Note, this is busted: `event.isActionPressed(action: "pause")`
        // https://github.com/migueldeicaza/SwiftGodot/issues/157

        if Input.isActionPressed(.pause) {
            guard playing else { return }
            getTree()?.paused.toggle()
            if getTree()?.paused == true {
                hud.show(message: "Paused", dismissAutomatically: false)
            } else {
                hud.hideMessage()
            }
        }
    }

    @Callable func newGame() {
        getTree()?.getNodesInGroup("rocks").forEach { $0.queueFree() }

        level = 0
        score = 0

        hud.show(message: "Get Ready!")
        player.reset()

        hud.messageTimer.timeout.connect { [weak self] in
            self?.playing = true
        }

        music.play()
    }

    @Callable func gameOver() {
        playing = false
        hud.gameOver()
        music.stop()
    }

    func newLevel() {
        levelUpSound.play()
        level += 1
        hud.show(message: "Wave \(level)")
        for i in 0 ... level {
            spawnRock(.large)
        }
        enemyTimer.start(timeSec: .random(in: 5 ... 10))
    }

    func spawnRock(_ kind: Rock.Kind, position: Vector2? = nil, velocity: Vector2? = nil) {
        let position = position ?? randomEdgePosition()
        let velocity = velocity ?? generateRandomVelocity()

        let rock = Rock.makeScene()
        rock.screensize = screeensize
        rock.start(position: position, velocity: velocity, kind: kind)
        callDeferred(method: "add_child", .init(rock))

        rock.connect(signal: .exploded, to: self, method: "rockExploded")
    }

    @Callable func rockExploded(
        kind: Int,
        radius: Double,
        position: Vector2,
        velocity: Vector2
    ) {
        explosionSound.play()
        guard let shrap = Rock.Kind(rawValue: kind)?.nextSizeDown() else {
            return
        }

        for offset in [-1, 1] {
            let direction = player.position
                .directionTo(to: position)
                .orthogonal() * Int64(offset)

            spawnRock(
                shrap,
                position: position + direction * radius,
                velocity: direction * velocity.length() * 1.1
            )
        }
    }

    func randomEdgePosition() -> Vector2 {
        spawnPath.progressRatio = .random(in: 0 ... 1)
        return spawnPath.position
    }

    func generateRandomVelocity() -> Vector2 {
        let angle = Double.random(in: 0 ... .pi * 2)
        let speed = Double.random(in: 50 ... 125)
        return .right.rotated(angle: angle) * speed
    }
}
