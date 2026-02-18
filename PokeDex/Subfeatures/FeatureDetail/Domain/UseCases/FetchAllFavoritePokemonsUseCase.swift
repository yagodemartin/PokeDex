//
//  FetchAllFavoritePokemonsUseCase.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

class FetchAllFavoritePokemonsUseCase {
    let repository: FavoritesRepositoryProtocol

    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    /// Executes the use case to fetch all favorite Pokémon.
    /// - Returns: An array of FavoritePokemonDTO objects marked as favorites.
    func execute() async throws -> [FavoritePokemonDTO] {
        return try await repository.fetchAllFavoritePokemons()
    }
}
