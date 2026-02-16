//
//  FavoritesRepository.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

import Foundation

/// Repository for managing favorite Pokémon operations.
///
/// `FavoritesRepository` implements the Repository pattern to provide a clean API
/// for all favorite-related database operations. It acts as a bridge between
/// Use Cases and the Data Source layer.
///
/// ## Key Features
/// - All methods are `async throws` to properly propagate errors
/// - Singleton pattern for consistent state
/// - Direct delegation to `FavouritesDataSource`
/// - Implements `FavoritesRepositoryProtocol` for dependency injection
///
/// ## Thread Safety
/// Marked with `@MainActor` to ensure all operations occur on the main thread,
/// which is required by SwiftData and UI updates.
@MainActor
class FavoritesRepository: FavoritesRepositoryProtocol {
    static let shared = FavoritesRepository()

    private init() {} // Singleton implementation

    /// Adds a Pokémon to the favorites list.
    /// - Parameter pokemon: The PokemonModel to add to favorites.
    /// - Throws: Any errors from the data source (database failures, etc.)
    func addPokemonToFavorites(pokemon: PokemonModel) async throws {
        try await FavouritesDataSource.shared.addPokemonToFavorites(pokemon: pokemon)
    }

    /// Removes a Pokémon from the favorites list.
    /// - Parameter pokemon: The PokemonModel to remove from favorites.
    /// - Throws: Any errors from the data source (database failures, etc.)
    func removePokemonFromFavorites(pokemon: PokemonModel) async throws {
        try await FavouritesDataSource.shared.removePokemonFromFavorites(pokemon: pokemon)
    }

    /// Fetches all Pokémon marked as favorites.
    /// - Returns: An array of PokemonModel objects from the favorites list.
    /// - Throws: Any errors from the data source (database failures, etc.)
    func fetchAllFavoritePokemons() async throws -> [PokemonModel] {
        try await FavouritesDataSource.shared.fetchPokemons()
    }

    /// Checks if a specific Pokémon is in the favorites list.
    /// - Parameter pokemon: The PokemonModel to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: Any errors from the data source (database failures, etc.)
    func isPokemonFavorite(pokemon: PokemonModel) async throws -> Bool {
        return try await FavouritesDataSource.shared.isPokemonFavorite(pokemon: pokemon)
    }
}
