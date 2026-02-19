//
//  Pokemon Clean Architecture
//
//  Created by yamartin on 22/11/24.
//

import SwiftUI
import SwiftData
import Foundation

var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        PokemonModel.self,
        FavoritePokemonDTO.self  // Include favorites in the main data store
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

    init() {
        // Initialize FavouritesDataSource with the shared ModelContainer
        // This ensures favorites are persisted to the main app database
        FavouritesDataSource.initializeShared(modelContainer: sharedModelContainer)
    }

    var body: some Scene {
        WindowGroup {
            FloatingTabBar()
                .environmentObject(tabBarState)
                .modelContainer(sharedModelContainer)
        }
    }
}
