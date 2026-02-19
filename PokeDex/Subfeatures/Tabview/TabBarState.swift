//
//  TabBarState.swift
//  PokeDex
//
//  Created by yamartin on 26/2/25.
//

import SwiftUI
import Combine

/// Manages tab bar state for animations (like/dislike).
/// Note: Tab bar visibility is now handled natively by iOS 18+ TabView.minimize behavior.
class TabBarState: ObservableObject {
    @Published var isLiked: Bool = false
    @Published var isDisliked: Bool = false
}
