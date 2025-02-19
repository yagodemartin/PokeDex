//
//  GetPokemonDetailSpecieUseCase.swift
//  PokeDex
//
//  Created by yamartin on 18/2/25.
//

import Foundation

class GetPokemonDetailSpecieUseCase {
    let repository: DetailRepositoryProtocol

    init(repository: DetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: Int) async throws -> PokemonSpeciesEntity? {
        guard let pokemonDetail: PokemonSpeciesEntity = try await repository.fetchPokemonDetailSpecie(id: id) else {
            return nil
        }

        return pokemonDetail
    }
}

