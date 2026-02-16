//
//  PokemonTCGCardModelView.swift
//  PokeDex
//
//  Created by yamartin on 19/3/25.
//

import Foundation
import SwiftUI

class PokemonTCGCardModelView: ObservableObject {
    @Published var cards: [PokemonTCGCard] = []
    private let fetchCardsUseCase: FetchPokemonTCGCardsUseCase

    init() {
        let repository = PokemonTCGRemoteDataSource()
        self.fetchCardsUseCase = FetchPokemonTCGCardsUseCase(repository: repository)
    }

    func loadCards(named name: String) {
        fetchCardsUseCase.execute(named: name) { [weak self] fetchedCards in
            DispatchQueue.main.async {
                self?.cards = fetchedCards ?? []
            }
        }
    }
}
