//
//  PokemonListView.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import SwiftUI

struct PokemonCellView: View {
    let name: String
    let number: Int?
    var imageURL: URL?
    var background: Color = .gray

    var body: some View {
        VStack {
            HStack {
                AsyncImage(url: imageURL) { image in
                    image
                        .image?
                        .resizable().scaledToFill()
                }
                .frame(width: 150, height: 150)
                .background(LinearGradient(gradient: Gradient(colors: [background.opacity(0.6), background]), startPoint: .top, endPoint: .bottom) )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.5), radius: 5, x: 5, y: 5)
            }

            HStack {
                Text(String(format: "%03d", number ?? 0)).foregroundColor(.black)
                     // 66 -> "066"
                Text(name.capitalized)
                    .font(.headline)
                    .foregroundColor(.black)
            }.padding(.top, 10)
        }
    }
}
