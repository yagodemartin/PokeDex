//
//  FeatureDetailAssembly.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import SwiftUI

class PokemonExploreAssembly {
    
    @MainActor
    static func view(dto: PokemonExploreAssemblyDTO) -> some View {
        let viewModel = PokemonExploreViewModel(dto: dto)
        return PokemonExploreView(viewModel)
    }
}

struct PokemonExploreAssemblyDTO {
}
