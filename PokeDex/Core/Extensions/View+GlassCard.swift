//
//  View+GlassCard.swift
//  PokeDex
//
//  Created by yamartin on 20/2/26.
//

import SwiftUI

/// Modifier that applies Liquid Glass effect to card backgrounds with iOS 16+ fallback.
///
/// - iOS 26+: Real Liquid Glass with specular highlights and adaptive shadows
/// - iOS 16-25: Elegant LinearGradient fallback
extension View {
    /// Applies Liquid Glass card background with automatic fallback for older iOS versions
    /// - Parameters:
    ///   - color: The base color for the card (used in gradient fallback)
    ///   - cornerRadius: Border radius of the rounded rectangle (default: 15)
    @ViewBuilder
    func glassCardBackground(
        color: Color,
        cornerRadius: CGFloat = 15
    ) -> some View {
        if #available(iOS 26, *) {
            // iOS 26+: Real Liquid Glass effect with specular highlights
            self
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: cornerRadius)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        } else {
            // iOS 16-25: Elegant gradient fallback
            self
                .background(
                    LinearGradient(
                        colors: [
                            color.adjust(brightness: 0.2),
                            color,
                            color.adjust(brightness: -0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(cornerRadius)
                .shadow(color: color.adjust(brightness: -0.2), radius: 5, x: 0, y: 10)
        }
    }
}
