//
//  PokemonDetailView.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import SwiftUI


struct PokemonDetailView: View {
    @StateObject private var viewModel: PokemonDetailViewModel
   
    init(_ viewModel: PokemonDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            if viewModel.pokemonDetail == nil {
                Text("Loading...")
            } else {
                AsyncImage(url: viewModel.pokemonDetail?.pokemon.imageURL) { image in
                    image.image?.resizable()
                }
                .scaledToFit()
                
                Text(viewModel.pokemonDetail?.pokemon.name ?? "")
                    .font(.title)
                
                HStack {
                    Text("Height: \(viewModel.pokemonDetail?.height ?? 0)")
                        .font(.subheadline)
                    Text("Weight: \(viewModel.pokemonDetail?.weight ?? 0)")
                        .font(.subheadline)
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
