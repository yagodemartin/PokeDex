//
//  PokemonView.swift
//  PokeDex
//
//  Created by NTTData 
//

import SwiftUI

struct PokemonListView: View {
    var pokemon: PokemonModel

    var body: some View {
        HStack {
            AsyncImage(url: pokemon.imageURL) { image in
                image
                    .image?
                    .resizable()
            }
            .scaledToFit()
            .frame(width: 100, height: 100)

            Text(pokemon.name)
        }
    }
}
