//
//  ExploreRepository.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

/// A repository that implements the Explore feature's data access logic.
///
/// `ExploreRepository` is responsible for fetching Pokémon data from the network
/// and transforming it from API response models (DTOs) into domain entities.
/// It acts as a bridge between the data layer (network) and the domain layer.
///
/// ## Architecture
/// ```
/// UseCase
///   ↓
/// ExploreRepository (implements ExploreRepositoryProtocol)
///   ↓
/// ExploreDataSource (HTTP calls)
///   ↓
/// PokeAPI
/// ```
///
/// ## Data Transformation
/// This repository transforms data in the following way:
/// 1. Fetches `PokemonListResponseModel` (DTO) from API
/// 2. Extracts the results array
/// 3. Maps each response to a `PokemonEntity` (domain model)
/// 4. Returns the array of domain entities to the use case
///
/// ## Singleton Pattern
/// The repository uses a singleton pattern (`shared` property) to ensure
/// a single instance throughout the application lifecycle.
///
/// ## Usage
/// ```swift
/// let repository = ExploreRepository.shared
/// let pokemons = try await repository.fetchPokemons(limit: 155)
/// ```
class ExploreRepository: ExploreRepositoryProtocol {
    /// Shared singleton instance of the repository.
    static let shared = ExploreRepository()

    private let exploreDataSource = ExploreDataSource()

    /// Fetches a list of Pokémon from the API.
    ///
    /// This method calls the data source to fetch Pokémon list data from the PokeAPI,
    /// then transforms the API response models into domain entities.
    /// Empty or invalid responses are filtered out during transformation.
    ///
    /// - Parameter limit: The maximum number of Pokémon to fetch.
    ///   Common values: 155 (first generation), 251 (first two generations), etc.
    /// - Returns: An array of `PokemonEntity` objects with basic information.
    /// - Throws: An error if the network request fails or response decoding fails.
    ///
    /// ## Performance
    /// Network call takes approximately 1-2 seconds.
    /// For complete details on each Pokémon, subsequent detail fetches are required.
    ///
    /// ## Details Included
    /// - Pokémon ID (extracted from URL)
    /// - Pokémon name
    /// - Image URL (constructed from standard Pokémon artwork repository)
    func fetchPokemons(limit: Int) async throws -> [PokemonEntity] {
        let pokemonsListResponse: PokemonListResponseModel = try await exploreDataSource.fetchPokemons(limit: limit)
        let pokemonResponses: [PokemonResponseModel] = pokemonsListResponse.results
        let pokemonEntities: [PokemonEntity] = pokemonResponses.compactMap { pokemon in
            return PokemonEntity(pokemonResponse: pokemon)
        }

        return pokemonEntities
    }
}
