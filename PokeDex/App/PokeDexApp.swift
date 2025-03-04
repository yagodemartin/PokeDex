//
//  Pokemon Clean Architecture
//
//  Created by yamartin on 22/11/24.
//

import SwiftUI
import SwiftData

var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        PokemonModel.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

@main
struct PokeDexApp: App {
    @StateObject private var tabBarState = TabBarState()

    var body: some Scene {
        WindowGroup {
            FloatingTabBar()                .environmentObject(tabBarState)
                .modelContainer(sharedModelContainer)
        }
    }
}
