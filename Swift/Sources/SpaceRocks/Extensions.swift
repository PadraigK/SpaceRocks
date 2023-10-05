import SGHelpers
import SwiftGodot

struct ActionName {
    let rawValue: StringName
    init(_ rawValue: StringName) {
        self.rawValue = rawValue
    }
}

extension ActionName {
    static let thrust = Self("thrust")
    static let rotateLeft = Self("rotate_left")
    static let rotateRight = Self("rotate_right")
    static let shoot = Self("shoot")
}

extension Input {
    static func isActionPressed(_ action: ActionName) -> Bool {
        isActionPressed(action: action.rawValue)
    }

    static func getAxis(negative: ActionName, positive: ActionName) -> Double {
        getAxis(negativeAction: negative.rawValue, positiveAction: positive.rawValue)
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
