//
//  PokemonTCGCardsView.swift
//  PokeDex
//
//  Created by yamartin on 19/3/25.
//

import SwiftUI

struct PokemonTCGCardsView: View {
    @StateObject private var viewModel = PokemonTCGViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.cards) { card in
                HStack {
                    AsyncImage(url: card.imageURL) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 50, height: 70)

                    VStack(alignment: .leading) {
                        Text(card.name)
                            .font(.headline)
                        Text(card.setName)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Cartas Charizard")
            .onAppear {
                viewModel.loadCards(named: "Charizard")
            }
        }
    }
}

@main
struct PokemonTCGApp: App {
    var body: some Scene {
        WindowGroup {
            PokemonTCGCardsView()
        }
    }
}
