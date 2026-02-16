//
//  AddPokemonToFavoritesUseCase.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

/// Use case for adding a Pokémon to favorites.
///
/// Handles the business logic for adding a Pokémon to the favorites list.
/// Uses Pokémon ID instead of model instance for thread-safety with @MainActor.
final class AddPokemonToFavoritesUseCase {
    let repository: FavoritesRepositoryProtocol

    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    /// Executes the use case to add a Pokémon to the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to be added to favorites.
    /// - Throws: An error if the operation fails.
    func execute(pokemonID: Int) async throws {
        try await repository.addPokemonToFavorites(pokemonID: pokemonID)
    }
}
