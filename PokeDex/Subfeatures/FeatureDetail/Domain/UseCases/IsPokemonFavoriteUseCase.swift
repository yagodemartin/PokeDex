//
//  IsPokemonFavoriteUseCase.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//
class IsPokemonFavoriteUseCase {
    let repository: FavoritesRepositoryProtocol

    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    /// Executes the use case to check if a Pokémon is in the favorites list.
    /// - Parameter pokemon: The PokemonModel object to check.
    /// - Returns: A boolean indicating whether the Pokémon is a favorite.
    func execute(pokemon: PokemonModel) async throws -> Bool {
        return try await repository.isPokemonFavorite(pokemon: pokemon)
    }
}
