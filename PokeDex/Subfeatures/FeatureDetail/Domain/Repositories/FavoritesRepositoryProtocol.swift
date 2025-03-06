//
//  FavoritesRepositoryProtocol.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//


protocol FavoritesRepositoryProtocol {
    /// Adds a Pokémon to the favorites list using the PokemonModel.
    /// - Parameter pokemon: The PokemonModel object to add to favorites.
    /// - Throws: An error if the operation fails, e.g., due to network or database issues.
    func addPokemonToFavorites(pokemon: PokemonModel) async throws

    /// Removes a Pokémon from the favorites list using the PokemonModel.
    /// - Parameter pokemon: The PokemonModel object to remove from favorites.
    /// - Throws: An error if the operation fails, e.g., due to network or database issues.
    func removePokemonFromFavorites(pokemon: PokemonModel) async throws

    /// Retrieves all Pokémon marked as favorites.
    /// - Returns: An array of PokemonModel objects that are marked as favorites.
    /// - Throws: An error if the operation fails, e.g., due to network or database issues.
    func fetchAllFavoritePokemons() async throws -> [PokemonModel]

    /// Checks if a specific Pokémon is in the favorites list.
    /// - Parameter pokemon: The PokemonModel object to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    /// - Throws: An error if the operation fails, e.g., due to network or database issues.
    func isPokemonFavorite(pokemon: PokemonModel) async throws -> Bool
}
