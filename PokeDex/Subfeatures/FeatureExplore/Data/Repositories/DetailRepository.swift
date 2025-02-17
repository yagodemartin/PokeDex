//
//  DetailRepository.swift
//  PokeDex
//
//  Created by Muhammad Adha Fajri Jonison on 31/08/23.
//

import Foundation

class DetailRepository: DetailRepositoryProtocol {
    static let shared = DetailRepository()

    private let detailDataSource = DetailDataSource()

    func fetchPokemonDetail(id: Int) async throws -> PokemonEntity? {
        let pokemonDetailResponse: PokemonDetailReponseModel = try await detailDataSource.fetchPokemonDetail(id: id)

        guard let pokemonDetail: PokemonEntity = PokemonEntity(pokemonDetailResponse: pokemonDetailResponse) else {
            return nil
        }

        return pokemonDetail
    }
}
