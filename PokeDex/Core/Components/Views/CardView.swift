//
//  CardView.swift
//  PokeDex
//
//  Created by yamartin on 17/2/25.
//

import SwiftUI

struct CardView: View {
    var pokemonDetail: PokemonModel?
    var pokeColor: Color

    var body: some View {
        VStack {
            HStack {
                Text( pokemonDetail?.getNumber() ?? "000")
                    .padding( 10)
                    .foregroundColor(.white)
                Spacer()
            }
            AsyncImage(url: pokemonDetail?.imageURL) { image in
                image.image?.resizable()
            }
            .scaledToFit()
            .frame(width: 300, height: 300)
            .padding(.bottom, 0)

            Text(pokemonDetail?.name.capitalized ?? "")
                .font(.system(size: 50))
                .bold()
                .foregroundColor(.white) // esta mal
                .padding(.bottom, 0)
            HStack( spacing: 10) {
                VStack {
                    Text("Height") // esta mal
                        .font(.system(size: 30))
                        .bold()
                        .foregroundColor(.white)
                    Text(String(pokemonDetail?.height ?? 0))
                        .font(.system(size: 20))
                    .foregroundColor(.white)
                }
                VStack {
                    Text("Weight") // esta mal
                        .font(.system(size: 30))
                        .bold()
                        .foregroundColor(.white)
                    Text(String(pokemonDetail?.weight ?? 0))
                        .font(.system(size: 20))
                    .foregroundColor(.white)
                }
            }
            .padding(.top, 1)
            .padding(.bottom, 20)
        }.background(LinearGradient(
            colors: [
                pokeColor.adjust(brightness: 0.2),
                pokeColor,
                pokeColor.adjust(brightness: -0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
        .cornerRadius(15)
        .padding()
        .shadow(color: pokeColor.adjust(brightness: -0.2), radius: 5, x: 0, y: 10)
    }
}
