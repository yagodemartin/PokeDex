//
//  ExploreRepositoryProtocol.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

protocol ExploreRepositoryProtocol {
    func fetchPokemons(limit: Int) async throws -> [PokemonEntity]
}
