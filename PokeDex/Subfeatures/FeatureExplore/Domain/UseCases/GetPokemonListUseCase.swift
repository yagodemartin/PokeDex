//
//  GetPokemonListUseCase.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

/// A use case that fetches a list of Pokémon from the API.
///
/// This use case encapsulates the business logic for retrieving a paginated list of Pokémon.
/// It follows the Clean Architecture pattern by delegating data retrieval to a repository,
/// keeping the domain layer independent of implementation details.
///
/// ## Overview
/// The `GetPokemonListUseCase` is responsible for:
/// - Coordinating the fetch operation through the repository
/// - Returning a list of Pokémon entities
/// - Propagating any errors that occur during fetching
///
/// ## Usage
/// ```swift
/// let useCase = GetPokemonListUseCase(
///     pokeDexRepository: ExploreRepository.shared
/// )
/// let pokemons = try await useCase.execute(limit: 155)
/// ```
class GetPokemonListUseCase {
    let repository: ExploreRepositoryProtocol

    /// Initializes the use case with a repository implementation.
    /// - Parameter pokeDexRepository: The repository that provides Pokémon data.
    init(pokeDexRepository: ExploreRepositoryProtocol) {
        self.repository = pokeDexRepository
    }

    /// Executes the use case to fetch a list of Pokémon.
    ///
    /// This method asynchronously fetches a list of Pokémon entities from the repository.
    /// The operation can throw errors if the network request fails or if data decoding fails.
    ///
    /// - Parameter limit: The maximum number of Pokémon to fetch. Typically 155 for the first generation.
    /// - Returns: An array of `PokemonEntity` objects representing the fetched Pokémon.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    ///
    /// ## Performance
    /// The initial list fetch is relatively fast (~1-2 seconds).
    /// To get complete details for each Pokémon, use `GetPokemonDetailUseCase` with parallel TaskGroups.
    func execute(limit: Int) async throws -> [PokemonEntity] {
        return try await repository.fetchPokemons(limit: limit)
    }
}
