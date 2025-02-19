//
//  ExploreDataSource.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

class DetailDataSource {
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetailReponseModel {
        guard let url: URL = Constants.APIEndpoint.getPokemonDetails(id: id).url else {
            throw URLError(.badURL)
        }

        return try await NetworkUtils.shared.fetch(from: url)
    }

    func fetchPokemonDetailSpecie(id: Int) async throws -> PokemonSpeciesResponseModel {
        guard let url: URL = Constants.APIEndpoint.getPokemonDetailSpecies(id: id).url else {
            throw URLError(.badURL)
        }

        return try await NetworkUtils.shared.fetch(from: url)
    }
}
