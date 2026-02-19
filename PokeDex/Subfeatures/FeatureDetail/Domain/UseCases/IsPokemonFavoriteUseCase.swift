//
//  IsPokemonFavoriteUseCase.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

/// Use case for checking if a Pokémon is in favorites.
///
/// Handles the business logic for verifying whether a Pokémon is in the favorites list.
/// Uses Pokémon ID instead of model instance for thread-safety with @MainActor.
final class IsPokemonFavoriteUseCase {
    let repository: FavoritesRepositoryProtocol

    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    /// Executes the use case to check if a Pokémon is in the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: An error if the operation fails.
    func execute(pokemonID: Int) async throws -> Bool {
        return try await repository.isPokemonFavorite(pokemonID: pokemonID)
    }
}
