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
            if viewModel.state == .okey {
                List {
                    ForEach(viewModel.pokemonList, id: \.self) { pokemon in
                        NavigationLink(destination: PokemonDetailAssembly.view(dto: PokemonDetailAssemblyDTO(idPokemon: pokemon.id))) {
                            PokemonCellView(name: pokemon.name, imageURL: pokemon.imageURL)
                        }
                    }
                }
            } else if viewModel.state == .error {
                HStack {
                    Text("Ha habido un error")
                }
            }

        }
        .onAppear {
        viewModel.onAppear()
        }
        .sheet(isPresented: self.$viewModel.showWarningError) {
            CustomErrorView(actionPerformed: viewModel.errorViewAction)
        }
        .loaderBase(state: self.viewModel.state)
    }
}
