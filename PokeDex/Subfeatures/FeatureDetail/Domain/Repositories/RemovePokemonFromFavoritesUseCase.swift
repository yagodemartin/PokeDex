//
//  RemovePokemonFromFavoritesUseCase.swift
//  PokeDex
//
//  Created by yamartin on 4/3/25.
//

class RemovePokemonFromFavoritesUseCase {
    let repository: FavoritesRepositoryProtocol

    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }

    /// Executes the use case to remove a Pokémon from the favorites list.
    /// - Parameter pokemon: The PokemonModel object to be removed from favorites.
    func execute(pokemon: PokemonModel) async throws {
        try await repository.removePokemonFromFavorites(pokemon: pokemon)
    }
}
