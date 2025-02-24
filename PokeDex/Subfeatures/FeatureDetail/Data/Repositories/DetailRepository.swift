//
//  DetailRepository.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

class DetailRepository: DetailRepositoryProtocol {
    static let shared = DetailRepository()

    private let detailDataSource = DetailDataSource()

    func fetchPokemonDetail(id: Int) async throws -> PokemonEntity? {
        let pokemonDetailResponse: PokemonDetailReponseModel = try await detailDataSource.fetchPokemonDetail(id: id)

        guard let pokemonDetail = PokemonEntity(pokemonDetailResponse: pokemonDetailResponse) else {
            return nil
        }

        return pokemonDetail
    }

    func fetchPokemonDetailSpecie(id: Int) async throws -> PokemonSpeciesEntity? {
        let pokemonDetailResponseSpecie: PokemonSpeciesResponseModel = try await detailDataSource.fetchPokemonDetailSpecie(id: id)

        guard let pokemonDetail = PokemonSpeciesEntity(from: pokemonDetailResponseSpecie ) else {
            return nil
        }

        return pokemonDetail
    }
}
