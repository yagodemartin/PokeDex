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
/// - Passes Pokémon IDs (Int) instead of model instances for thread-safety
///
/// ## Thread Safety
/// Marked with `@MainActor` to ensure all operations occur on the main thread,
/// which is required by SwiftData and UI updates. Uses `Sendable` types (Int)
/// for passing data across actor boundaries.
@MainActor
class FavoritesRepository: FavoritesRepositoryProtocol {
    static let shared = FavoritesRepository()

    private init() {}

    /// Adds a Pokémon to the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to add.
    /// - Throws: Any errors from the data source (database failures, etc.)
    func addPokemonToFavorites(pokemonID: Int) async throws {
        try await FavouritesDataSource.shared.addPokemonToFavorites(pokemonID: pokemonID)
    }

    /// Removes a Pokémon from the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to remove.
    /// - Throws: Any errors from the data source (database failures, etc.)
    func removePokemonFromFavorites(pokemonID: Int) async throws {
        try await FavouritesDataSource.shared.removePokemonFromFavorites(pokemonID: pokemonID)
    }

    /// Fetches all Pokémon marked as favorites.
    ///
    /// - Returns: An array of PokemonModel objects from the favorites list.
    /// - Throws: Any errors from the data source (database failures, etc.)
    func fetchAllFavoritePokemons() async throws -> [PokemonModel] {
        try await FavouritesDataSource.shared.fetchPokemons()
    }

    /// Checks if a specific Pokémon is in the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: Any errors from the data source (database failures, etc.)
    func isPokemonFavorite(pokemonID: Int) async throws -> Bool {
        return try await FavouritesDataSource.shared.isPokemonFavorite(pokemonID: pokemonID)
    }
}
