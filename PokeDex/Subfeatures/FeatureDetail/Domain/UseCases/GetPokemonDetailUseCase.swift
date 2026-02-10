//
//  GetPokemonDetailUseCase.swift
//  PokeDex
//
//  Created by yamartin on 22/11/24.
//

import Foundation

/// A use case that fetches detailed information about a specific Pokémon.
///
/// This use case retrieves comprehensive details about a Pokémon, including stats,
/// abilities, types, height, and weight. It's typically called after the list has been
/// fetched to populate individual Pokémon cards with complete information.
///
/// ## Overview
/// The `GetPokemonDetailUseCase` is responsible for:
/// - Fetching detailed information for a specific Pokémon by ID
/// - Handling optional results (returns nil if Pokémon not found)
/// - Delegating to the repository for actual data retrieval
///
/// ## Usage
/// ```swift
/// let useCase = GetPokemonDetailUseCase(
///     repository: DetailRepository()
/// )
/// if let pokemonDetail = try await useCase.execute(id: 6) {
///     print("Found: \(pokemonDetail.name)")
/// }
/// ```
///
/// ## Performance Considerations
/// - Single fetch takes ~100-200ms
/// - For multiple Pokémon, use TaskGroups for parallel loading:
///   ```swift
///   try await withThrowingTaskGroup(of: PokemonEntity?.self) { group in
///       for id in 1...155 {
///           group.addTask { try await useCase.execute(id: id) }
///       }
///   }
///   ```
class GetPokemonDetailUseCase {
    let repository: DetailRepositoryProtocol

    /// Initializes the use case with a repository implementation.
    /// - Parameter repository: The repository that provides detailed Pokémon data.
    init(repository: DetailRepositoryProtocol) {
        self.repository = repository
    }

    /// Executes the use case to fetch detailed information about a specific Pokémon.
    ///
    /// This method asynchronously fetches complete details for a Pokémon identified by its ID.
    /// The operation can throw errors if the network request fails.
    ///
    /// - Parameter id: The Pokédex ID of the Pokémon to fetch. Valid range is typically 1-1025.
    /// - Returns: A `PokemonEntity` with complete details, or `nil` if the Pokémon doesn't exist.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    ///
    /// ## Details Included
    /// - ID and name
    /// - Stats (HP, Attack, Defense, Special Attack, Special Defense, Speed)
    /// - Types (Fire, Water, Grass, etc.)
    /// - Height and weight
    /// - Image URL
    func execute(id: Int) async throws -> PokemonEntity? {
        guard let pokemonDetail: PokemonEntity = try await repository.fetchPokemonDetail(id: id) else {
            return nil
        }

        return pokemonDetail
    }
}
