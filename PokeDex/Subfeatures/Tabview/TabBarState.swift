//
//  TabBarState.swift
//  PokeDex
//
//  Created by yamartin on 26/2/25.
//

import SwiftUI
import Combine

class TabBarState: ObservableObject {
    @Published var isTabBarVisible: Bool = true
    @Published var isLiked: Bool = false
    @Published var isDisliked: Bool = false
}
