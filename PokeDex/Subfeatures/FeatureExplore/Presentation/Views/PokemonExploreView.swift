//
//  PokemonExploreView.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import SwiftUI

struct PokemonExploreView: View {
    @EnvironmentObject var tabBarState: TabBarState
    @StateObject private var viewModel: PokemonExploreViewModel

    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10),
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    init(_ viewModel: PokemonExploreViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
            VStack(spacing: 0) {
                header
                Spacer()
                if viewModel.state == .okey {
                    list
                } else if viewModel.state == .error {
                    HStack {
                        Text("Ha habido un error")
                    }
                }
            } // VSTACK
  

        .onAppear {
            tabBarState.isTabBarVisible = true
            viewModel.onAppear()
        }
        .sheet(isPresented: self.$viewModel.showWarningError) {
            CustomErrorView(actionPerformed: viewModel.errorViewAction)
        }
        .loaderBase(state: self.viewModel.state)
        .toolbar(.hidden, for: .tabBar)

    }


    var header: some View {
        HStack {
            Spacer()
            Text("Pokedex NTTData")
                .font(.title)
                .bold()
                .padding(.vertical)
                .padding(.leading)
            Image("pokeball")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            Spacer()
        }
        .foregroundColor(.white) // MAL
        .background(
            Color.headerBackground
        )
        
    }

    var list: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                ForEach(viewModel.pokemons) { pokemon in
                    NavigationLink(destination: PokemonDetailAssembly.view(dto: PokemonDetailAssemblyDTO(idPokemon: pokemon.id))) {
                        PokemonCellView(name: pokemon.name,
                                        number: pokemon.id,
                                        imageURL: pokemon.imageURL,
                                        background: pokemon.types.first?.getColor() ?? .black)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                                    tabBarState.isTabBarVisible = false // Hide tab bar when navigating
                                })
                }
            }
        }
        .padding(.horizontal)
        .background(Color.defaultBackground)
        .ignoresSafeArea(.all, edges: .bottom)

    }
}

#Preview {
    PokemonExploreAssembly.view(dto: PokemonExploreAssemblyDTO())
}
