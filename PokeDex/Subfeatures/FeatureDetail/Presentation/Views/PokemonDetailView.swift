//
//  PokemonDetailView.swift
//  PokeDex
//
//  Created by yamartin on 29/11/24.
//

import SwiftUI

struct PokemonDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var tabBarState: TabBarState

    @StateObject private var viewModel: PokemonDetailViewModel
    @State var isLiked: Bool = false

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
                    CardView(pokemonDetail: viewModel.pokemonDetail, pokeColor: pokeColor, liked: $isLiked)

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
                        viewModel.onAppear(model: modelContext)
                    }
            }
            .navigationTitle(viewModel.pokemonDetail?.name.capitalized ?? "")
            .font(.title)
            .bold()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.headerBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(.black)
            .toolbar(.hidden, for: .tabBar)
            .onChange(of: isLiked) {
                if isLiked {
                    tabBarState.isLiked = true
                    self.viewModel.likeButtonPressed(liked: isLiked)
                }
            }
        }
    }
}

#Preview {
    PokemonDetailAssembly.view(dto: PokemonDetailAssemblyDTO(idPokemon: 4))
}
