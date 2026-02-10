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
    @Binding var liked: Bool

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text( pokemonDetail?.getNumber() ?? "000")
                        .padding(10)
                        .foregroundColor(.white)
                    Spacer()
                    LikeButton(isLiked: $liked)
                        .foregroundColor(.headerBackground)
                        .padding(10)
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

    struct LikeButton: View {
       // Use a `@State` variable to track whether the button is liked or not
        @Binding  var isLiked: Bool

        var body: some View {
           Button(action: {
               // Toggle the value of the `isLiked` variable when the button is tapped
               self.isLiked.toggle()
           }) {
               // Use an image or label to indicate that the button is a "like" button
               Image(systemName: isLiked ? "heart.fill" : "heart")
           }
       }
   }
}
