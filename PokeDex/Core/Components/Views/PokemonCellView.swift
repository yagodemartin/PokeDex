//
//  PokemonListView.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import SwiftUI

struct PokemonCellView: View {
    let name: String
    var imageURL: URL?

    var body: some View {
        VStack {
            HStack {
                AsyncImage(url: imageURL) { image in
                    image
                        .image?
                        .resizable().scaledToFill()
                }
                .frame(width: 150, height: 150)
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color:.black.opacity(0.5), radius: 5, x: 5, y: 5)
            }

            HStack {
                Text(name)
                    .font(.headline)
            }.padding(.top)
        }
    }
}
