//
//  GetPokemonListUseCase.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

class GetPokemonListUseCase {
    let repository: ExploreRepositoryProtocol
    
    init(pokeDexRepository: ExploreRepositoryProtocol) {
        self.repository = pokeDexRepository
    }
    
    func execute(limit: Int) async throws -> [PokemonEntity] {
        return try await repository.fetchPokemons(limit: limit)
    }
}

