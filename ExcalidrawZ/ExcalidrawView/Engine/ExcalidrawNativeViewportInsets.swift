//
//  ExcalidrawNativeViewportInsets.swift
//  ExcalidrawZ
//
//  Native chrome overlay insets that the Web canvas should reserve for its
//  own UI controls while the drawing surface itself may extend underneath.
//

import SwiftUI

struct ExcalidrawNativeViewportInsets: Codable, Equatable, Sendable {
    var top: Double
    var right: Double
    var bottom: Double
    var left: Double

    static let zero = ExcalidrawNativeViewportInsets()

    init(
        top: CGFloat = 0,
        right: CGFloat = 0,
        bottom: CGFloat = 0,
        left: CGFloat = 0
    ) {
        self.top = Self.normalized(top)
        self.right = Self.normalized(right)
        self.bottom = Self.normalized(bottom)
        self.left = Self.normalized(left)
    }

    private static func normalized(_ value: CGFloat) -> Double {
        let double = Double(value)
        guard double.isFinite else { return 0 }
        return max(0, ceil(double))
    }
}

private struct ExcalidrawNativeViewportInsetsKey: EnvironmentKey {
    static let defaultValue: ExcalidrawNativeViewportInsets = .zero
}

extension EnvironmentValues {
    var excalidrawNativeViewportInsets: ExcalidrawNativeViewportInsets {
        get { self[ExcalidrawNativeViewportInsetsKey.self] }
        set { self[ExcalidrawNativeViewportInsetsKey.self] = newValue }
    }
}
