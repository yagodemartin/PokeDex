//
//  PokemonDetailView.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import SwiftUI

struct PokemonDetailView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var viewModel: PokemonDetailViewModel

    init(_ viewModel: PokemonDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        let pokeColor = viewModel.pokemonDetail?.types.first?.getColor() ?? Color.gray

        NavigationStack {
            ZStack {
                Color.red
                    .ignoresSafeArea()

                ScrollView {
                    CardView(pokemonDetail: viewModel.pokemonDetail, pokeColor: pokeColor)

                    // Types
                    if let types = viewModel.pokemonDetail?.types {
                        HStack {
                            ForEach(types, id: \.self) { type in
                                CapsuleView(type: type)
                            }
                        }
                    }

                    Text(viewModel.pokemonDetailSpecie?.flavorText ?? "")
                        .font(.callout)
                          .multilineTextAlignment(.leading)
                          .padding()

                    if let stats = self.viewModel.pokemonDetail?.stats {
                        PokemonStatsChartView(stats: stats).padding(.horizontal)
                    }
                }
                .background(.white)
                .edgesIgnoringSafeArea(.horizontal)
                    .onAppear {
                        viewModel.onAppear()
                    }
            }
            .navigationTitle(viewModel.pokemonDetail?.name.capitalized ?? "")
            .font(.title)
            .bold()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(.black)
        }
    }
}

#Preview {
    PokemonDetailAssembly.view(dto: PokemonDetailAssemblyDTO(idPokemon: 4))
}
