//
//  FeatureDetailAssembly.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import SwiftUI

class PokemonDetailAssembly {
    @MainActor
    static func view(dto: PokemonDetailAssemblyDTO) -> some View {
        let viewModel = PokemonDetailViewModel(dto: dto)
        return PokemonDetailView(viewModel)
    }
}

struct PokemonDetailAssemblyDTO {
    var idPokemon: Int
}
