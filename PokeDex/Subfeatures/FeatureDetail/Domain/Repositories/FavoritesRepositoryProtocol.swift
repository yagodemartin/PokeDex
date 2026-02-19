//
//  FavoritesRepositoryProtocol.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

/// Protocol for managing favorite Pokémon operations.
///
/// Defines the contract for all favorite-related database operations using Pokémon IDs.
/// This design ensures thread-safety by passing `Sendable` types (Int) across actor boundaries
/// instead of passing mutable model instances.
protocol FavoritesRepositoryProtocol {
    /// Adds a Pokémon to the favorites list.
    ///
    /// Copies all Pokémon data into FavoritePokemonDTO to create an independent persistent copy.
    /// This prevents data loss if the original PokemonModel is modified or deleted.
    ///
    /// - Parameters:
    ///   - pokemonID: The unique identifier of the Pokémon to add to favorites.
    ///   - pokemonData: Complete Pokémon model containing all fields to be persisted.
    /// - Throws: An error if the operation fails (e.g., database issues).
    func addPokemonToFavorites(pokemonID: Int, pokemonData: PokemonModel?) async throws

    /// Removes a Pokémon from the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to remove from favorites.
    /// - Throws: An error if the operation fails (e.g., database issues).
    func removePokemonFromFavorites(pokemonID: Int) async throws

    /// Retrieves all Pokémon marked as favorites.
    ///
    /// - Returns: An array of FavoritePokemonDTO objects that are marked as favorites.
    /// - Throws: An error if the operation fails (e.g., database issues).
    func fetchAllFavoritePokemons() async throws -> [FavoritePokemonDTO]

    /// Checks if a specific Pokémon is in the favorites list.
    ///
    /// - Parameter pokemonID: The unique identifier of the Pokémon to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: An error if the operation fails (e.g., database issues).
    func isPokemonFavorite(pokemonID: Int) async throws -> Bool
}
