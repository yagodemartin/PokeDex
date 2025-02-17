//
//  GetPokemonDetailUseCase.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

class GetPokemonDetailUseCase {
    let repository: DetailRepositoryProtocol

    init(repository: DetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: Int) async throws -> PokemonEntity? {
        guard let pokemonDetail: PokemonEntity = try await repository.fetchPokemonDetail(id: id) else {
            return nil
        }

        return pokemonDetail
    }
}
