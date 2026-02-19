//
//  PokemonTCGViewModel.swift
//  PokeDex
//
//  Created by yamartin on 19/3/25.
//

import Foundation
import SwiftUI

class PokemonTCGViewModel: ObservableObject {
    @Published var cards: [PokemonTCGCardModelView] = []
    private let fetchCardsUseCase: FetchPokemonTCGCardsUseCase

    init() {
        let repository = PokemonTCGRemoteDataSource()
        self.fetchCardsUseCase = FetchPokemonTCGCardsUseCase(repository: repository)
    }

    func loadCards(named name: String) {
        fetchCardsUseCase.execute(named: name) { [weak self] domainModels in
            guard let domainModels = domainModels
            else { return }

            let viewModels = domainModels.map { domainModel in
                PokemonTCGCardModelView(domainModel: domainModel)
            }

            DispatchQueue.main.async {
                self?.cards = viewModels
            }
        }
    }
}
