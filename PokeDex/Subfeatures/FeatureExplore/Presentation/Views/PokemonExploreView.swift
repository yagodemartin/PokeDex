//
//  PokemonExploreView.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import SwiftUI

struct PokemonExploreView: View {
    
    @StateObject private var viewModel: PokemonExploreViewModel
    
    let columns = [
        GridItem(.adaptive(minimum: 200) , spacing: 0),
        GridItem(.adaptive(minimum: 200) , spacing: 0)
    ]

    
    
    init(_ viewModel: PokemonExploreViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 0) {
                
                HStack {
                    Spacer()
                    Text("Pokedex")
                        .font(.title)
                        .bold()
                        .padding(.vertical)
                        .padding(.leading)
                    Image("pokeball")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40 , height: 40)
                    Spacer()
                    
                }
                .foregroundColor(.black)
                .background(
                    Color.headerBackground
                )
                
                if viewModel.state == .okey {
                    list
                } else if viewModel.state == .error {
                    HStack {
                        Text("Ha habido un error")
                    }
                }
                
            } // VSTACK
            .ignoresSafeArea(.all, edges: .bottom)
        }  // Navigation Stack
        
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(isPresented: self.$viewModel.showWarningError) {
            CustomErrorView(actionPerformed: viewModel.errorViewAction)
        }
        .loaderBase(state: self.viewModel.state)
    }
    
    
    var list: some View {

        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                ForEach(viewModel.pokemons, id: \.self) { pokemon in
                    NavigationLink(destination: PokemonDetailAssembly.view(dto: PokemonDetailAssemblyDTO(idPokemon: pokemon.id))) {
                        PokemonCellView(name: pokemon.name,
                                        number: pokemon.id,
                                        imageURL: pokemon.imageURL ,
                                        background: pokemon.types.first?.getColor() ?? .black)

                    }
                }
            }
            
        }
        .padding()
        .background(Color.white)
    }
    
}

#Preview {
    PokemonExploreAssembly.view(dto: PokemonExploreAssemblyDTO())
}
