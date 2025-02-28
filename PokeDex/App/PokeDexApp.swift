//
//  Pokemon Clean Architecture
//
//  Created by yamartin on 22/11/24.
//

import SwiftUI

@main
struct PokeDexApp: App {
    @StateObject private var tabBarState = TabBarState()

    var body: some Scene {
        WindowGroup {
            FloatingTabBar()                .environmentObject(tabBarState)
        }
    }
}
