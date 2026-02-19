//
//  Color_extension.swift
//  PokeDex
//
//  Created by yamartin on 17/2/25.
//

import Foundation
import SwiftUI
import UIKit

extension Color {
    // MARK: - TabBar Colors (Liquid Glass)

    /// TabBar accent color for active/selected tabs (red, matches header)
    static let tabBarActive = Color(red: 0.95, green: 0.2, blue: 0.2)

    /// TabBar inactive color for unselected tabs (white with transparency)
    static let tabBarInactive = Color.white.opacity(0.6)

    // MARK: - Utility Methods

    func adjust(hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, opacity: CGFloat = 1) -> Color {
        let color = UIColor(self)
        var currentHue: CGFloat = 0
        var currentSaturation: CGFloat = 0
        var currentBrigthness: CGFloat = 0
        var currentOpacity: CGFloat = 0

        if color.getHue(&currentHue, saturation: &currentSaturation, brightness: &currentBrigthness, alpha: &currentOpacity) {
            return Color(hue: currentHue + hue,
                         saturation: currentSaturation + saturation,
                         brightness: currentBrigthness + brightness,
                         opacity: currentOpacity + opacity)
        }
        return self
    }
}
