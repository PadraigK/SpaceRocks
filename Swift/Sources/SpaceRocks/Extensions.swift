import SGHelpers
import SwiftGodot

extension ClosedRange {
    func clamp(_ value: Bound) -> Bound {
        lowerBound > value ? lowerBound
            : upperBound < value ? upperBound
            : value
    }
}

struct AnimationName {
    let rawValue: StringName
    init(_ rawValue: StringName) {
        self.rawValue = rawValue
    }
}

extension AnimationPlayer {
    func play(_ name: AnimationName) {
        play(name: name.rawValue)
    }
}

extension AnimatedSprite2D {
    var animationName: AnimationName {
        set {
            animation = newValue.rawValue
        }
        get {
            AnimationName(animation)
        }
    }

    func play(_ name: AnimationName) {
        play(name: name.rawValue)
    }
}

struct ActionName {
    let rawValue: StringName
    init(_ rawValue: StringName) {
        self.rawValue = rawValue
    }
}

extension Input {
    static func isActionPressed(_ action: ActionName) -> Bool {
        isActionPressed(action: action.rawValue)
    }

    static func getAxis(negative: ActionName, positive: ActionName) -> Double {
        getAxis(negativeAction: negative.rawValue, positiveAction: positive.rawValue)
    }
}

extension ActionName {
    static let thrust = Self("thrust")
    static let rotateLeft = Self("rotate_left")
    static let rotateRight = Self("rotate_right")
    static let shoot = Self("shoot")
    static let pause = Self("pause")
}

extension InputEvent {
    func isActionPressed(_ action: ActionName) -> Bool {
        isActionPressed(action: action.rawValue)
    }
}

struct PropertyName {
    let rawValue: StringName
    init(_ rawValue: StringName) {
        self.rawValue = rawValue
    }
}

extension PropertyName {
    static let disabled = Self("disabled")
}

extension Object {
    func setDeferred(property: PropertyName, value: some VariantConvertible) {
        setDeferred(property: property.rawValue, value: value.toVariant())
    }
}
