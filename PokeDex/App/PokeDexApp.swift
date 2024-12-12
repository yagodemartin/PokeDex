//
//  Pokemon_Clean_ArchitectureApp.swift
//  Pokemon Clean Architecture
//
//  Created by NTTData on 25/08/23.
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
