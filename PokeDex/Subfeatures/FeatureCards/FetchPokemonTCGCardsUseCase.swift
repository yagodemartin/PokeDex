//
//  FetchPokemonTCGCardsUseCase.swift
//  PokeDex
//
//  Created by yamartin on 19/3/25.
//

import Foundation

class FetchPokemonTCGCardsUseCase {
    private let repository: PokemonTCGRepository

    init(repository: PokemonTCGRepository) {
        self.repository = repository
    }

    func execute(named name: String, completion: @escaping ([PokemonTCGCardDomainModel]?) -> Void) {
        repository.fetchCards(named: name) { serviceModels in
            guard let serviceModels = serviceModels else {
                completion(nil)
                return
            }

            let domainModels = serviceModels.map { serviceModel in
                PokemonTCGCardDomainModel(
                    id: serviceModel.id,
                    name: serviceModel.name,
                    setName: serviceModel.set.name,
                    imageURLString: serviceModel.images.small
                )
            }
            completion(domainModels)
        }
    }
}
