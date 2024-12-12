//
//  ExploreRepository.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//


class ExploreRepository: ExploreRepositoryProtocol {
    static let shared = ExploreRepository()
    
    private let exploreDataSource = ExploreDataSource()
    
    func fetchPokemons(limit: Int) async throws -> [PokemonEntity] {
        let pokemonsListResponse: PokemonListResponseModel = try await exploreDataSource.fetchPokemons(limit: limit)
        let pokemonResponses: [PokemonResponseModel] = pokemonsListResponse.results
        let pokemonEntities: [PokemonEntity] = pokemonResponses.compactMap { pokemon in
            return PokemonEntity(pokemonResponse: pokemon)
        }
        
        return pokemonEntities
    }
}
