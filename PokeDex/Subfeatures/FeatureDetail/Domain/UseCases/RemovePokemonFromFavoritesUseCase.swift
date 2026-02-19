//
//  RemovePokemonFromFavoritesUseCase.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

/// Use case for removing a Pokémon from favorites.
///
/// Handles the business logic for removing a Pokémon from the favorites list.
/// Uses Pokémon ID instead of model instance for thread-safety with @MainActor.
final class RemovePokemonFromFavoritesUseCase {
    let repository: FavoritesRepositoryProtocol

    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    /// Executes the use case to remove a Pokémon from the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to be removed from favorites.
    /// - Throws: An error if the operation fails.
    func execute(pokemonID: Int) async throws {
        try await repository.removePokemonFromFavorites(pokemonID: pokemonID)
    }
}
