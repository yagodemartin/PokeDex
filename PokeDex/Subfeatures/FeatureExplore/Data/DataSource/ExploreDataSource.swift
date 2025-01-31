//
//  PokeDexDataSource.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

class ExploreDataSource {
    func fetchPokemons(limit: Int) async throws -> PokemonListResponseModel {
        guard let url: URL = Constants.APIEndpoint.getPokemonList(limit: limit).url else {
            throw URLError(.badURL)
        }

        return try await NetworkUtils.shared.fetch(from: url)
    }
}
