//
//  CardView.swift
//  PokeDex
//
//  Created by yamartin on 17/2/25.
//

import SwiftUI

struct CardView: View {

    var pokemonDetail: PokemonModel?

    var body: some View {

        HStack {
            Text ( pokemonDetail?.getNumber() ?? "000")
                .padding( 10)
                .foregroundColor(.white)
            Spacer()
        }
        AsyncImage(url: pokemonDetail?.imageURL) { image in
            image.image?.resizable()
        }
        .scaledToFit()
        .frame(width: 300 , height: 300)
        .padding(.bottom , 0)


        Text(pokemonDetail?.name.capitalized ?? "")
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
                Text(String(pokemonDetail?.height  ?? 0))
                    .font(.system(size: 20))
                .foregroundColor(.white)                        }
            VStack {
                Text("Weight")
                    .font(.system(size: 30))
                    .bold()
                    .foregroundColor(.white)
                Text(String(pokemonDetail?.weight ?? 0))
                    .font(.system(size: 20))
                .foregroundColor(.white)                        }

        }
        .padding(.top, 1)
        .padding(.bottom , 20)

    }.background(LinearGradient(
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
