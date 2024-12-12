//
//  PokemonExploreView.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import SwiftUI

struct PokemonExploreView: View {
    
    @StateObject private var viewModel: PokemonExploreViewModel
    
    init(_ viewModel: PokemonExploreViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
        
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.pokemonList, id: \.self) { pokemon in
                    NavigationLink(destination: PokemonDetailAssembly.view(dto: PokemonDetailAssemblyDTO(idPokemon: pokemon.id))) {
                        PokemonCellView(name: pokemon.name, imageURL: pokemon.imageURL)
                    }
                }
            }
        }
        .onAppear {
        viewModel.onAppear()
        }
    }
}
