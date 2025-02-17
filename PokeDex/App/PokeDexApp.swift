//
//  Pokemon Clean Architecture
//
//  Created by yamartin on 22/11/24.
//

import SwiftUI

@main
struct PokeDexApp: App {
    var body: some Scene {
        WindowGroup {
            PokemonExploreAssembly.view(dto: PokemonExploreAssemblyDTO())
        }
    }
}
