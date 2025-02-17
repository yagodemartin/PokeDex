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

        let pokecolor = viewModel.pokemonDetail?.types.first?.getColor() ?? Color.gray
        NavigationStack {
            ZStack {
                Color.red
                    .ignoresSafeArea()

                ScrollView {
                    VStack {
                        HStack {
                            Text ( viewModel.pokemonDetail?.getNumber() ?? "000")
                                .padding( 10)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        AsyncImage(url: viewModel.pokemonDetail?.imageURL) { image in
                            image.image?.resizable()
                        }
                        .scaledToFit()
                        .frame(width: 300 , height: 300)
                        .padding(.bottom , 0)


                        Text(viewModel.pokemonDetail?.name.capitalized ?? "")
                            .font(.system(size: 50))
                            .bold()
                            .foregroundColor(.white)
                            .padding(.bottom , 0)
                        HStack ( spacing: 10){
                            VStack {
                                Text("Height")
                                    .font(.system(size: 30))
                                    .bold()
                                    .foregroundColor(.white)
                                Text(String(viewModel.pokemonDetail?.height  ?? 0))
                                    .font(.system(size: 20))
                                .foregroundColor(.white)                        }
                            VStack {
                                Text("Weight")
                                    .font(.system(size: 30))
                                    .bold()
                                    .foregroundColor(.white)
                                Text(String(viewModel.pokemonDetail?.weight ?? 0))
                                    .font(.system(size: 20))
                                .foregroundColor(.white)                        }

                        }
                        .padding(.top, 1)
                        .padding(.bottom , 20)

                    }
                    .background(LinearGradient(
                        colors: [
                            pokecolor.adjust(brightness: 0.2),
                            pokecolor,
                            pokecolor.adjust(brightness: -0.2),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .cornerRadius(15)
                    .padding()
                    .shadow(color: pokecolor.adjust(brightness: -0.2), radius: 10, x: 0, y: 10)


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

